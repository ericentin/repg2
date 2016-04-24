defmodule RePG2DistributedTest do
  use ExUnit.Case

  import RePG2.NodeManager

  @moduletag :capture_log
  @moduletag :distributed

  setup do
    reset_repg2()
  end

  test "nodes share groups" do
    :ok = RePG2.create(:test_group)

    assert RePG2.join(:test_group, self) == :ok

    assert_group_membership(:test_group, self(), true)

    pid = spawn_proc_on_other_node()

    assert rpc_call_other_node(RePG2, :create, [:test_group2]) == :ok

    assert rpc_call_other_node(RePG2, :join, [:test_group2, pid]) == :ok

    assert_group_membership(:test_group2, pid, false)

    assert RePG2.leave(:test_group, self) == :ok

    assert_no_group_member(:test_group)

    assert rpc_call_other_node(RePG2, :leave, [:test_group2, pid]) == :ok

    assert_no_group_member(:test_group2)
  end

  test "exchange1" do
    :ok = RePG2.create(:test_group)

    assert RePG2.join(:test_group, self) == :ok

    assert_group_membership(:test_group, self(), true)

    reset_other_node()

    :timer.sleep(1_000)

    assert_group_membership(:test_group, self(), true)
  end

  test "exchange2" do
    pid = spawn_proc_on_other_node()

    assert rpc_call_other_node(RePG2, :create, [:test_group]) == :ok

    assert rpc_call_other_node(RePG2, :join, [:test_group, pid]) == :ok

    assert_group_membership(:test_group, pid, false)

    Application.stop(:repg2)
    :ok = Application.start(:repg2)

    :timer.sleep(1_000)

    assert_group_membership(:test_group, pid, false)
  end

  test "join pid from disconnected node" do
    :ok = RePG2.create(:test_group)

    pid = spawn_proc_on_other_node()

    disconnect_other_node()

    :timer.sleep(500)

    assert RePG2.join(:test_group, pid) == :ok

    :timer.sleep(500)

    assert_no_group_member(:test_group)
  end

  defp assert_group_membership(name, pid, pid_is_local) do
    assert RePG2.get_members(name) == [pid]

    assert RePG2.get_local_members(name) == if pid_is_local, do: [pid], else: []

    assert RePG2.get_closest_pid(name) == pid

    assert rpc_call_other_node(RePG2, :get_members, [name]) == [pid]

    assert rpc_call_other_node(RePG2, :get_local_members, [name]) == if pid_is_local, do: [], else: [pid]

    assert rpc_call_other_node(RePG2, :get_closest_pid, [name]) == pid
  end

  defp assert_no_group_member(name) do
    assert RePG2.get_members(name) == []

    assert RePG2.get_local_members(name) == []

    assert RePG2.get_closest_pid(name) == {:error, {:no_process, name}}

    assert rpc_call_other_node(RePG2, :get_members, [name]) == []

    assert rpc_call_other_node(RePG2, :get_local_members, [name]) == []

    assert rpc_call_other_node(RePG2, :get_closest_pid, [name]) == {:error, {:no_process, name}}
  end

end
