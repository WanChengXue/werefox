defmodule WerefoxBackend.RoomController do
  use GenServer

  def init({room_id, config}) do
    agent_number = config["agent_number"]
    agents_list = config["agents"]
    specify_id_map = specify_id(agents_list, %{})
    # start_agent(room_id, agent_number, specify_id_map)
    %{"end_rule_prompt" => end_rule_prompt, "rule_prompt" => rule_prompt} = config["prompts"]

    pid_table =
      start_agent(
        room_id,
        agent_number,
        specify_id_map,
        agents_list,
        %{},
        rule_prompt,
        end_rule_prompt
      )

    IO.inspect(pid_table)
    {:ok, %{"pid_table" => pid_table, "context" => [], "next_action" => []}}
  end

  def handle_call({:run, room_id}, _from, state) do
    history_context = state["context"]

    # 处理next_action 这一段，一个动作一个动作的进行处理
    {agent_pid, content, rest_action, message_type} = generate_agent_next_action({room_id, history_context})
    {agent_index, agent_action} =
      WerefoxBackend.Agent.send_message(agent_pid, {message_type, history_context})

    # 返回的是这一个回合所有人的动作后的结果汇总也是一个[%{}， %{}]类型的list
    new_context = add_public_output_to_content(state["context"], agent_action)

    updated_state =
      state |> Map.put("context", new_context) |> Map.put("next_action", agent_action)

    IO.inspect(updated_state)
    # state = %{"pid_table" => state["pid_table"], "context" => new_context}
    {:reply, new_context, state}
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

  defp start_agent(
         room_id,
         agent_number,
         specify_id,
         agents_list,
         pid_name_map,
         rule_prompt,
         end_game_prompt
       ) do
    if agent_number > 0 do
      {:ok, pid} =
        case Map.get(specify_id, agent_number - 1, nil) do
          nil ->
            WerefoxBackend.Agent.start_link(
              {room_id, agent_number - 1, "", agents_list, rule_prompt, end_game_prompt}
            )

          name ->
            WerefoxBackend.Agent.start_link(
              {room_id, agent_number - 1, name, agents_list, rule_prompt, end_game_prompt}
            )
        end

      update_pid_name_map = Map.put(pid_name_map, "#{room_id}_#{agent_number - 1}", pid)

      start_agent(
        room_id,
        agent_number - 1,
        specify_id,
        agents_list,
        update_pid_name_map,
        rule_prompt,
        end_game_prompt
      )
    else
      pid_name_map
    end
  end

  defp add_public_output_to_content(prev_content_list, agent_action) do
    case Enum.filter(agent_action, fn {type, _} -> type == :public end) do
      [{:public, public_action}] ->
        IO.inspect(public_action)
        prev_content_list ++ public_action

      _ ->
        prev_content_list
    end
  end

  defp generate_agent_next_action({room_id, next_action_list}) do
    case next_action_list do
      [] ->
        agent_pid = String.to_atom("#{room_id}_0")
        {agent_pid, "", [], :ai}

      [[{:private, private_action_list}, {:public, public_action_list}] | rest_action] ->
        [{agent_index, content} | rest_private_action] = private_action_list
        agent_pid = String.to_atom("#{room_id}_#{agent_index}")

        next_private_list =
          case rest_private_action do
            [] ->
              [{:public, public_action_list}]

            _ ->
              [{:private, rest_private_action}, {:public, public_action_list}]
          end

        {agent_pid, content, next_private_list, :private}

      [[{:private, private_action_list}] | rest_action] ->
        [{agent_index, content} | rest_private_action] = private_action_list
        agent_pid = String.to_atom("#{room_id}_#{agent_index}")

        next_private_list =
          case rest_private_action do
            [] ->
              []

            _ ->
              [{:private, rest_private_action}]
          end

        {agent_pid, content, next_private_list, :private}

      [[{:public, public_action_list}] | rest_action] ->
        [{agent_index, content} | rest_public_action] = public_action_list
        agent_pid = String.to_atom("#{room_id}_#{agent_index}")

        next_public_list =
          case rest_public_action do
            [] ->
              []

            _ ->
              [{:public, rest_public_action}]
          end

        {agent_pid, content, next_public_list, :public}
    end
  end

  def run_game({room_id, room_pid}) do
    GenServer.call(room_pid, {:run, room_id}, 120_000)
  end
end
