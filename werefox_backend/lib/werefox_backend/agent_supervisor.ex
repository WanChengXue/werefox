defmodule WerefoxBackend.AgentSupervisor do
  use Supervisor

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg)
  end

  def init({room_id, agent_number, specify_id}) do
    IO.puts("Agent Supervisor Start!")
    # children_process = generate_agent_process_list(agent_number, room_id, specify_id, [])
    children_process = [
      {WerefoxBackend.Agent, [room_id, 35, ""]},
      {WerefoxBackend.Agent, [room_id, 33, ""]}
    ]

    # Supervisor.init(children_process, strategy: :one_for_one)
  end

  def generate_agent_process_list(agent_number, room_id, specify_id, agent_process_list) do
    if agent_number > 0 do
      updated_agent_process_list =
        case Map.get(specify_id, agent_number - 1, nil) do
          nil ->
            [{WerefoxBackend.Agent, [room_id, agent_number - 1, ""]} | agent_process_list]

            Supervisor.init([{WerefoxBackend.Agent, [room_id, agent_number - 1, ""]}],
              strategy: :one_for_one
            )

          name ->
            [{WerefoxBackend.Agent, [room_id, agent_number - 1, name]} | agent_process_list]

            Supervisor.init([{WerefoxBackend.Agent, [room_id, agent_number - 1, name]}],
              strategy: :one_for_one
            )
        end

      # IO.inspect(updated_agent_process_list)
      generate_agent_process_list(
        agent_number - 1,
        room_id,
        specify_id,
        updated_agent_process_list
      )
    else
      agent_process_list
    end
  end
end
