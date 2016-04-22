defmodule RePG2Test do
  use ExUnit.Case
  doctest RePG2

  @moduletag :capture_log

  setup do
    Application.stop(:repg2)
    :ok = Application.start(:repg2)
  end

  test "initial state" do
    assert RePG2.which_groups() == []
  end

  test "create group" do
    assert RePG2.create(:test_group) == :ok

    assert RePG2.which_groups() == [:test_group]
  end

  test "delete group" do
    RePG2.create(:test_group)

    assert RePG2.delete(:test_group) == :ok

    assert RePG2.which_groups() == []
  end

  test "join group" do
    :ok = RePG2.create(:test_group)

    assert RePG2.join(:test_group, self()) == :ok

    assert RePG2.get_members(:test_group) == [self()]

    assert RePG2.get_local_members(:test_group) == [self()]

    assert RePG2.get_closest_pid(:test_group) == self()
  end

  test "leave group" do
    :ok = RePG2.create(:test_group)

    assert RePG2.join(:test_group, self()) == :ok

    assert RePG2.get_members(:test_group) == [self()]

    assert RePG2.get_local_members(:test_group) == [self()]

    assert RePG2.get_closest_pid(:test_group) == self()

    assert RePG2.leave(:test_group, self()) == :ok

    assert RePG2.get_members(:test_group) == []

    assert RePG2.get_local_members(:test_group) == []

    assert RePG2.get_closest_pid(:test_group) == {:error, {:no_process, :test_group}}
  end
end
