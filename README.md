# Wind 🌬️

A pleasant Elixir websocket client library, based on Mint and Mint.WebSocket.

This library was extracted from a high-volume websocket client in an
application where speed is a critical priority.  Since the implementing code
was highly varied, this library aims to provide a minimal framework that
doesn't get in the way and provides composable tools to avoid the typical
boilerplate.

Note that each connection starts a `GenServer` instead of all the connections
being managed by a dispacting process.  This design decision was intentional in
order to maintain the speed requirement (and prevent the dispatching process
from becoming the bottleneck).  However, this may come at a cost of some syntax
sugar you might find in other libraries.

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

## Example

Below is a minimal example to show how you could create a websocket client.

```elixir
defmodule BinanceMonitor do
  use Wind.Stream, ping_timer: 30_000

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

## TODO

* Add telemetry.
* Add additional event handling.
