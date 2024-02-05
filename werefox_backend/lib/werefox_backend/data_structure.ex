defmodule WerefoxBackend.DataStructure do
  def parse_data(data_str) do
      private_regex = ~r/private: \[(.*?)\]/
      public_regex = ~r/public:\s*(.*)$/

      private_data =
        case Regex.run(private_regex, data_str) do
          nil ->
            []

          [_, matched_string] ->
            [{:private, parse_action_item(matched_string)}]
        end

      public_data =
        case Regex.run(public_regex, data_str) do
          nil ->
            []

          [_, matched_string] ->
            [{:public, parse_action_item(matched_string)}]
        end

      private_data ++ public_data
    end


  defp parse_action_item(item_str) do
    pattern = ~r/{([^{}]+)}/
    action_string_list = Regex.scan(pattern, item_str)

    Enum.map(action_string_list, fn [_, action_string] -> parse_single_action_string(action_string) end)
  end

  defp parse_single_action_string(action_string) do
    pattern = ~r/([^:]+):\s*([^#]+)\s*#\s*([^#]+)/

    case Regex.run(pattern, action_string) do
      [_, receiver, content, reply_type] -> {receiver, content, String.to_atom(reply_type)}
      _ -> nil
    end
  end

  def flatten_data(sender, [], acc) do
    acc
  end

  def flatten_data(sender, [head | tail], acc) do
    case head do
      {:private, data} ->
        private_data =
          acc ++
            Enum.map(data, fn {receiver, content, reply_type} ->
              {:private, sender, receiver, content, reply_type}
            end)

        flatten_data(sender, tail, private_data)

      {:public, data} ->
        public_data =
          acc ++
            Enum.map(data, fn {receiver, content, reply_type} ->
              {:public, sender, receiver, content, reply_type}
            end)

        flatten_data(sender, tail, public_data)

      _ ->
        flatten_data(sender, tail, acc)
    end
  end

end
