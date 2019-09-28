defmodule ChatopsRPC.ConfigurationError do
  @moduledoc false
  defexception [:message]

  def exception(error) do
    %__MODULE__{message: error}
  end
end
