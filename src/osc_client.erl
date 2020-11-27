-module(osc_client).

%% API exports
-export([connect/0, connect/2, connect/3,
         ping/1,
         reconnect/1,
         send_msg/2, send_msg/3,
         send_bundle/2, send_bundle/3,
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

send_msg(Pid, Address) ->
    gen_server:cast(Pid, {message, Address}).

send_msg(Pid, Address, Args) ->
    gen_server:cast(Pid, {message, Address, Args}).

send_bundle(Pid, Address) ->
    gen_server:cast(Pid, {bundle, Address}).

send_bundle(Pid, Address, Args) ->
    gen_server:cast(Pid, {bundle, Address, Args}).

socket(Pid) ->
    gen_server:call(Pid, socket).

start() ->
    start(normal, []).

%% For use by application:start
start(_StartType, _StartArgs) ->
    process_flag(trap_exit, true),
    application:ensure_started(osc_lib),
    apply(?SUP, start_link, []).

stop() ->
    exit(?SUP, kill).

%% For use by application:stop
stop(_State) ->
    ok.
