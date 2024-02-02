defmodule WerefoxBackend.DataStructure do
  def parse_data(data_str) do
    private_regex = ~r/private: \[(.*?)\]/
    public_regex = ~r/public: \[(.*?)\]/

    private_data = Regex.scan(private_regex, data_str)
                   |> List.first()
                   |> List.last()
                   |> String.split(", ")
                   |> Enum.map(&parse_private_item/1)

    public_data = Regex.scan(public_regex, data_str)
                  |> List.first()
                  |> List.last()
                  |> String.split(", ")
                  |> Enum.map(&parse_public_item/1)

    [
      {:private, private_data},
      {:public, public_data}
    ]
  end

  defp parse_private_item(item_str) do
    {key, value} = String.split(item_str, ": ")

    {String.to_integer(key), String.replace(value, "\"", "")}
  end

  defp parse_public_item(item_str) do
    {key, value} = String.split(item_str, ": ")

    case key do
      "all" -> {:public, [:all, String.replace(value, "\"", "")]}
      _ -> {:public, [String.to_atom(key), String.replace(value, "\"", "")]}
    end
  end
end