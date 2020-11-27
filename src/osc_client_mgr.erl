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
-export([start/3,
         start_link/3
]).

%% Constants, etc.
-define(SERVER, ?MODULE). 
-define(GEN_SERV_OPTS, []).
-define(UDP_TIMEOUT, 2000).

-record(state, {
    host,
    port,
    socket,
    opts
}).

%% API

start(Host, Port, UdpOpts) ->
    start_link(Host, Port, UdpOpts).

start_link(Host, Port, UdpOpts) ->
    process_flag(trap_exit, true),
    gen_server:start_link({global, ?SERVER}, ?MODULE, [Host, Port, UdpOpts], ?GEN_SERV_OPTS).

%% Callbacks

init([]) ->
    {ok, #state{}};
init([Host, Port, UdpOpts]) ->
    {ok, Socket} = gen_udp:open(0, UdpOpts),
    {ok, #state{host=Host, port=Port, socket=Socket, opts=UdpOpts}}.

handle_call(ping, _From, State) ->
    {reply, pong, State};
handle_call(socket, _From, State) ->
    {reply, State#state.socket, State};
handle_call(reconnect, _From, State) ->
    gen_udp:close(State#state.socket),
    {ok, Socket} = gen_udp:open(0, State#state.opts),
    {reply, ok, State#state{socket=Socket}};
handle_call({Type, Address}, _From, State) ->
    Data = encode(Type, Address),
    Result = call_udp(State, Data, ?UDP_TIMEOUT),
    {reply, Result, State};
handle_call({Type, Address, Args}, _From, State) ->
    Data = encode(Type, Address, Args),
    Result = call_udp(State, Data, ?UDP_TIMEOUT),
    {reply, Result, State};
handle_call(_Msg, _From, State) ->
    {reply, unknown_cmd, State}.

handle_cast({Type, Address}, State) ->
    Data = encode(Type, Address),
    cast_udp(State, Data),
    {noreply, State};
handle_cast({Type, Address, Args}, State) ->
    Data = encode(Type, Address, Args),
    cast_udp(State, Data),
    {noreply, State};
handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info({'EXIT', _From, normal}, State) ->
    error_logger:error_msg("The OSC client manager is exiting (normal)."),
    {noreply, State};
handle_info({'EXIT', _From, shutdown}, State) ->
    error_logger:error_msg("The OSC client manager is exiting (shutdown)."),
    {noreply, State};
handle_info({'EXIT', From, Reason}, State) ->
    io:format("OSC client manager process: ~p exited with reason: ~p~n",
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

encode(Type, Address) ->
    encode(Type, Address, []).

encode(Type, Address, Args) ->
    osc_lib:encode({Type, Address, Args}).

%% Pass the state and the data for comms with a reply
call_udp(#state{host=Host, port=Port, socket=Socket}, Data, Timeout) ->
    ok = gen_udp:send(Socket, Host, Port, Data),
    receive
        {udp, Socket, _, _, Bin} ->
            osc_lib:decode(Bin)
    after Timeout ->
            {error, timeout}
    end.

%% Pass the state and the data for comms with no reply
cast_udp(#state{host=Host, port=Port, socket=Socket}, Data) ->
    ok = gen_udp:send(Socket, Host, Port, Data).
