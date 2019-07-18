defmodule RePG2 do
  @moduledoc """
  The RePG2 interface.

  From the [Erlang pg2 docs](http://erlang.org/doc/man/pg2.html):

  > This module implements process groups. Each message may be sent to one,
  > some, or all members of the group.
  >
  > A group of processes can be accessed by a common name. For example, if
  > there is a group named foobar, there can be a set of processes (which
  > can be located on different nodes) which are all members of the group
  > foobar. There are no special functions for sending a message to the group.
  > Instead, client functions should be written with the functions
  > get_members/1 and get_local_members/1 to find out which processes are
  > members of the group. Then the message can be sent to one or more members
  > of the group.
  >
  > If a member terminates, it is automatically removed from the group.
  """

  alias RePG2.{Impl, Worker}

  @typedoc "A process group name."
  @type name :: term

  @doc """
  Create a process group with given `name`.

  From the [Erlang pg2 docs](http://erlang.org/doc/man/pg2.html):

  > Creates a new, empty process group. The group is globally visible on all
  > nodes. If the group exists, nothing happens.
  """
  @spec create(name) :: :ok
  def create(name) do
    unless Impl.group_exists?(name) do
      Worker.globally_locked_multi_call(name, {:create, name})
    end

    :ok
  end

  @doc """
  Delete the process group with given `name`.

  From the [Erlang pg2 docs](http://erlang.org/doc/man/pg2.html):

  > Deletes a process group.
  """
  @spec delete(name) :: :ok
  def delete(name) do
    Worker.globally_locked_multi_call(name, {:delete, name})

    :ok
  end

  @doc """
  Join `pid` to the process group with given `name`.

  From the [Erlang pg2 docs](http://erlang.org/doc/man/pg2.html):

  > Joins the process Pid to the group Name. A process can join a group several
  > times; it must then leave the group the same number of times.
  """
  @spec join(name, pid) :: :ok | {:error, {:no_such_group, name}}
  def join(name, pid) do
    if Impl.group_exists?(name) do
      Worker.globally_locked_multi_call(name, {:join, name, pid})

      :ok
    else
      {:error, {:no_such_group, name}}
    end
  end

  @doc """
  Make `pid` leave the process group with given `name`.

  From the [Erlang pg2 docs](http://erlang.org/doc/man/pg2.html):

  > Makes the process Pid leave the group Name. If the process is not a member
  > of the group, ok is returned.
  """
  @spec leave(name, pid) :: :ok | {:error, {:no_such_group, name}}
  def leave(name, pid) do
    if Impl.group_exists?(name) do
      Worker.globally_locked_multi_call(name, {:leave, name, pid})

      :ok
    else
      {:error, {:no_such_group, name}}
    end
  end

  @doc """
  Get all members of the process group with given `name`.

  From the [Erlang pg2 docs](http://erlang.org/doc/man/pg2.html):

  > Returns all processes in the group Name. This function should be used from
  > within a client function that accesses the group. It is therefore optimized
  > for speed.
  """
  @spec get_members(name) :: [pid] | {:error, {:no_such_group, name}}
  def get_members(name) do
    if Impl.group_exists?(name) do
      Impl.group_members(name)
    else
      {:error, {:no_such_group, name}}
    end
  end

  @doc """
  Get all members of the process group with given `name` on the local node.

  From the [Erlang pg2 docs](http://erlang.org/doc/man/pg2.html):

  > Returns all processes running on the local node in the group Name. This
  > function should to be used from within a client function that accesses the
  > group. It is therefore optimized for speed.
  """
  @spec get_local_members(name) :: [pid] | {:error, {:no_such_group, name}}
  def get_local_members(name) do
    if Impl.group_exists?(name) do
      Impl.local_group_members(name)
    else
      {:error, {:no_such_group, name}}
    end
  end

  @doc """
  Get a random member of the process group with given `name` on the local node.

  From the [Erlang pg2 docs](http://erlang.org/doc/man/pg2.html):

  > This is a useful dispatch function which can be used from client functions.
  > It returns a process on the local node, if such a process exist. Otherwise,
  > it chooses one randomly.
  """
  @spec get_closest_pid(name) ::
          pid | {:error, {:no_such_group, name} | {:no_process, name}}
  def get_closest_pid(name) do
    case get_local_members(name) do
      [pid] ->
        pid

      [] ->
        case get_members(name) do
          [] ->
            {:error, {:no_process, name}}

          members ->
            Enum.random(members)
        end

      members when is_list(members) ->
        Enum.random(members)

      other ->
        other
    end
  end

  @doc """
  Get a list of all known groups.

  From the [Erlang pg2 docs](http://erlang.org/doc/man/pg2.html):

  > Returns a list of all known groups.
  """
  @spec which_groups() :: [name]
  def which_groups, do: Impl.all_groups()
end
