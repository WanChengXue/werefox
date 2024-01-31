defmodule WerefoxBackend.RoomController do
  use GenServer

  def init({room_id, config}) do
    agent_number = config["agent_number"]
    agents_list = config["agents"]
    specify_id_map = specify_id(agents_list, %{})
    # start_agent(room_id, agent_number, specify_id_map)
    %{"end_rule_prompt"=>end_rule_prompt, "rule_prompt" => rule_prompt} = config["prompts"]
    pid_table = start_agent(room_id, agent_number, specify_id_map, agents_list, %{}, rule_prompt, end_rule_prompt)
    IO.inspect(pid_table)
    {:ok, %{"pid_table" => pid_table, "context" => [%{role: "system", content: "请根据上面的系统提示，判断出当前的游戏状态，然后用提示的动输出格式输出"}]}}
  end

  def handle_call({:run, room_id}, _from, state) do
    history_context = state["context"]
    god_pid = String.to_atom("#{room_id}_0")
    res_string = WerefoxBackend.Agent.send_message(god_pid, {:ai, history_context})
    # new_context = state["context"] ++ [%{"0" => res_string}]
    # state = %{"pid_table" => state["pid_table"], "context" => new_context}
    {:reply, res_string, state}
  end

  def start_link(room_id, config) do
    IO.puts("room start")
    GenServer.start_link(__MODULE__, {room_id, config})
  end

  defp specify_id([user | other_user], specify_id_map) do
    case user do
      %{"user_id" => user_id, "name" => "unknown"} ->
        specify_id(other_user, specify_id_map)

      %{"user_id" => user_id, "name" => name} ->
        specify_id_map = Map.put(specify_id_map, user_id, name)

      _ ->
        specify_id_map
    end
  end

  defp start_agent(room_id, agent_number, specify_id, agents_list, pid_name_map, rule_prompt, end_game_prompt) do
    if agent_number > 0 do
      {:ok, pid} =
        case Map.get(specify_id, agent_number - 1, nil) do
          nil ->
            WerefoxBackend.Agent.start_link({room_id, agent_number - 1, "", agents_list, rule_prompt, end_game_prompt})

          name ->
            WerefoxBackend.Agent.start_link({room_id, agent_number - 1, name, agents_list, rule_prompt, end_game_prompt})
        end

      update_pid_name_map = Map.put(pid_name_map, "#{room_id}_#{agent_number - 1}", pid)
      start_agent(room_id, agent_number - 1, specify_id, agents_list, update_pid_name_map, rule_prompt, end_game_prompt)
    else
      pid_name_map
    end
  end

  def run_game({room_id, room_pid}) do
    GenServer.call(room_pid, {:run, room_id}, 120000)
  end

end
