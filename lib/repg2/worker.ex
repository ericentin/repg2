defmodule RePG2.Worker do
  @moduledoc false

  use GenServer

  require Logger

  alias RePG2.Impl

  def start_link, do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @doc """
  Make a globally locked multi call to all `RePG2.Worker`s in the cluster.

  This function acquires a cluster-wide lock on the group `name`, ensuring
  that only one node can update the group at a time. Then, a
  `GenServer.multi_call` is made to all `RePG2.Worker`s with the given
  `message`.
  """
  def globally_locked_multi_call(name, message) do
    :global.trans({{__MODULE__, name}, self()}, fn ->
      all_nodes = Node.list([:visible, :this])

      GenServer.multi_call(all_nodes, RePG2.Worker, message)
    end)
  end

  def init([]) do
    nodes = Node.list()

    :ok = :net_kernel.monitor_nodes(true)

    for new_node <- nodes do
      send(worker_for(new_node), {:new_repg2, Node.self()})
      send(self(), {:nodeup, new_node})
    end

    :ok = Impl.init()

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
    _ =
      Logger.warn("""
      The RePG2 server received an unexpected message:
      handle_call(#{inspect(message)}, #{inspect(from)}, #{inspect(state)})
      """)

    {:noreply, state}
  end

  def handle_cast({:exchange, _node, all_memberships}, state) do
    for {name, members} <- all_memberships,
        Impl.assure_group(name),
        member <- members -- Impl.group_members(name),
        do: Impl.join_group(name, member)

    {:noreply, state}
  end

  def handle_cast(_, state), do: {:noreply, state}

  def handle_info({:DOWN, _ref, :process, pid, _info}, state) do
    for name <- Impl.member_groups(pid),
        membership <- Impl.memberships_in_group(pid, name),
        do: Impl.leave_group(name, membership)

    {:noreply, state}
  end

  def handle_info({:nodeup, new_node}, state) do
    exchange_all_memberships(new_node)

    {:noreply, state}
  end

  def handle_info({:new_repg2, new_node}, state) do
    exchange_all_memberships(new_node)

    {:noreply, state}
  end

  def handle_info(_, state), do: {:noreply, state}

  defp exchange_all_memberships(node_name) do
    all_memberships = for group <- Impl.all_groups(), do: {group, Impl.group_members(group)}

    node_name
    |> worker_for()
    |> GenServer.cast({:exchange, Node.self(), all_memberships})
  end

  defp worker_for(node_name), do: {__MODULE__, node_name}
end
