defmodule CarRental.TrustScore.Response do
  @moduledoc """
    Represents TrustScore response.
  """
  use TypedStruct

  typedstruct enforce: true do
    field(:id, Ecto.UUID.t())
    field(:score, pos_integer())
   end
end
