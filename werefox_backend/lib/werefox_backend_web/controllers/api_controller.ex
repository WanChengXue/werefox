defmodule WerefoxBackendWeb.ApiController do
    use WerefoxBackendWeb, :controller
    def init_game(conn, %{"config" => config}) do
        # 要求传入的config是一个json
    end


    def run_game(conn, %{"agent_name" => agent_name, "new_sentense" => new_sentense, "room_id" => room_id}) do

    end


    def get_summary(conn, %{"room_id" => room_id}) do

    end


    defp config_parse(config) do
        # 定义一下数据格式

        
    end

end