defmodule Pchat.WebSocketHandler do
  @behaviour :cowboy_websocket

  require Logger

  @impl true
  def init(req, state) do
    {:cowboy_websocket, req, state}
  end

  @impl true
  def websocket_init(state) do
    Registry.register(Pchat.Registry, "chat", {})

    {:ok, state}
  end

  @impl true
  def websocket_info({:broadcast, text}, state) do
    {:reply, {:text, text}, state}
  end

  @impl true
  def websocket_handle({:text, json}, state) do
    {:ok, data} = Jason.decode(json)

    case handle_message(data, state) do
      {:error, message} ->
        {:reply, message, state}

      {:reply, res, state} ->
        {:reply, res, state}

      {:noreply, _} ->
        {:ok, state}
    end
  rescue
    _ -> {:reply, "Нечитаемое сообщение", state}
  end

  @impl true
  def terminate(_reason, _req, _) do
    Pchat.ChatRoom.leave(self())
    :ok
  end

  defp handle_message(%{"type" => "join", "username" => username}, state) do
    Pchat.ChatRoom.join(self(), username)

    messages = Pchat.ChatRoom.get_messages()
    users = Pchat.ChatRoom.get_users()

    responce = %{
      type: "init",
      messages: messages,
      users: users
    }

    {:reply, Jason.encode!(responce), Map.put(state, :username, username)}
  end

  defp handle_message(%{"type" => "message", "content" => content}, state) do
    case Map.get(state, :username) do
      nil ->
        {:reply, {:text, Jason.encode!(%{error: "сначала присоединись к каналу"})}}

      username ->
        Pchat.ChatRoom.send_message(username, content)

        {:noreply, :ok}
    end
  end

  defp handle_message(_, _) do
    {:error, "Неизвестный формат сообщения"}
  end
end
