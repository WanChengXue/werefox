defmodule WerefoxBackendWeb.ApiController do
    use WerefoxBackendWeb, :controller
    import YamlElixir

    def init_game(conn, _) do
        # 要求传入的config是一个json, 这里使用本地路径替代
        config_path = Path.join(File.cwd!(), "lib/werefox_backend/game_yaml/werefox.yaml")
        config = YamlElixir.read_from_file(config_path)
        {:ok, response} = config
        WerefoxBackend.RoomCache.start_room(response)
        conn
        |> put_status(:ok)
        |> json(%{"init" => response})
    end


    def run_game(conn, %{"agent_name" => agent_name, "new_sentense" => new_sentense, "room_id" => room_id}) do

    end


    def get_summary(conn, %{"room_id" => room_id}) do

    end


    defp config_parse(config) do
        # 定义一下数据格式


    end

end