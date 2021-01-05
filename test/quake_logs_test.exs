defmodule QuakeLogsTest do
  use ExUnit.Case

  test "creates and finish a game" do
    logs = """
      0:00 InitGame:
      20:37 ShutdownGame:
    """
    result = QuakeLogs.Parser.parse(logs)
    assert result |> Map.get(:games) |> length() == 1
    assert Map.get(result, :current_game) == nil
  end

  test "parses a game correctly" do
    logs = """
      1:20 InitGame:
      2:20 Kill: 4 8 12: Zeh killed Isgalamido by MOD_BFG
      2:23 Kill: 4 8 12: Isgalamido killed Ronalducho by MOD_TEST_WEAPON
      2:23 Kill: 4 8 12: Zeh killed Ronalducho by MOD_TEST_WEAPON
      2:23 Kill: 4 8 12: Ronalducho killed Isgalamido by MOD_TEST_WEAPON
      3:47 ShutdownGame:
    """
    result = QuakeLogs.Parser.parse(logs)
    game = result |> Map.get(:games) |> Enum.at(0)

    assert game.total_kills == 4
    assert game.kills["Zeh"] == 2
    assert game.kills_by_means["MOD_TEST_WEAPON"] == 3
  end

  test "parses more than one game correctly" do
    logs = """
      1:20 InitGame:
      2:20 Kill: 4 8 12: Zeh killed Isgalamido by MOD_BFG
      2:23 Kill: 4 8 12: Isgalamido killed Ronalducho by MOD_TEST_WEAPON
      2:23 Kill: 4 8 12: Zeh killed Ronalducho by MOD_TEST_WEAPON
      2:23 Kill: 4 8 12: Ronalducho killed Isgalamido by MOD_TEST_WEAPON
      3:47 ShutdownGame:
      5:12 InitGame:
      2:20 Kill: 4 8 12: Isgalamido killed Zeh by MOD_BFG
      2:23 Kill: 4 8 12: Isgalamido killed Ronalducho by MOD_RAILGUN
      2:23 Kill: 4 8 12: Isgalamido killed Ronalducho by MOD_RPG
      2:23 Kill: 4 8 12: Ronalducho killed Isgalamido by MOD_RPG
      7:42 ShutdownGame:
    """
    game2_guns = ["MOD_BFG", "MOD_RAILGUN", "MOD_RPG"]

    result = QuakeLogs.Parser.parse(logs)
    assert result.global_ranking["Isgalamido"] == 1
    assert result.global_ranking["Ronalducho"] == -2
    assert length(result.games) == 2
    assert length(result.games) == 2
    assert result.games
    |> Enum.at(1)
    |> Map.get(:kills_by_means)
    |> Map.keys()
    |> Enum.all?(fn gun -> gun in game2_guns end)
  end

  @tag :pending
  test "track clients by id" do

  end
end
