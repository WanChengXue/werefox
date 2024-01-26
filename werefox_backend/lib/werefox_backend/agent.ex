defmodule WerefoxBackend.Agent do
    use GenServer
    import OpenaiEx

    def init(identity) do
        openai_bot = OpenaiEx.new("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")
        {:ok, %{"identity" => identity, "ai_bot" => openai_bot, "private_message" => []}}
    end

    def handle_call({:ai, %{"context" => context}}, _from, state) do
        # 这个context是一个[%{}]类型的数据, 这里还有一个合并的操作
        chat_req = %{
            messages: context,
            model: "gpt-3.5-turbo"
        }
        %{"choices" => [%{"message" => %{"content" => content}}]} = 
            state["ai_bot"] |> OpenaiEx.ChatCompletion.create(chat_req)
        {:reply, content, state}
    end


    def handle_cast({:private_message, content}, state) do
        Map.put("private_message", state["private_message"] ++ [content])
        {:noreply, state}
    end

    
    def start_link(room_id, agent_indentity) do
        agent_name = String.to_atom("#{room_id}_#{agent_indentity}")
        GenServer.start_link(__MODULE__, agent_indentity, name: agent_name)
    end

    def send_message(pid, message) do
        GenServer.call(pid, message)
    end


    defp concatenate_messeage(content, private_message) do
        # 思考，这个位置究竟放什么信息
    end
end