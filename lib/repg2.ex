defmodule RePG2 do

  @ets_table __MODULE__

  alias RePG2.Impl

  def create(name) do
    unless Impl.group_exists?(name) do
      global_atomic_multi_call(name, {:create, name})
    end

    :ok
  end

  def delete(name) do
    global_atomic_multi_call(name, {:delete, name})

    :ok
  end

  def join(name, pid) do
    if Impl.group_exists?(name) do
      global_atomic_multi_call(name, {:join, name, pid})

      :ok
    else
      {:error, {:no_such_group, name}}
    end
  end

  def leave(name, pid) do
    if Impl.group_exists?(name) do
      global_atomic_multi_call(name, {:leave, name, pid})

      :ok
    else
      {:error, {:no_such_group, name}}
    end
  end

  def get_members(name) do
    if Impl.group_exists?(name) do
      Impl.group_members(name)
    else
      {:error, {:no_such_group, name}}
    end
  end

  def get_local_members(name) do
    if Impl.group_exists?(name) do
      Impl.local_group_members(name)
    else
      {:error, {:no_such_group, name}}
    end
  end

  def get_closest_pid(name) do
    case get_local_members(name) do
      [pid] ->
        pid

      [] ->
        case get_members(name) do
          [] -> {:error, {:no_process, name}}
          members -> Enum.random(members)
        end

      members when is_list members ->
        Enum.random(members)

      other ->
        other
    end
  end

  def which_groups(),
    do: Impl.all_groups()

  defp global_atomic_multi_call(name, message) do
    :global.trans {{__MODULE__, name}, self()}, fn ->
      GenServer.multi_call(Node.list([:visible, :this]), RePG2.Worker, message)
    end
  end
end
