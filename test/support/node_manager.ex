defmodule RePG2.NodeManager do
  def set_up_other_node() do
    if :net_adm.ping(other_node()) != :pong do
      Task.start_link fn ->
        System.cmd("mix", ["run", "--no-halt", "-e", "Node.start(:b, :shortnames)"], env: %{"MIX_ENV" => "test"})
      end

      System.at_exit fn _status_code ->
        wait_for_other_node_up()
        :rpc.call(other_node, :init, :stop, [])
      end

      wait_for_other_node_up()
    end
  end

  def spawn_proc_on_other_node() do
    Node.spawn(other_node(), __MODULE__, :receive_forever, [])
  end

  def receive_forever do
    receive do
    after
      :infinity -> :ok
    end
  end

  def other_node() do
    "a@" <> hostname = node() |> to_string()

    :"b@#{hostname}"
  end

  def wait_for_other_node_up() do
    case :net_adm.ping(other_node()) do
      :pong ->
        :ok

      :pang ->
        :timer.sleep(1_000)
        wait_for_other_node_up()
    end
  end

  def rpc_call_other_node(module, function, args) do
    :rpc.call(other_node(), module, function, args)
  end

  def reset_repg2() do
    rpc_call_other_node(Application, :stop, [:repg2])
    Application.stop(:repg2)

    :ok = rpc_call_other_node(Application, :start, [:repg2])
    :ok = Application.start(:repg2)
  end

  def reset_other_node() do
    rpc_call_other_node(__MODULE__, :reset_node, [])
  end

  def reset_node() do
    Application.stop(:repg2)
    :ok = Application.start(:repg2)
  end

  def disconnect_other_node() do
    rpc_call_other_node(__MODULE__, :disconnect, [])
  end

  def disconnect() do
    Node.stop()
    :timer.sleep(1_000)
    Node.start(:b, :shortnames)
  end
end
