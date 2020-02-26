defmodule ChatopsRPC.ConfigurationError do
  defexception [:message]

  def exception(error) do
    %__MODULE__{message: error}
  end
end
