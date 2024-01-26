defmodule WerefoxBackend.AgentSupervisor do
    use Supervisor

    def start_link(arg) do
        Supervisor.start_link(__MODULE__, arg)
    end


    def init(_) do

    end

end