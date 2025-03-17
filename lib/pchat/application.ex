defmodule Pchat.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, name: Pchat.Registry, keys: :duplicate},
      {Pchat.ChatRoom, []},
      {Plug.Cowboy,
       scheme: :http, plug: Pchat.Router, options: [port: 4343, dispatch: dispatch()]}
    ]

    opts = [strategy: :one_for_one, name: Pchat.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def dispatch() do
    [
      {:_,
       [
         {"/ws/chat", Pchat.WebSocketHandler, []},
         {:_, Plug.Cowboy.Handler, {Pchat.Router, []}}
       ]}
    ]
  end
end
