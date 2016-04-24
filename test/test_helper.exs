exclude =
  if Node.alive? do
    RePG2.NodeManager.set_up_other_node()

    []
  else
    [distributed: true]
  end

ExUnit.start(exclude: exclude)
