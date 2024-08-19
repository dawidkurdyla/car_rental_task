defmodule CarRental.Clients do
  @moduledoc """
  Mock clients DB
  """
  @clients_count 2000

  alias CarRental.Clients.Client
  alias CarRental.Clients.Params

  @spec list_clients() :: {:ok, [Client.t()]}
  def list_clients do
    clients = for _ <- 1..@clients_count, do: generate_client()

    {:ok, clients}
  end

  @spec save_score_for_client(Params.t()) :: {:ok, atom()}
  def save_score_for_client(%Params{}) do
    {:ok, :saved}
  end

  defp generate_client do
    %Client{
      id: :crypto.strong_rand_bytes(4) |> :binary.decode_unsigned(),
      name: Faker.Person.name(),
      email: Faker.Internet.email(),
      phone: Faker.Phone.EnUs.phone(),
      age: Enum.random(20..70),
      license_number: Faker.Code.isbn10(),
      license_expiry: Faker.Date.forward(365 * 5) |> Date.to_string(),
      residential_address: Faker.Address.street_address(),
      credit_card_info: Faker.Code.isbn13(),
      rental_history: generate_rental_history()
    }
  end

  defp generate_rental_history do
    for _ <- 1..Enum.random(1..5) do
      %{
        car_id: :crypto.strong_rand_bytes(4) |> :binary.decode_unsigned(),
        rental_date: Faker.Date.backward(365) |> Date.to_string(),
        return_date: Faker.Date.forward(365) |> Date.to_string()
      }
    end
  end
end
