defmodule WerefoxBackendWeb.ApiController do
  use WerefoxBackendWeb, :controller
  import YamlElixir

  def init_game(conn, _) do
    # 要求传入的config是一个json, 这里使用本地路径替代
    config_path = Path.join(File.cwd!(), "lib/werefox_backend/game_yaml/werefox.yaml")
    {:ok, response} = YamlElixir.read_from_file(config_path)
    room_pid = WerefoxBackend.RoomCache.start_room(response)

    conn
    |> put_status(:ok)
    |> json(%{"room_pid" => room_pid})
  end

  def run_game(conn, %{"room_id" => room_id}) do
    strip_room_id = String.replace(room_id, ~r/\\|"|"/, "")
    room_pid = WerefoxBackend.RoomCache.get_room_pid(strip_room_id)
    game_log = WerefoxBackend.RoomController.run_game({strip_room_id, room_pid})
    # IO.inspect(game_log)

    conn
    |> put_status(:ok)
    |> json(game_log)
  end

  def get_summary(conn, %{"room_id" => room_id}) do
  end

  def get_room_table(conn, _) do
    room_table_list = WerefoxBackend.RoomCache.get_room_table()
    IO.inspect(room_table_list)

    conn
    |> put_status(:ok)
    |> json(%{"room_table" => room_table_list})
  end
end
