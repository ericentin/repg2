defmodule RePG2.ETS do
  @moduledoc false

  @ets_table __MODULE__

  def new do
    @ets_table = :ets.new(@ets_table, [:ordered_set, :protected, :named_table])

    :ok
  end

  def member(key), do: :ets.member(@ets_table, key)

  def insert(object), do: :ets.insert(@ets_table, object)

  def delete(key), do: :ets.delete(@ets_table, key)

  def lookup(key), do: :ets.lookup(@ets_table, key)

  def match(match_spec), do: :ets.match(@ets_table, match_spec)

  def update_counter(key, update_op, callbacks \\ []) do
    on_success = Keyword.get(callbacks, :on_success, &default_on_success/1)
    on_failure = Keyword.get(callbacks, :on_failure, &default_on_failure/2)

    try do
      :ets.update_counter(@ets_table, key, update_op)
    else
      result -> on_success.(result)
    catch
      kind, payload -> on_failure.(kind, payload)
    end
  end

  defp default_on_success(result), do: result

  defp default_on_failure(kind, payload), do: {:error, {kind, payload}}
end
