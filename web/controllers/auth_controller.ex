defmodule Votio.AuthController do
  use Votio.Web, :controller

  @moduledoc """
  Handles the Überauth integration.
  This controller implements the request and callback phases for all providers.
  The actual creation and lookup of users/authorizations is handled by UserFromAuth
  """

  plug Ueberauth

  alias Votio.UserFromAuth

  def login(conn, _params, current_user, _claims) do
    render conn, "login.html", current_user: current_user, current_auths: auths(current_user)
  end

  def callback(%Plug.Conn{assigns: %{ueberauth_failure: fails}} = conn, _params, current_user, _claims) do
    conn
    |> put_flash(:error, hd(fails.errors).message)
    |> render("login.html", current_user: current_user, current_auths: auths(current_user))
  end

  def callback(%Plug.Conn{assigns: %{ueberauth_auth: auth}} = conn, _params, current_user, _claims) do
    case UserFromAuth.get_or_insert(auth, current_user, Repo) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Signed in as #{user.name}")
        |> Guardian.Plug.sign_in(user, :token, perms: %{default: Guardian.Permissions.max})
        |> api_signin_on_success(user)
      {:error, _reason} ->
        conn
        |> put_flash(:error, "Could not authenticate")
        |> redirect(to: "/")
        # |> render("login.html", current_user: current_user, current_auths: auths(current_user))
    end
  end

  def api_signin_on_success(conn, user) do
    new_conn = Guardian.Plug.api_sign_in(conn, user)
    jwt = Guardian.Plug.current_token(new_conn)
    claims = Guardian.Plug.claims(new_conn)
    case claims do
      {:ok, claim} ->
        exp = Map.get(claim, "exp")
        new_conn
        |> put_resp_header("authorization", "Bearer #{jwt}")
        |> put_resp_header("x-expires", "#{exp}")
        |> redirect(to: "/")
      _ ->
        conn
        |> put_flash(:error, "Could not validate")
        |> redirect(to: "/")
    end
  end

  def logout(conn, _params, current_user, _claims) do
    if current_user do
      conn
      # This clears the whole session.
      # We could use sign_out(:default) to just revoke this token
      # but I prefer to clear out the session. This means that because we
      # use tokens in two locations - :default and :admin - we need to load it (see above)
      |> Guardian.Plug.sign_out
      |> put_flash(:info, "Signed out")
      |> redirect(to: "/")
    else
      conn
      |> put_flash(:info, "Not logged in")
      |> redirect(to: "/")
    end
  end

  defp auths(nil), do: []
  defp auths(%Votio.User{} = user) do
    Ecto.Model.assoc(user, :authorizations)
      |> Repo.all
      |> Enum.map(&(&1.provider))
  end
end
