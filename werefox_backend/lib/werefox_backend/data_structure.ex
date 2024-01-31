defmodule WerefoxBackend.DataStructure do
  def convert_string_to_map(input) do
    case String.match?(input, ~r/^\[{(.*)}\]$/) do
      true -> convert_data(input)
      false -> %{}
    end
  end

  defp convert_data(input) do
    case String.replace(input, "[{", "")
         |> String.replace("}]", "")
         |> String.replace("{", "")
         |> String.replace("}", "")
         |> String.split(", ") do
      [type | data] ->
        Enum.reduce(data, convert_item(type), fn item, acc ->
          convert_item(item) |> Map.merge(acc)
        end)

      [] ->
        %{}
    end
  end

  defp convert_item(item) do
    case String.split(item, ": ") do
      [key, value] ->
        %{String.to_integer(key) => value}

      _ ->
        %{}
    end
  end
end
