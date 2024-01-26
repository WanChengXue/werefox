defmodule WerefoxBackend.RoomCache do
    use GenServer
    def init(_) do
        IO.puts("Room Cache start!")
        {:ok, Map.new()}
    end


    def handle_call({:room_worker, %{"room_id" => room_id}}, _, state) do

    end

    def handle_call({:start_room,  config}, _from, state) do
        random_room_id = Base.url_encode64(:crypto.strong_rand_bytes(16))
        {:ok, pid} = WerefoxBackend.RoomController.start_link(random_room_id, config)
        Map.put(state, random_room_id, pid)
        {:reply, random_room_id, state}
    end


    def start_link(args) do
        GenServer.start_link(__MODULE__, args, name: :room_cache)
    end


    def get_room_pid(%{"room_id"=>room_id}) do
        GenServer.call(:room_cache, {:room_worker, %{"room_id"=>room_id}})
    end

    def start_room(config) do
        GenServer.call({:start_room, config})
    end
end