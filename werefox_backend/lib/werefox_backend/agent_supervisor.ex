defmodule WerefoxBackend.AgentSupervisor do
    use Supervisor

    def start_link(arg) do
        Supervisor.start_link(__MODULE__, arg)
    end


    def init(agent_number, room_id, specify_id) do
        IO.puts("Agent Supervisor Start!")
        children = [
            WerefoxBackend.Agent
        ]
        Supervisor.init(children, strategy: :one_for_one)
    end

end