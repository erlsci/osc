-module(osc_client_mgr_sup).

-behaviour(supervisor).

-define(MGR, osc_client_mgr). 

%% API
-export([add_conn/3,
         list_conns/0,
         remove_conn/1,
         start_link/0
]).

%% Supervisor callbacks
-export([handle_info/1, handle_info/2,
         init/1
]).

start_link() ->
    process_flag(trap_exit, true),
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% @doc Initializes the supervisor.
%% @spec init(Args) -> {ok, {SupFlags, ChildSpecs}} | ignore | {error, Reason}
init([]) ->
    SupFlags = #{strategy => simple_one_for_one,
                 intensity => 0,
                 period => 1},
    ChildSpecs = [#{id => ?MGR,
                    start => {?MGR, start_link, []},
                    shutdown => brutal_kill,
                    modules => [?MGR]
                 }],
    {ok, {SupFlags, ChildSpecs}}.

%% Add a client manager ("connection") to the supervisor
add_conn(Host, Port, UdpOpts) ->
    supervisor:start_child(?MODULE, [Host, Port, UdpOpts]).

list_conns() ->
    supervisor:which_children(?MODULE).

%% Remove a client manager from the supervisor
remove_conn(Pid) ->
    supervisor:terminate_child(?MODULE, Pid).


handle_info(Data) ->
    handle_info(Data, undefined).

handle_info({'EXIT', _From, normal}, State) ->
    error_logger:error_msg("The OSC client manager is exiting (normal)."),
    {noreply, State};
handle_info({'EXIT', _From, shutdown}, State) ->
    error_logger:error_msg("The OSC client manager is exiting (shutdown)."),
    {noreply, State}.
