-module(osc_client_mgr).

-behaviour(gen_server).

%% gen_server callback exports
-export([init/1,
         handle_call/3,
         handle_cast/2,
         handle_info/2,
         code_change/3,
	 terminate/2
]).

%% API exports
-export([start/0,
         start_link/0,
         send_msg/1,
         send_bundle/1]).

%% Constants, etc.
-define(SERVER, ?MODULE). 

-record(state, {
    host,
    port,
    socket
}).

%% API

start() ->
    start_link().

start_link() ->
    gen_server:start_link({global, ?SERVER}, ?MODULE, [], []).

%% Callbacks

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

handle_call(ping, _From, State) ->
    {reply, pong, State};
handle_call(get_addresses, _From, State) ->
    {reply, State#state.osc_addresses, State};
handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(Msg, State) ->
    {noreply, States}.

handle_info({'EXIT', _From, normal}, State) ->
    error_logger:error_msg("The OSC server is exiting (normal)."),
    {noreply, State};
handle_info({'EXIT', _From, shutdown}, State) ->
    error_logger:error_msg("The OSC server server is exiting (shutdown)."),
    {noreply, State};
handle_info({'EXIT', From, Reason}, State) ->
    io:format("OSC server process: ~p exited with reason: ~p~n",
	      [From, Reason]),
    {noreply, State};
handle_info(_Info, State) ->
    {noreply, State}.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

terminate(_Reason, State) ->
    gen_udp:close(State#state.socket),
    ok.

%% Private / support functions

send_msg(Host, Port, [H|T]) ->
    %% Prog is a io-list
    P1 = lists:flatten(Prog),
    M = ["/run-code" , "erl-id", P1],
    Encoded = osc_lib:encode({message, H, T}),
    send_udp(Host, Port, Encoded).


send_bundle(Host, Port, [H|T]) ->
    .

send_udp(Host, Port, Data) ->
    {ok, Socket} = gen_udp:open(0, [binary]),
    ok = gen_udp:send(Socket, Host, Port, Data),
    gen_udp:close(Socket).
