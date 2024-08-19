defmodule CarRental.Clients.Params do
  @moduledoc """
  Represents params to save client's trust score.
  """
  use TypedStruct

  typedstruct enforce: true do
    field(:client_id, non_neg_integer())
    field(:score, pos_integer())
  end
end
