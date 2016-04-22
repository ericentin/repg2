defmodule RePG2DistributedTest do
  use ExUnit.Case

  @moduletag :capture_log
  @moduletag :distributed

  setup do
    Application.stop(:repg2)
    :ok = Application.start(:repg2)
  end

  test "basic distribution" do
  end
end
