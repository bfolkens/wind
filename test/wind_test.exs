defmodule WindTest do
  use ExUnit.Case, async: true

  @moduletag :requires_internet_connection

  describe "with a sample host" do
    setup [:sample_uri]

    test "connect/1 should not connect to an invalid host" do
      assert {:error, _reason} = URI.new!("ws://bad-host/") |> Wind.connect()
    end

    test "connect/1 should connect", %{uri: uri} do
      assert {:ok, _conn, _ref} = Wind.connect(uri)
    end
  end

  describe "with an active connection" do
    setup [:sample_uri, :connect]

    test "setup_await/2 should upgrade the websocket connection", %{conn: conn, ref: ref} do
      assert {:ok, _conn, _ref, _websocket, _response} = Wind.setup_await(conn, ref)
    end
  end

  describe "with an active websocket" do
    setup [:sample_uri, :connect, :upgrade]

    test "send/4 should send a message", %{conn: conn, ref: ref, websocket: websocket} do
      assert {:ok, _conn, _websocket} = Wind.send(conn, ref, websocket, {:text, "test"})
    end
  end

  defp sample_uri(_) do
    host = System.get_env("ECHO_URL") || "ws://localhost/"
    uri = URI.new!(host)

    %{host: host, uri: uri}
  end

  defp connect(%{uri: uri}) do
    {:ok, conn, ref} = Wind.connect(uri)

    %{conn: conn, ref: ref}
  end

  defp upgrade(%{conn: conn, ref: ref}) do
    {:ok, conn, ref, websocket, _response} = Wind.setup_await(conn, ref)

    %{conn: conn, ref: ref, websocket: websocket}
  end
end
