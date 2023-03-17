# Wind

A pleasant Elixir websocket client framework, based on Mint and Mint.WebSocket. 🌱

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `wind` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:wind, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/wind>.

## Example

Below is a minimal example to show how you could create a websocket client.

```elixir
defmodule BinanceMonitor do
  use Wind.Stream

  def start_link() do
    uri = URI.new!("wss://data-stream.binance.com/ws")
    Wind.Stream.start_link(__MODULE__, uri: uri)
  end

  def handle_connect(state) do
    message = Jason.encode!(%{method: "SUBSCRIBE", params: ["btcusdt@aggTrade"], id: 1})
    {:reply, {:text, message}, state}
  end

  def handle_frame({:text, message}, state) do
    data = Jason.decode!(message)
    IO.inspect(data)

    {:noreply, state}
  end
end
```
