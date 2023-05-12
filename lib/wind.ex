defmodule Wind do
  @moduledoc """
  A pleasant Elixir websocket client library based on Mint.
  """

  @doc """
  Statelessly connect to a websocket URL.  This is a convenience function
  around Mint that establishes a connection to `uri` and then subsequently
  upgrades the connection.

  ## Examples

      iex> URL.new!("wss://example.com/ws") |> Wind.connect()
      {:ok, conn, ref}

  """
  @spec connect(URI.t(), list, list) ::
          {:ok, Mint.HTTP.t(), Mint.Types.request_ref()}
          | {:error, Mint.Types.error()}
          | {:error, Mint.HTTP.t(), Mint.WebSocket.error()}
  def connect(uri, headers \\ [], opts \\ []) do
    http_scheme =
      case uri.scheme do
        "ws" -> :http
        "wss" -> :https
      end

    ws_scheme =
      case uri.scheme do
        "ws" -> :ws
        "wss" -> :wss
      end

    path =
      case uri.query do
        nil -> uri.path
        query -> uri.path <> "?" <> query
      end

    with {:ok, conn} <- Mint.HTTP.connect(http_scheme, uri.host, uri.port, opts),
         {:ok, conn, ref} <- Mint.WebSocket.upgrade(ws_scheme, conn, path || "/", headers) do
      {:ok, conn, ref}
    end
  end

  @doc """
  Statelessly setup a websocket connection.  This is a convenience function that
  wraps the Mint.WebSocket setup functions for a websocket.

  ## Examples

      iex> Wind.setup(conn, ref, http_reply_message)
      {:ok, conn, ref, websocket}

  """
  @spec setup(Mint.HTTP.t(), Mint.Types.request_ref(), term, list) ::
          {:ok, Mint.HTTP.t(), Mint.Types.request_ref(), Mint.WebSocket.t()}
          | {:error, Mint.HTTP.t(), Mint.Types.error(), [Mint.Types.response()]}
          | :unknown
  def setup(conn, ref, http_reply_message, opts \\ [])
      when not is_nil(conn) and not is_nil(ref) do
    with {:ok, conn, [{:status, ^ref, status}, {:headers, ^ref, resp_headers}, {:done, ^ref}]} <-
           Mint.WebSocket.stream(conn, http_reply_message),
         {:ok, conn, websocket} <- Mint.WebSocket.new(conn, ref, status, resp_headers, opts) do
      {:ok, conn, ref, websocket}
    end
  end

  @doc """
  Synchronously setup a websocket connection.  See `setup/3`.

  ## Examples

      iex> Wind.setup_await(conn, ref)
      {:ok, conn, ref, websocket}

  """
  @spec setup_await(Mint.HTTP.t(), Mint.Types.request_ref()) ::
          {:ok, Mint.HTTP.t(), Mint.Types.request_ref(), Mint.WebSocket.t()}
          | {:error, Mint.HTTP.t(), Mint.Types.error(), [Mint.Types.response()]}
          | :unknown
  def setup_await(conn, ref)
      when not is_nil(conn) and not is_nil(ref) do
    http_reply_message = receive(do: (message -> message))
    setup(conn, ref, http_reply_message)
  end

  @doc """
  Statelessly decode a websocket message.  This is a convenience function that
  wraps Mint.WebSocket `stream/2` and `decode/2` functions.

  ## Examples

      iex> Wind.decode(conn, ref, websocket, message)
      {:ok, conn, websocket, data}

  """
  @spec decode(Mint.HTTP.t(), Mint.Types.request_ref(), Mint.WebSocket.t(), term()) ::
          {:ok, Mint.HTTP.t(), Mint.WebSocket.t(), [Mint.WebSocket.frame() | {:error, term}]}
          | {:error, Mint.WebSocket.t(), any}
  def decode(conn, ref, websocket, message)
      when not is_nil(conn) and not is_nil(ref) and not is_nil(websocket) and not is_nil(message) do
    with {:ok, conn, [{:data, ^ref, data}]} <- Mint.WebSocket.stream(conn, message),
         {:ok, websocket, data} <- Mint.WebSocket.decode(websocket, data) do
      {:ok, conn, websocket, data}
    end
  end

  @doc """
  Statelessly send a websocket message.  This is a convenience function that
  wraps Mint.WebSocket the `encode/2` and `stream_request_body/3` functions.

  ## Examples

      iex> Wind.decode(conn, ref, websocket, message)
      {:ok, conn, websocket}

  """
  @spec send(Mint.HTTP.t(), Mint.Types.request_ref(), Mint.WebSocket.t(), Mint.WebSocket.shorthand_frame() | Mint.WebSocket.frame()) ::
          {:ok, Mint.HTTP.t(), Mint.WebSocket.t()}
          | {:error, Mint.WebSocket.t(), any}
          | {:error, Mint.HTTP.t(), Mint.WebSocket.error()}
  def send(conn, ref, websocket, message)
      when not is_nil(conn) and not is_nil(ref) and not is_nil(websocket) and not is_nil(message) do
    with {:ok, websocket, data} <- Mint.WebSocket.encode(websocket, message),
         {:ok, conn} <- Mint.WebSocket.stream_request_body(conn, ref, data) do
      {:ok, conn, websocket}
    end
  end
end
