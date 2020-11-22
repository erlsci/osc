-module(osc_client).

%% API exports
-export([connect/2, connect/3,
         ping/1,
         reconnect/1,
         send_msg/2,
         send_bundle/2,
         start/0, start/2,
         stop/0, stop/1
]).

-define(SUP, osc_client_mgr_sup).
-define(MGR, {global, osc_client_mgr}).

%% API

%% Create a new UDP client manager; returns a PID.
connect(Host, Port) ->
    connect(Host, Port, []).

%% Create a new UDP client manager; returns a PID.
connect(Host, Port, UdpOpts) ->
    gen_server:call(?MGR, {connect, Host, Port, UdpOpts}).

ping(Pid) ->
    gen_server:call(?MGR, {ping, Pid}).

reconnect(Pid) ->
    gen_server:call(?MGR, {reconnect, Pid}).

send_msg(Pid, Data) ->
    gen_server:call(?MGR, {message, Pid, Data}).

send_bundle(Pid, Data) ->
    gen_server:call(?MGR, {bundle, Pid, Data}).

start() ->
    start(normal, []).

%% For use by application:start
start(_StartType, _StartArgs) ->
    apply(?SUP, start_link, []).

stop() ->
    %% XXX manually stop supervisor ... terminate all child processes?
    tbd.

%% For use by application:stop
stop(_State) ->
    ok.
