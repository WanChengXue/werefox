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
    {:ok, %{"pid_table" => pid_table, "context" => [], "next_action" => [], "step" => 0, "cursor"=>0}}
  end

  def handle_call({:run, room_id}, _from, state) do
    history_context = state["next_action"]
    game_step = state["step"]
    # 处理next_action 这一段，一个动作一个动作的进行处理
    {agent_pid, {broadcast_type, sender, reciever, content, reply_type}, rest_action} =
      generate_agent_next_action(room_id, history_context)

    message_type = generate_message_type({reply_type, broadcast_type})
    IO.inspect({"------", {agent_pid, message_type, content, game_step}})

    {new_context, new_next_action, new_cursor} =
      case reply_type do
        :reply ->
          {agent_index, agent_action} =
            WerefoxBackend.Agent.send_message(
              agent_pid,
              {message_type, {sender, content}, game_step, state["cursor"]}
            )

          # 返回的是这一个回合所有人的动作后的结果汇总也是一个[%{}， %{}]类型的list
          new_context = add_public_output_to_content(state["context"], agent_action, game_step)
          new_next_action = rest_action ++ WerefoxBackend.DataStructure.flatten_data(agent_index, agent_action, [])
          {new_context, new_next_action, state["cursor"]+1}

        :no_reply ->
          WerefoxBackend.Agent.send_message(
            agent_pid,
            {message_type, {sender, content}, game_step, state["cursor"]}
          )

          {state["context"], rest_action, state["cursor"]}
      end


    updated_state =
      state
      |> Map.put("context", new_context)
      |> Map.put("next_action", new_next_action)
      |> Map.put("step", game_step + 1)
      |> Map.put("cursor", new_cursor)
    IO.inspect("xxxxxx updated_state xxxxx")
    IO.inspect(updated_state)
    # state = %{"pid_table" => state["pid_table"], "context" => new_context}
    agent_history = get_total_agent_history(state["pid_table"])
    {:reply, agent_history, updated_state}
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

  defp add_public_output_to_content(prev_content_list, agent_action, step) do
    # prev_content_list = [{"0", content, "1", content}]
    case Enum.filter(agent_action, fn {type, _} -> type == :public end) do
      [{:public, [{index, message, _}]}] ->
        prev_content_list ++ [{step, index, message}]

      _ ->
        prev_content_list
    end
  end

  def generate_agent_next_action(room_id, history_action_list) do
    case history_action_list do
      [] ->
        {String.to_atom("#{room_id}_#{0}"), {:private, "0", "0", "", :reply}, []}

      [exec_action | rest_action] ->
        {_, sender, receiver, _, _} = exec_action
        {String.to_atom("#{room_id}_#{receiver}"), exec_action, rest_action}
    end
  end

  defp generate_message_type({reply_type, message_type}) do
    case {reply_type, message_type} do
      {:reply, :private} -> :private_ask
      {:reply, :public} -> :public_ask
      {:no_reply, :private} -> :private_info
      {:no_reply, :public} -> :public_info
    end
  end

  defp get_total_agent_history(pid_map) do
    Enum.reduce(pid_map, %{}, fn {name, pid}, acc ->
      Map.put(acc, name, WerefoxBackend.Agent.get_agent_history_context(pid))
    end)
  end

  def run_game({room_id, room_pid}) do
    GenServer.call(room_pid, {:run, room_id}, 120_000)
  end
end
