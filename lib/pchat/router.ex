defmodule Pchat.Router do
  use Plug.Router

  require Logger

  plug(Plug.Logger)
  plug(Plug.Static, at: "/", from: :pchat, only: ["css", "js"])
  plug(:match)
  plug(:dispatch)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)

  get "/" do
    Logger.info("123")

    conn
    |> put_resp_content_type("text/html")
    |> send_file(200, "priv/static/index.html")
  end

  get "/api/messages" do
    messages = Pchat.ChatRoom.get_messages()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(messages))
  end

  get "/api/users" do
    users = Pchat.ChatRoom.get_users()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(users))
  end

  match _ do
    send_resp(conn, 404, "Страница не найдена")
  end
end
