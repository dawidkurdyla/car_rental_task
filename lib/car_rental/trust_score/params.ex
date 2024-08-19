defmodule CarRental.TrustScore.Params do
  @moduledoc """
  A struct representing a trust score params.
  """

  use TypedStruct

  typedstruct enforce: true do
    field(:clients, list(ClientParams.t()))
  end

  typedstruct enforce: true, module: ClientParams do
    field(:client_id, non_neg_integer())
    field(:age, non_neg_integer())
    # Driver's license number
    field(:license_number, String.t())
    # The number of rentals the client has made
    field(:rentals_count, non_neg_integer())
  end
end
