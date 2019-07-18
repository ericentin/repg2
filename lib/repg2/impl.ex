defmodule RePG2.Impl do
  @moduledoc false

  alias RePG2.ETS

  def init, do: ETS.new()

  def assure_group(name) do
    key = {:group, name}

    unless ETS.member(key), do: ETS.insert({key})
  end

  def group_exists?(name), do: ETS.member({:group, name})

  def join_group(name, pid) do
    ref_pid_key = {:ref, pid}

    ETS.update_counter(ref_pid_key, {4, +1},
      on_failure: fn _, _ ->
        monitor_ref = Process.monitor(pid)

        ETS.insert({ref_pid_key, monitor_ref, 1})
      end
    )

    member_name_pid_key = {:member, name, pid}

    ETS.update_counter(member_name_pid_key, {2, +1},
      on_failure: fn _, _ ->
        ETS.insert({member_name_pid_key, 1})

        if node(pid) == Node.self(), do: ETS.insert({{:local_member, name, pid}})

        ETS.insert({{:pid, pid, name}})
      end
    )

    :ok
  end

  def leave_group(name, pid) do
    member_name_pid_key = {:member, name, pid}

    ETS.update_counter(member_name_pid_key, {2, -1},
      on_success: fn group_counter ->
        if group_counter == 0 do
          ETS.delete({:pid, pid, name})

          if node(pid) == Node.self(),
            do: ETS.delete({:local_member, name, pid})

          ETS.delete(member_name_pid_key)
        end

        ref_pid_key = {:ref, pid}

        if ETS.update_counter(ref_pid_key, {3, -1}) == 0 do
          [{^ref_pid_key, monitor_ref, 0}] = ETS.lookup(ref_pid_key)

          ETS.delete(ref_pid_key)

          true = Process.demonitor(monitor_ref, [:flush])
        end
      end
    )
  end

  def delete_group(name) do
    for pid <- group_members(name), do: leave_group(name, pid)

    ETS.delete({:group, name})
  end

  def group_members(name) do
    for [pid, group_counter] <- ETS.match({{:member, name, :"$1"}, :"$2"}),
        _ <- 1..group_counter,
        do: pid
  end

  def local_group_members(name) do
    for [pid] <- ETS.match({{:local_member, name, :"$1"}}),
        membership <- memberships_in_group(pid, name),
        do: membership
  end

  def all_groups, do: for([name] <- ETS.match({{:group, :"$1"}}), do: name)

  def member_groups(pid) do
    for [name] <- ETS.match({{:pid, pid, :"$1"}}), do: name
  end

  def memberships_in_group(pid, name) do
    case ETS.lookup({:member, name, pid}) do
      [] ->
        []

      [{{:member, ^name, ^pid}, group_counter}] ->
        List.duplicate(pid, group_counter)
    end
  end
end
