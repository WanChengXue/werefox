defmodule WerefoxBackend.Agent do
  use GenServer
  import OpenaiEx

  def init({room_id, index, identity, agents_list, rule_prompt, end_game_prompt}) do
    openai_bot =
      OpenaiEx.new("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")
      |> OpenaiEx.with_receive_timeout(120_000)

    {:ok,
     %{
       "room_id" => room_id,
       "index" => index,
       "identity" => identity,
       "ai_bot" => openai_bot,
       "private_message" => [],
       "agent_list_message" => agents_list,
       "rule_prompt" => rule_prompt,
       "end_game_prompt" => end_game_prompt
     }}
  end

  # [{:private}]
  def handle_call({:ai, context}, _from, state) do
    identity = state["identity"]

    [%{"prompt_template" => prompt, "memory_type" => memory_type}] =
      Enum.filter(state["agent_list_message"], fn agent -> agent["name"] == identity end)

    history_string =
      Enum.map(context, fn {index, message} -> "#{index}: #{message}" end) |> Enum.join("\n")

    # rule 文本
    game_rule_prompt = %{role: "system", content: state["rule_prompt"]}
    end_game_prompt = %{role: "system", content: state["end_game_prompt"]}
    # 将prompt中${history}用history_string 进行替换掉
    replace_context_placeholder_prompt =
      String.replace(prompt, "${#{memory_type}}", history_string)

    user_system_prompt = %{role: "user", content: prompt}
    private_system_prompt = %{role: "user", content: "以下是只有你和你队友才知道的私有信息"}

    concat_message =
      [game_rule_prompt] ++
        [end_game_prompt] ++
        [user_system_prompt] ++ [private_system_prompt] ++ state["private_message"]

    chat_req = %{
      messages: concat_message,
      model: "gpt-3.5-turbo"
    }

    # %{"choices" => [%{"message" => %{"content" => content}}]} =
    #   state["ai_bot"] |> OpenaiEx.ChatCompletion.create(chat_req)
    # action_result = WerefoxBackend.DataStructure.convert_string_to_map(content)
    content =
      "[{private: [{1: 猎人}, {2: 平民}, {3: 平民}, {4: 平民}, {5: 狼人}, {6: 狼人}, {7: 预言家}, {8: 狼人}, {9: 女巫}]}, {public: [{0: 身份分发完毕}]}]"

    # action_result = WerefoxBackend.DataStructure.convert_string_to_map(content)
    action_result = [
      {:private,
       [
         {1, "猎人"},
         {2, "平民"},
         {3, "平民"},
         {4, "平民"},
         {5, "狼人"},
         {6, "狼人"},
         {7, "预言家"},
         {8, "狼人"},
         {9, "女巫"}
       ]},
      {:public, [{0, "身份分发完毕"}]}
    ]

    # 如action_result = [{:private, [%{}, %{}]}], [{:public, [%{}]}] / [{:private, [%{}, %{}]}, {:public, [%{}, %{}]}]
    {:reply, {state["index"], action_result}, state}
  end

  def handle_cast({:private_message, content}, state) do
    Map.put("private_message", state["private_message"] ++ [content])
    {:noreply, state}
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
    timeout = 120_000
    GenServer.call(pid, message, timeout)
  end

  defp generate_process_pid(room_id, agent_index) do
    String.to_atom("#{room_id}_#{agent_index}")
  end

  defp convert_chat_list_to_chat_string(chat_content_list) do
  end
end
