defmodule WindTest do
  use ExUnit.Case, async: true

  @moduletag :requires_internet_connection

  test "connect/1 should connect" do
    uri = URI.new!("wss://socketsbay.com/wss/v2/1/demo/")
    assert {:ok, _conn, _ref} = Wind.connect(uri)
  end

  describe "with an active connection" do
    setup [:connect]

    test "setup_await/2 should upgrade the websocket connection", %{conn: conn, ref: ref} do
      assert {:ok, _conn, _ref, _websocket} = Wind.setup_await(conn, ref)
    end
  end

  describe "with an active websocket" do
    setup [:connect, :upgrade]

    test "send/4 should send a message", %{conn: conn, ref: ref, websocket: websocket} do
      assert {:ok, _conn, _websocket} = Wind.send(conn, ref, websocket, {:text, "test"})
    end
  end

  defp connect(_) do
    uri = URI.new!("wss://socketsbay.com/wss/v2/1/demo/")
    {:ok, conn, ref} = Wind.connect(uri)

    %{conn: conn, ref: ref}
  end

  defp upgrade(%{conn: conn, ref: ref}) do
    {:ok, conn, ref, websocket} = Wind.setup_await(conn, ref)

    %{conn: conn, ref: ref, websocket: websocket}
  end
end
