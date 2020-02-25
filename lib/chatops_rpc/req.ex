defmodule ChatopsRPC.Req do
  def new(user, room_id, method, params) do
    %{}
  end
end

defmodule ChatopsRPC.Resp do
  import Norm

  def s do
    good = schema(%{
      result: spec(is_binary),
      title: spec(is_binary),
      title_link: spec(is_binary), # and is link
      color: spec(is_binary), # and is hex values
      buttons: coll_of(schema(%{
        label: spec(is_binary),
        image_url: spec(is_binary), # and is link
        command: spec(is_binary),
      })),
      image_url: spec(is_binary),
    })

    bad = schema(%{
      error: schema(%{message: spec(is_binary)})
    })

    alt(ok: selection(good, [:result]), error: selection(bad))
  end
end
