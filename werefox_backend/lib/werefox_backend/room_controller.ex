defmodule WerefoxBackend.RoomController do
    use GenServer
    
    def init(room_id, config) do
        # 需要拆分config内容，然后交由agent_supervisor启动所有的智能体
        {:ok, %{}}
    end


    def handle_call(messeage, _from , state) do

    end


    def start_link(room_id, config) do 
        GenServer.start_link(__MODULE__, {room_id, config})
    end
end