defmodule QuakeLogs do
  use Application

  def start(_type, _opts) do
    File.read!("lib/data/quake.log")
    |> QuakeLogs.Parser.parse()
    |> IO.inspect()

    {:ok, self()}
  end
end
