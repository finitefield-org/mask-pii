defmodule MaskPII do
  @moduledoc """
  A lightweight Elixir library for masking PII such as email addresses and phone numbers.
  """

  @version "0.2.0"

  @doc """
  Returns the current version of the mask-pii Elixir package.
  """
  @spec version() :: String.t()
  def version, do: @version
end
