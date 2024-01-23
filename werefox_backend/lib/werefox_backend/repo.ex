defmodule WerefoxBackend.Repo do
  use Ecto.Repo,
    otp_app: :werefox_backend,
    adapter: Ecto.Adapters.Postgres
end
