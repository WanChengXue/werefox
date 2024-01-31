defmodule WerefoxBackend.Agent do
  use GenServer
  import OpenaiEx

  def init({room_id, index, identity, agents_list, rule_prompt, end_game_prompt}) do
    openai_bot = OpenaiEx.new("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")|> OpenaiEx.with_receive_timeout(120_000)

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

  def handle_call({:ai, context}, _from, state) do
    identity = state["identity"]
    [%{"prompt_template" => prompt, "memory_type" => memory_type}] =
      Enum.filter(state["agent_list_message"], fn agent -> agent["name"] == identity end)
    # rule 文本
    game_rule_prompt = %{role: "system", content: state["rule_prompt"]}
    end_game_prompt = %{role: "system", content: state["end_game_prompt"]}
    # 系统文本
    user_system_prompt = %{role: "user", content: prompt}
    # private_system_prompt = %{role: "user", content: "以下是只有你和你队友才知道的私有信息"}

    # public文本 + 系统文本 + 私有文本进行拼接[game_rule_prompt] ++ [end_game_prompt] ++ context ++
    concat_message = [user_system_prompt]
    chat_req = %{
      messages: context,
      model: "gpt-3.5-turbo"
    }
    IO.inspect(chat_req)
    model_output = state["ai_bot"] |> OpenaiEx.ChatCompletion.create(chat_req)
    IO.inspect(model_output)
    %{"choices" => [%{"message" => %{"content" => content}}]} = model_output
    {:reply, %{state["index"] => content}, state}
  end

  def handle_cast({:private_message, content}, state) do
    Map.put("private_message", state["private_message"] ++ [content])
    {:noreply, state}
  end

  def start_link({room_id, agent_index, agent_indentity, agents_list, rule_prompt, end_game_prompt}) do
    agent_name = String.to_atom("#{room_id}_#{agent_index}")

    GenServer.start_link(__MODULE__, {room_id, agent_index, agent_indentity, agents_list, rule_prompt, end_game_prompt},
      name: agent_name
    )
  end

  def send_message(pid, message) do
    timeout = 120000
    GenServer.call(pid, message, timeout)
  end

  defp generate_process_pid(room_id, agent_index) do
    String.to_atom("#{room_id}_#{agent_index}")
  end

  def filter_prompt([activate_agent | rest_agent], agent_name) do
    case activate_agent do
      %{"name" => agent_name} -> activate_agent
      _ -> filter_prompt(rest_agent, agent_name)
    end
  end

end
