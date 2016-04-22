defmodule RePG2.Worker do
  @moduledoc false

  use GenServer

  require Logger

  alias RePG2.Impl

  @ets_table RePG2


  def start_link(),
    do: GenServer.start_link(__MODULE__, [], name: __MODULE__)


  def init([]) do
    nodes = Node.list()

    :ok = :net_kernel.monitor_nodes(true)

    for node <- nodes do
      send Impl.worker_for(node), {:new_repg2, Node.self()}
      send self(), {:nodeup, node}
    end

    :ets.new(@ets_table, [:ordered_set, :protected, :named_table])

    {:ok, %{}}
  end


  def handle_call({:create, name}, _from, state) do
    Impl.assure_group(name)

    {:reply, :ok, state}
  end

  def handle_call({:join, name, pid}, _from, state) do
    if Impl.group_exists?(name), do: Impl.join_group(name, pid)

    {:reply, :ok, state}
  end

  def handle_call({:leave, name, pid}, _from, state) do
    if Impl.group_exists?(name), do: Impl.leave_group(name, pid)

    {:reply, :ok, state}
  end

  def handle_call({:delete, name}, _from, state) do
    Impl.delete_group(name)

    {:reply, :ok, state}
  end

  def handle_call(message, from, state) do
    Logger.warn(
      "The RePG2 server received an unexpected message:\n" <>
      "handle_call(#{inspect message}, #{inspect from}, #{inspect state})")

    {:noreply, state}
  end


  def handle_cast({:exchange, _node, groups_and_members}, state) do
    Impl.store(groups_and_members)

    {:noreply, state}
  end

  def handle_cast(_, state) do
    {:noreply, state}
  end


  def handle_info({:DOWN, ref, :process, _pid, _info}, state) do
    Impl.member_died(ref)

    {:noreply, state}
  end

  def handle_info({:nodeup, node}, state) do
    Impl.exchange_all_members(node)

    {:noreply, state}
  end

  def handle_info({:new_repg2, node}, state) do
    Impl.exchange_all_members(node)

    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end
end
