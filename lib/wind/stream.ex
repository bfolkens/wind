defmodule Wind.Stream do
  @moduledoc """
  `Stream` is the basis for creating a connection module in your application.

  ```elixir
    defmodule Example do
      use Wind.Stream

      def start_link() do
        uri = URI.new!("http://example.com/ws")
        Wind.Stream.start_link(__MODULE__, uri: uri)
      end

      def handle_connect(state) do
        # Handle any post-connect setup here.
        {:noreply, state}
      end

      def handle_frame({type, message}, state) do
        IO.inspect({type, message}, label: "frame")
        {:noreply, state}
      end
    end
  ```
  """

  def start_link(module, default, options \\ []) when is_list(default) do
    GenServer.start_link(module, default, options)
  end

  def send(pid, message) do
    GenServer.cast(pid, {:send, message})
  end

  # TODO: Add telemetry
  # TODO: opts for ping (timer milliseconds?)
  defmacro __using__(_opts) do
    quote location: :keep do
      use GenServer
      require Logger

      @impl true
      def init(opts) do
        state = %{
          opts: opts,
          conn_info: nil
        }

        {:ok, state, {:continue, :connect}}
      end

      @impl true
      def handle_continue(:connect, %{opts: opts} = state) do
        uri = Keyword.get(opts, :uri)
        headers = Keyword.get(opts, :headers, [])
        http_opts = Keyword.get(opts, :http_opts, [protocols: [:http1], transport_opts: [verify: :verify_none]])

        Logger.debug(fn -> "Connecting to #{uri}" end)
        case Wind.connect(uri, headers, http_opts) do
          {:ok, conn, ref} ->
            Logger.debug(fn -> "Connected" end)
            {:noreply, %{state | conn_info: {conn, ref, nil}}}

          {:error, reason} ->
            {:stop, {:error, reason}, state}

          {:error, conn, reason} ->
            {:stop, {:error, conn, reason}, state}
        end
      end

      defp start_ping_timer() do
        Process.send_after(self(), :ping_timer, 30_000)
      end

      defp maybe_handle_reply({:noreply, state}), do: {:noreply, state}

      defp maybe_handle_reply({:reply, message, %{conn_info: {conn, ref, websocket}} = state}) do
        {:ok, conn, websocket} = Wind.send(conn, ref, websocket, message)
        {:noreply, %{state | conn_info: {conn, ref, websocket}}}
      end

      @impl true
      def handle_cast({:send, message}, %{conn_info: {conn, ref, websocket}} = state) do
        {:ok, conn, websocket} = Wind.send(conn, ref, websocket, message)
        {:noreply, %{state | conn_info: {conn, ref, websocket}}}
      end

      @impl true
      def handle_info(:ping_timer, %{conn_info: {conn, ref, websocket}} = state) do
        {:ok, conn, websocket} = Wind.send(conn, ref, websocket, {:ping, ""})
        {:noreply, %{state | conn_info: {conn, ref, websocket}}}
      end

      @impl true
      def handle_info({_, _, "HTTP/1.1 101 Switching Protocols" <> _} = http_reply_message, %{conn_info: {conn, ref, _}} = state) do
        Logger.debug(fn -> "Upgrading to websocket" end)
        {:ok, conn, ref, websocket} = Wind.setup(conn, ref, http_reply_message)
        state = %{state | conn_info: {conn, ref, websocket}}

        # TODO: Make conditional with "use" opts
        start_ping_timer()

        state
        |> handle_connect()
        |> maybe_handle_reply()
      end

      @impl true
      def handle_info(message, %{conn_info: {conn, ref, websocket}} = state) do
        {:ok, conn, websocket, data} = Wind.decode(conn, ref, websocket, message)
        state = %{state | conn_info: {conn, ref, websocket}}

        state =
          Enum.reduce(data, state, fn datum, state ->
            {:noreply, state} =
              handle_frame(datum, state)
              |> maybe_handle_reply()

            state
          end)

        {:noreply, state}
      end

      def handle_frame({:ping, _data}, %{conn_info: {conn, ref, websocket}} = state) do
        Logger.debug(fn -> "ping" end)
        {:reply, {:pong, ""}, state}
      end

      def handle_frame({:pong, _data}, state) do
        Logger.debug(fn -> "pong" end)
        # TODO: Check timer diff?
        Process.send_after(self(), :ping_timer, 30_000)

        {:noreply, state}
      end
    end
  end
end

