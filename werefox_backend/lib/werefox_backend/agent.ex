defmodule WerefoxBackend.Agent do
  use GenServer
  import OpenaiEx
  import Jason

  def init({room_id, index, identity, agents_list, rule_prompt, end_game_prompt}) do
    config_path = Path.join(File.cwd!(), "lib/werefox_backend/game_yaml/werefox_template.json")
    {:ok, raw_content} = File.read(config_path)
    {:ok, ai_bot} = Jason.decode(raw_content)

    # openai_bot =
    #   OpenaiEx.new("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")
    #   |> OpenaiEx.with_receive_timeout(120_000)

    {:ok,
     %{
       "room_id" => room_id,
       "index" => Integer.to_string(index),
       "identity" => identity,
       "ai_bot" => ai_bot,
       "private_message" => [],
       "public_message" => [],
       "agent_list_message" => agents_list,
       "rule_prompt" => rule_prompt,
       "end_game_prompt" => end_game_prompt
     }}
  end

  def handle_call({:ai, {sender_index, content}, step, cursor}, _from, state) do
    identity = state["identity"]
    [%{"prompt_template" => prompt, "memory_type" => memory_type}] =
      Enum.filter(state["agent_list_message"], fn agent -> agent["name"] == identity end)

    # 这个content的数据格式是[{step, index, message形式}]
    concat_string =
      history_content_generate({
        state["public_message"],
        state["private_message"],
        [{step, sender_index, content}]
      })

    # rule 文本
    game_rule_prompt = %{role: "system", content: state["rule_prompt"]}
    end_game_prompt = %{role: "system", content: state["end_game_prompt"]}
    # 将prompt中${history}用history_string 进行替换掉
    replace_context_placeholder_prompt =
      String.replace(prompt, "${#{memory_type}}", concat_string)

    user_system_prompt = %{role: "user", content: prompt}

    # private_system_prompt = %{role: "user", content: "以下是只有你和你队友才知道的私有信息"}
    concat_message =
      [game_rule_prompt] ++ [end_game_prompt] ++ [user_system_prompt]

    IO.inspect({"======raw action =======", step, cursor, state["index"]})
    raw_action_string = state["ai_bot"][Integer.to_string(cursor)][state["index"]]
    # chat_req = %{
    #   messages: concat_message,
    #   model: "gpt-3.5-turbo"
    # }
    IO.inspect(raw_action_string)
    action_result = WerefoxBackend.DataStructure.parse_data(raw_action_string)
    IO.inspect(action_result)
    {:reply, {state["index"], action_result}, state}
  end

  def handle_call(:get_history, _, state) do
    concat_history =
      history_content_generate({
        state["public_message"],
        state["private_message"],
        []
      })

    {:reply, concat_history, state}
  end

  def handle_cast({:private, {sender_index, content}, step}, state) do
    identity =
      case state["identity"] do
        "" -> content
        _ -> state["identity"]
      end

    update_private_list = state["private_message"] ++ [{step, sender_index, content}]

    update_state =
      Map.put(state, "private_message", update_private_list) |> Map.put("identity", identity)

    {:noreply, update_state}
  end

  def handle_cast({:public, {sender_index, content}, step}, state) do
    update_public_list = state["public_message"] ++ [{step, sender_index, content}]
    update_state = Map.put(state, "public_message", update_public_list)
    {:noreply, update_state}
  end

  def start_link(
        {room_id, agent_index, agent_indentity, agents_list, rule_prompt, end_game_prompt}
      ) do
    agent_name = String.to_atom("#{room_id}_#{agent_index}")

    GenServer.start_link(
      __MODULE__,
      {room_id, agent_index, agent_indentity, agents_list, rule_prompt, end_game_prompt},
      name: agent_name
    )
  end

  def send_message(pid, message) do
    {message_type, context, game_step, cursor} = message

    case message_type do
      # 四种消息类型
      :private_ask ->
        action_list = GenServer.call(pid, {:ai, context, game_step, cursor})
        GenServer.cast(pid, {:private, context, game_step})
        action_list

      :public_ask ->
        action_list = GenServer.call(pid, {:ai, context, game_step, cursor})
        GenServer.cast(pid, {:public, context, game_step})
        action_list

      :private_info ->
        GenServer.cast(pid, {:private, context, game_step})

      :public_info ->
        GenServer.cast(pid, {:public, context, game_step})
    end
  end

  def get_agent_history_context(pid) do
    GenServer.call(pid, :get_history)
  end

  defp generate_process_pid(room_id, agent_index) do
    String.to_atom("#{room_id}_#{agent_index}")
  end

  defp history_content_generate({public_content, private_content, current_content}) do
    # 三部分文本构成，公开文本，只有自己知道的文本，以及最新的一句文本
    public_string_list =
      Enum.map(public_content, fn {step, index, message} -> {step, "#{index}: #{message}"} end)

    private_string_list =
      Enum.map(private_content, fn {step, index, message} -> {step, "#{index}: #{message}"} end)

    concat_string_list =
      Enum.concat(public_string_list, private_string_list)
      |> Enum.concat(current_content)
      |> Enum.sort_by(&elem(&1, 0))

    concat_string = Enum.join(Enum.map(concat_string_list, &elem(&1, 1)), "\n")
  end
end
