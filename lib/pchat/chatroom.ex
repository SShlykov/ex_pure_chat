defmodule Pchat.ChatRoom do
  use GenServer
  require Logger

  # Client
  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def join(pid, username), do: GenServer.cast(__MODULE__, {:join, pid, username})
  def leave(pid), do: GenServer.cast(__MODULE__, {:leave, pid})

  def send_message(username, message),
    do: GenServer.cast(__MODULE__, {:send_message, username, message})

  def get_users(), do: GenServer.call(__MODULE__, :get_users)
  def get_messages(), do: GenServer.call(__MODULE__, :get_messages)

  # Callbacks
  @impl true
  def init(_), do: {:ok, %{users: %{}, messages: []}}

  @impl true
  def handle_cast({:join, pid, username}, state) do
    Logger.info("пользователь присоединился: #{username}")

    Process.monitor(pid)

    users = Map.put(state.users, pid, username)

    broadcast_system("пользователь присоединился: #{username}")

    {:noreply, %{state | users: users}}
  end

  @impl true
  def handle_cast({:leave, pid}, state) do
    case Map.get(state.users, pid) do
      nil ->
        {:noreply, state}

      username ->
        Logger.info("пользователь покинул комнату; #{username}")

        users = Map.delete(state.users, pid)

        broadcast_system("пользователь покинул комнату: #{username}")

        {:noreply, %{state | users: users}}
    end
  end

  @impl true
  def handle_cast({:send_message, username, message}, state) do
    message = %{
      id: System.system_time(:millisecond),
      username: username,
      content: message,
      timestamp: DateTime.utc_now() |> DateTime.to_string()
    }

    Logger.info(
      "пользователь написал сообщение: user - #{username}; message - #{inspect(message)}"
    )

    messages = [message | state.messages] |> Enum.take(100)

    broadcast(message)

    {:noreply, %{state | messages: messages}}
  end

  @impl true
  def handle_call(:get_users, _from, state) do
    users =
      state.users
      |> Map.values()
      |> Enum.sort()

    {:reply, users, state}
  end

  @impl true
  def handle_call(:get_messages, _from, state) do
    users =
      state.messages
      |> Enum.reverse()

    {:reply, users, state}
  end

  @impl true
  def handle_info({:DOWN, _red, :process, pid, _reason}, state) do
    handle_cast({:leave, pid}, state)
  end

  defp broadcast_system(content) do
    message = %{
      id: System.system_time(:millisecond),
      username: "Система",
      content: content,
      timestamp: DateTime.utc_now() |> DateTime.to_string()
    }

    broadcast(message)
  end

  defp broadcast(message) when is_map(message) do
    message
    |> Jason.encode!()
    |> broadcast()
  end

  defp broadcast(message) do
    Registry.dispatch(Pchat.Registry, "chat", fn entries ->
      for {pid, _} <- entries do
        send(pid, {:broadcast, message})
      end
    end)
  end
end
