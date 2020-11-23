-module(osc_client_mgr_sup).

-behaviour(supervisor).

-define(MGR, osc_client_mgr). 

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% @doc Initializes the supervisor.
%% @spec init(Args) -> {ok, {SupFlags, ChildSpecs}} | ignore | {error, Reason}
init([]) ->
    Server = #{
        id => ?MGR,
        start => {?MGR, start_link, []},
	restart => permanent,
        shutdown => 2000,
        type => worker,
        modules => [?MGR]},
    {ok, {#{
          strategy => one_for_one,
          intensity => 3,
          period => 60}, [Server]}}.
