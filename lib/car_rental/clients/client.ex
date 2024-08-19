defmodule CarRental.Clients.Client do
  @moduledoc """
  A struct representing a client.
  """

  use TypedStruct

  typedstruct enforce: true do
    field(:id, integer())
    field(:name, String.t())
    field(:age, integer())
    field(:email, String.t())
    field(:phone, String.t())
    # Driver's license number
    field(:license_number, String.t())
    # Driver's license expiry date
    field(:license_expiry, Date.t())
    # Residential address
    field(:residential_address, String.t())
    # Credit card information for payment
    field(:credit_card_info, String.t())
    field(:rental_history, list())
  end
end
