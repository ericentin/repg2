defmodule RePG2Test do
  use ExUnit.Case
  doctest RePG2

  @moduletag :capture_log

  setup do
    RePG2.NodeManager.stop_repg2_other_node()

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

  test "get closest pid returns random member" do
    :rand.seed(:exsplus, {0, 0, 0})

    assert RePG2.get_closest_pid(:test_group) == {:error, {:no_such_group, :test_group}}

    :ok = RePG2.create(:test_group)

    other_pid =
      spawn_link(fn ->
        :timer.sleep(:infinity)
      end)

    assert RePG2.join(:test_group, self()) == :ok

    assert RePG2.join(:test_group, other_pid) == :ok

    assert RePG2.get_closest_pid(:test_group) == self()

    assert RePG2.get_closest_pid(:test_group) == other_pid
  end

  test "member dies" do
    :ok = RePG2.create(:test_group)

    other_pid =
      spawn_link(fn ->
        receive do
          :exit -> :ok
        end
      end)

    assert RePG2.join(:test_group, other_pid) == :ok

    assert RePG2.get_closest_pid(:test_group) == other_pid

    send(other_pid, :exit)

    :timer.sleep(500)

    assert RePG2.get_closest_pid(:test_group) == {:error, {:no_process, :test_group}}
  end

  test "worker should log unexpected calls" do
    assert ExUnit.CaptureLog.capture_log(fn ->
             catch_exit(GenServer.call(RePG2.Worker, :unexpected_message))
           end) =~
             "The RePG2 server received an unexpected message:\nhandle_call(:unexpected_message"
  end
end
