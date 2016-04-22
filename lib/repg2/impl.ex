defmodule RePG2.Impl do
  @moduledoc false

  @ets_table RePG2

  def assure_group(name) do
    key = {:group, name}

    unless :ets.member(@ets_table, key),
      do: :ets.insert(@ets_table, {key})
  end

  def join_group(name, pid) do
    ref_pid_key = {:ref, pid}

    try do
      :ets.update_counter(@ets_table, ref_pid_key, {4, +1})
    else
      _ -> :ok
    catch
      _, _ ->
        {ref_pid, ref} = do_monitor(pid)

        :ets.insert(@ets_table, {ref_pid_key, ref_pid, ref, 1})
        :ets.insert(@ets_table, {{:ref, ref}, pid})
    end

    member_name_pid_key = {:member, name, pid}

    try do
      :ets.update_counter(@ets_table, member_name_pid_key, {2, +1})
    else
      _ -> :ok
    catch
      _, _ ->
        :ets.insert(@ets_table, {member_name_pid_key, 1})

        if node(pid) == Node.self(),
          do: :ets.insert(@ets_table, {{:local_member, name, pid}})

        :ets.insert(@ets_table, {{:pid, pid, name}})
    end

    :ok
  end

  def leave_group(name, pid) do
    member_name_pid_key = {:member, name, pid}

    try do
      :ets.update_counter(@ets_table, member_name_pid_key, {2, -1})
    else
      group_counter ->
        if group_counter == 0 do
          :ets.delete(@ets_table, {:pid, pid, name})

          if node(pid) == Node.self(),
            do: :ets.delete(@ets_table, {:local_member, name, pid})

          :ets.delete(@ets_table, member_name_pid_key)
        end

        ref_pid_key = {:ref, pid}

        if :ets.update_counter(@ets_table, ref_pid_key, {4, -1}) == 0 do
          [{^ref_pid_key, ref_pid, ref, 0}] =
            :ets.lookup(@ets_table, ref_pid_key)

          :ets.delete(@ets_table, {:ref, ref})
          :ets.delete(@ets_table, ref_pid_key)

          true = Process.demonitor(ref, [:flush])

          kill_monitor_proc(ref_pid, pid)
        end
    catch
      _, _ -> :ok
    end
  end

  def delete_group(name) do
    for pid <- group_members(name), do: leave_group(name, pid)

    :ets.delete(@ets_table, {:group, name})
  end

  def group_members(name) do
    for [pid, group_counter] <-
          :ets.match(@ets_table, {{:member, name, :"$1"}, :"$2"}),
        _ <- 1..group_counter,
      do: pid
  end

  def store(groups_and_members) do
    for {name, members} <- groups_and_members,
        assure_group(name),
        member <- members -- group_members(name),
      do: join_group(name, member)

    :ok
  end

  def member_died(ref) do
    [{{:ref, ^ref}, pid}] = :ets.lookup(@ets_table, {:ref, ref})

    names = member_groups(pid)

    for name <- names, membership <- memberships_in_group(pid, name),
      do: leave_group(name, membership)

    :ok
  end

  def local_group_members(name) do
    for [pid] <- :ets.match(@ets_table, {{:local_member, name, :"$1"}}),
        membership <- memberships_in_group(pid, name),
      do: membership
  end

  def exchange_all_members(node_name) do
    GenServer.cast(
      worker_for(node_name),
      {:exchange, Node.self(), all_members()}
    )
  end

  def group_exists?(name),
    do: :ets.member(@ets_table, {:group, name})

  def worker_for(node_name),
    do: {__MODULE__, node_name}

  defp all_members() do
    for group <- all_groups(),
      do: {group, group_members(group)}
  end

  def all_groups() do
    for [name] <- :ets.match(@ets_table, {{:group, :"$1"}}),
      do: name
  end

  defp member_groups(pid) do
    for [name] <- :ets.match(@ets_table, {{:pid, pid, :"$1"}}),
      do: name
  end

  defp memberships_in_group(pid, name) do
    case :ets.lookup(@ets_table, {:member, name, pid}) do
      [] ->
        []

      [{{:member, ^name, ^pid}, group_counter}] ->
        List.duplicate(pid, group_counter)
    end
  end

  defp kill_monitor_proc(ref_pid, pid) do
    unless ref_pid == pid, do: Process.exit(ref_pid, :kill)
  end

  defp do_monitor(pid) do
    if node(pid) in Node.list([:visible, :this]) do
      {pid, Process.monitor(pid)}
    else
      spawn_monitor fn ->
        ref = Process.monitor(pid)

        receive do
          {:DOWN, ^ref, :process, ^pid, _info} -> :ok
        end
      end
    end
  end
end
