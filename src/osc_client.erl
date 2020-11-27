-module(osc_client).

%% API exports
-export([connect/0, connect/2, connect/3,
         ping/1,
         reconnect/1,
         call_msg/2, call_msg/3,
         call_bundle/2, call_bundle/3,
         cast_msg/2, cast_msg/3,
         cast_bundle/2, cast_bundle/3,
         socket/1,
         start/0, start/2,
         stop/0, stop/1
]).

-define(SUP, osc_client_mgr_sup).
-define(MGR, {global, osc_client_mgr}).

%% API

%% Create a new UDP client manager; returns a PID.
connect() ->
    {ok, Host} = application:get_env(osc_lib, host),
    {ok, Port} = application:get_env(osc_lib, port),
    connect(Host, Port).

connect(Host, Port) ->
    {ok, UdpOpts} = application:get_env(osc_lib, udp_opts),
    connect(Host, Port, UdpOpts).

connect(Host, Port, UdpOpts) ->
    osc_client_mgr_sup:add_conn(Host, Port, UdpOpts).

%% Check to see if the child gen_server is running / responding
ping(Pid) ->
    gen_server:call(Pid, ping).

%% Re-create the UDP Erlang port in the child gen_server
reconnect(Pid) ->
    gen_server:call(Pid, reconnect).

%% Messages & bundles with a reply
call_msg(Pid, Address) ->
    gen_server:call(Pid, {message, Address}).

call_msg(Pid, Address, Args) ->
    gen_server:call(Pid, {message, Address, Args}).

call_bundle(Pid, Address) ->
    gen_server:call(Pid, {bundle, Address}).

call_bundle(Pid, Address, Args) ->
    gen_server:call(Pid, {bundle, Address, Args}).

%% Messages & bundles with no reply
cast_msg(Pid, Address) ->
    gen_server:cast(Pid, {message, Address}).

cast_msg(Pid, Address, Args) ->
    gen_server:cast(Pid, {message, Address, Args}).

cast_bundle(Pid, Address) ->
    gen_server:cast(Pid, {bundle, Address}).

cast_bundle(Pid, Address, Args) ->
    gen_server:cast(Pid, {bundle, Address, Args}).

%% Non-OSC API functions

socket(Pid) ->
    gen_server:call(Pid, socket).

%% Constructors

start() ->
    start(normal, []).

%% For use by application:start
start(_StartType, _StartArgs) ->
    process_flag(trap_exit, true),
    application:ensure_started(osc_lib),
    case apply(?SUP, start_link, []) of
        {ok, Pid} -> {ok, Pid};
        {error, {_, Pid}} -> {ok, Pid}
    end.

stop() ->
    exit(?SUP, kill).

%% For use by application:stop
stop(_State) ->
    ok.
