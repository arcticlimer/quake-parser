defmodule QuakeLogs.Parser do
  @moduledoc """
  Parser for Quake logs
  """

  @game_object %{kills: %{}, total_kills: 0, kills_by_means: %{}}
  @log_object %{current_game: nil, games: [], global_ranking: %{}}

  @doc """
  Receives a raw logs string, parses it and returns a
  map containing useful information about the logs
  """
  def parse(log_lines) do
    log_lines
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reduce(@log_object, &reduce_parse/2)
  end

  defp reduce_parse(line, acc) do
    # TODO track clients by ID
    case parse_line(line) do
      {:new_game, _} ->
        Map.put(acc, :current_game, @game_object)
      {:game_ended, _} ->
        {game, updated_map} = Map.pop!(acc, :current_game)
        Map.update(updated_map, :games, [], &(&1 ++ [game]))
      {:kill, %{"dead" => dead, "killer" => killer, "meaning" => meaning}} ->
        acc
        |> update_game_total_kills(&inc/1)
        |> update_kill_by_meaning(meaning, &inc/1)
        |> update_player_kills(killer, &inc/1)
        |> update_player_kills(dead, &dec/1)
        |> update_global_ranking(killer, &inc/1)
        |> update_global_ranking(dead, &dec/1)
      {:error, _} ->
        acc
    end
  end

  defp parse_line(line) do
    cond do
      event?(line, "InitGame") ->
        {:new_game, nil}
      event?(line, "ShutdownGame") ->
        {:game_ended, nil}
      event?(line, "Kill") ->
        {:kill,
          Regex.named_captures(
            ~r'\d+:\s(?<killer>.+)\skilled\s(?<dead>.+)\sby\s(?<meaning>.+)$',
            line
          )
        }
      true ->
        {:error, "Unknown expression."}
    end
  end

  defp inc(n), do: n + 1
  defp dec(n), do: n - 1

  defp update_kill_by_meaning(global_log, meaning, callback) do
    meaning_key = Access.key(meaning, 0)
    update_in(
      global_log,
      [:current_game, :kills_by_means, meaning_key],
      callback
    )
  end

  defp update_global_ranking(global_log, player, callback) do
    player_key = Access.key(player, 0)
    update_in(global_log, [:global_ranking, player_key], callback)
  end

  defp update_game_total_kills(global_log, callback) do
    update_in(global_log, [:current_game, :total_kills], callback)
  end

  defp update_player_kills(global_log, player, callback) do
    player_kill = Access.key(player, 0)
    update_in(global_log, [:current_game, :kills, player_kill], callback)
  end

  defp event?(line, event) do
    String.match?(line, ~r'^\d{1,2}:\d{2}\s#{event}:')
  end
end
