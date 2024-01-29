defmodule WerefoxBackend.RoomController do
    use GenServer


    def init({room_id, config}) do
        agent_number = config["agent_number"]
        agents_list = config["agents"]
        specify_id_map = specify_id(agents_list, %{})
        WerefoxBackend.AgentSupervisor.start_link(room_id, agent_number, specify_id_map)
        {:ok, %{}}
    end


    def handle_call(messeage, _from , state) do
        {:ok, %{}, state}
    end


    def start_link(room_id, config) do 
        IO.puts("room start")
        GenServer.start_link(__MODULE__, {room_id, config})
    end


    defp specify_id([user | other_user], specify_id_map) do
        case user do
            %{"user_id" => user_id, "name" => "unknown"}  ->
                specify_id(other_user, specify_id_map)
            %{"user_id" => user_id, "name" => name} ->
                specify_id_map = Map.put(specify_id_map, user_id, name)
            _ -> 
                specify_id_map
        end
    end
end