%% @author Ruslan Babayev <ruslan@babayev.com>
%% @copyright 2009 Ruslan Babayev
%% @doc OSC Server.

-module(osc_server).

-behaviour(gen_server).

%% gen_server callbacks
-export([init/1,
         handle_call/3,
         handle_cast/2,
         handle_info/2,
         code_change/3,
	 terminate/2
]).

%% API
-export([start_link/0,
         add_address/3,
         remove_address/1
]).

%% Constants, etc.
-define(SERVER, ?MODULE). 
-define(ETS_TABLE, osc_addresses).

-record(state, {
    socket,
    addresses,
    osc_addresses = []
}).

%% @doc Starts the server.
%% @spec start_link() -> {ok, Pid} | ignore | {error, Reason}
start_link() ->
    gen_server:start_link({global, ?SERVER}, ?MODULE, [], []).

%% @doc Adds an OSC address.
%% @spec add_address(string(), atom(), atom()) -> ok
add_address(Address, Module, Function) ->
    gen_server:cast(?SERVER, {add_address, Address, Module, Function}).

%% @doc Removes an OSC address.
%% @spec remove_address(Address) -> ok
remove_address(Address) ->
    gen_server:cast(?SERVER, {delete_address, Address}).

%% @private
%% @doc Initializes the server.
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
init([]) ->
    {ok, Port} = application:get_env(osc, port),
    {ok, RecBuf} = application:get_env(osc, recbuf),
    Options = [binary, {active, once}, {recbuf, RecBuf}],
    case gen_udp:open(Port, Options) of
	{ok, Socket} ->
	    Addresses = ets:new(?ETS_TABLE, [named_table, ordered_set]),
	    {ok, #state{socket = Socket, addresses = Addresses}};
	{error, Reason} ->
	    error_logger:error_report({?MODULE, udp_open, Reason}),
	    {stop, {?MODULE, udp_open, Reason}}
    end.

%% @private
%% @doc Handles call messages.
%% @spec handle_call(Request, From, State) ->
%%                  {reply, Reply, State} |
%%                  {reply, Reply, State, Timeout} |
%%                  {noreply, State} |
%%                  {noreply, State, Timeout} |
%%                  {stop, Reason, Reply, State} |
%%                  {stop, Reason, State}
handle_call(ping, _From, State) ->
    {reply, pong, State};
handle_call(get_addresses, _From, State) ->
    {reply, State#state.osc_addresses, State};
handle_call(_Request, _From, State) ->
    {reply, ok, State}.

%% @private
%% @doc Handles cast messages.
%% @spec handle_cast(Msg, State) -> {noreply, State} |
%%                                  {noreply, State, Timeout} |
%%                                  {stop, Reason, State}
handle_cast({add_address, Address, Module, Function}, State) ->
    Addresses = State#state.addresses,
    ets:insert(Addresses, {string:tokens(Address, "/"), {Module, Function}}),
    OldOSCAddresses = State#state.osc_addresses,
    {noreply, State#state{osc_addresses = OldOSCAddresses ++ [Address]}};
handle_cast({remove_address, Address}, State) ->
    Addresses = State#state.addresses,
    ets:delete(Addresses, string:tokens(Address, "/")),
    OldOSCAddresses = State#state.osc_addresses,
    NewOSCAddresses = lists:dropwhile(fun(X) -> X == Address end, OldOSCAddresses),
    {noreply, State#state{osc_addresses = NewOSCAddresses}}.

%% @private
%% @doc Handles all non call/cast messages.
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
handle_info({'EXIT', _From, normal}, State) ->
    error_logger:error_msg("The OSC server is exiting (normal)."),
    {noreply, State};
handle_info({'EXIT', _From, shutdown}, State) ->
    error_logger:error_msg("The OSC server is exiting (shutdown)."),
    {noreply, State};
handle_info({'EXIT', From, Reason}, State) ->
    io:format("OSC server process: ~p exited with reason: ~p~n",
	      [From, Reason]),
    {noreply, State};
handle_info({udp, Socket, _IP, _Port, Packet}, State) ->
    inet:setopts(Socket, [{active, once}]),
    Addresses = State#state.addresses,
    try osc_lib:decode(Packet) of
	{message, Address, Args} ->
	    handle_message(immediately, Address, Args, Addresses);
	{bundle, When, Elements} ->
	    handle_bundle(When, Elements, Addresses)
    catch
	Class:Term ->
	    error_logger:error_report({osc_lib,decode,Class,Term})
    end,
    {noreply, State};
handle_info(_Info, State) ->
    {noreply, State}.

%% @private
%% @doc Performs cleanup on termination.
%% @spec terminate(Reason, State) -> void()
terminate(_Reason, State) ->
    gen_udp:close(State#state.socket),
    ok.

%% @private
%% @doc Converts process state when code is changed.
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% @doc Handles OSC messages.
%% @spec handle_message(When, Address, Args, Addresses) -> any()
%%       When = time()
%%       Address = string()
%%       Args = [any()]
%%       Addresses = [address()]
handle_message(When, Address, Args, Addresses) ->
    case ets:match(Addresses, make_pattern(Address)) of
	[] ->
	    error_logger:info_report({unhandled,{message,Address,Args}});
	Matches ->
	    Time = osc_util:when_to_millisecs(When),
	    [timer:apply_after(Time, Module, Function, [Args]) ||
		[{Module, Function}] <- Matches]
    end.

%% @doc Converts the OSC address pattern into ETS match spec.
%% @spec make_pattern(string()) -> tuple()
make_pattern(Address) ->
    make_pattern(string:tokens(Address, "/"), []).

make_pattern([], Acc) ->
    {lists:reverse(Acc), '$1'};
make_pattern(["*"], Acc) ->
    {lists:reverse(Acc) ++ '_', '$1'};
make_pattern([H|T], Acc) ->
    make_pattern(T, [make_pattern2(H, [])|Acc]).

make_pattern2([], Acc) ->
    lists:reverse(Acc);
make_pattern2([$*|_], Acc) ->
    lists:reverse(Acc) ++ '_';
make_pattern2([$?|T], Acc) ->
    make_pattern2(T, ['_'|Acc]);
make_pattern2([H|T], Acc) ->
    make_pattern2(T, [H|Acc]).

%% @doc Handles OSC bundles.
%% @spec handle_bundle(When, Elements, Addresses) -> any()
%%       Elements = [message() | bundle()]
%%       Addresses = [address()]
%%       message() = {message, Address::string(), Args::[any()]}
%%       bundle() = {bundle, When::time(), [message() | bundle()]}
%%       time() = immediately | {time, Seconds::integer(), Fractions::integer()}
%%       address() = {Module::atom(), Function::atom()}
handle_bundle(_When, [], _Addresses) ->
    ok;
handle_bundle(When, [{message, Address, Args} | Rest], Addresses) ->
    handle_message(When, Address, Args, Addresses),
    handle_bundle(When, Rest, Addresses);
handle_bundle(When, [{bundle, InnerWhen, Elements} | Rest], Addresses) ->
    handle_bundle(InnerWhen, Elements, Addresses),
    handle_bundle(When, Rest, Addresses).
