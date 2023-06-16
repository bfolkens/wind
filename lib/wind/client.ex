defmodule Wind.Client do
  @moduledoc """
  `Client` is the basis for creating a connection module in your application.

  ```elixir
    defmodule Example do
      use Wind.Client

      def start_link() do
        uri = URI.new!("http://example.com/ws")
        Wind.Client.start_link(__MODULE__, uri: uri)
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

  @type frame :: Mint.WebSocket.shorthand_frame() | Mint.WebSocket.frame()

  @doc """
  Invoked after a connection is established. Override to setup post-connection state.
  """
  @callback handle_connect(state :: term) ::
              {:reply, frame :: frame(), new_state :: term}
              | {:noreply, new_state :: term}

  @doc """
  Invoked for each received frame.
  """
  @callback handle_frame(frame :: frame(), state :: term) ::
              {:reply, frame :: frame(), new_state :: term}
              | {:noreply, new_state :: term}

  def start_link(module, default, options \\ []) when is_list(default) do
    GenServer.start_link(module, default, options)
  end

  def send(pid, message) do
    GenServer.cast(pid, {:send, message})
  end

  defmacro __using__(opts) do
    quote location: :keep do
      use GenServer
      require Logger

      @behaviour Wind.Client

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

        http_opts =
          Keyword.get(opts, :http_opts,
            protocols: [:http1],
            transport_opts: [verify: :verify_none]
          )

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

      defp maybe_handle_reply({:noreply, state}), do: {:noreply, state}

      defp maybe_handle_reply({:reply, message, state}), do: send_frame(message, state)

      defp send_frame(message, %{conn_info: {conn, ref, websocket}} = state) do
        case Wind.send(conn, ref, websocket, message) do
          {:ok, conn, websocket} ->
            {:noreply, %{state | conn_info: {conn, ref, websocket}}}

          {:error, _conn_or_websocket, reason} ->
            {:stop, %{state | conn_info: {conn, ref, websocket}}, reason}
        end
      end

      unquote do
        if opts[:ping_timer] do
          quote do
            @impl true
            def handle_info(:ping_timer, state), do: send_frame({:ping, ""}, state)

            def handle_frame({:ping, _data}, state) do
              Logger.debug(fn -> "ping" end)
              {:reply, {:pong, ""}, state}
            end

            def handle_frame({:pong, _data}, state) do
              Logger.debug(fn -> "pong" end)
              # TODO: Check timer diff?
              Process.send_after(self(), :ping_timer, unquote(opts[:ping_timer]))

              {:noreply, state}
            end

            defp start_ping_timer() do
              Process.send_after(self(), :ping_timer, unquote(opts[:ping_timer]))
            end
          end
        end
      end

      @impl true
      def handle_cast({:send, message}, state), do: send_frame(message, state)

      defoverridable handle_cast: 2

      @impl true
      def handle_info(
            {_, _, "HTTP/1.1 101 Switching Protocols" <> _} = http_reply_message,
            %{conn_info: {conn, ref, _}} = state
          ) do
        Logger.debug(fn -> "Upgrading to websocket" end)
        {:ok, conn, ref, websocket} = Wind.setup(conn, ref, http_reply_message)
        state = %{state | conn_info: {conn, ref, websocket}}

        unquote do
          if opts[:ping_timer] do
            quote do
              start_ping_timer()
            end
          end
        end

        state
        |> handle_connect()
        |> maybe_handle_reply()
      end

      @impl true
      def handle_info(message, %{conn_info: {conn, ref, websocket}} = state)
          when not is_nil(conn) and not is_nil(ref) and not is_nil(websocket) do
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

      @impl true
      def handle_info(message, state), do: {:stop, {:error, message}, state}

      defoverridable handle_info: 2

      @doc false
      def handle_connect(state), do: {:noreply, state}

      defoverridable handle_connect: 1
    end
  end
end
