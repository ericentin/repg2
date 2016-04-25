[![Build Status](https://travis-ci.org/antipax/repg2.svg?branch=master)](https://travis-ci.org/antipax/repg2) [![Coverage Status](https://coveralls.io/repos/github/antipax/repg2/badge.svg?branch=master)](https://coveralls.io/github/antipax/repg2?branch=master) [![Inline docs](http://inch-ci.org/github/antipax/repg2.svg?branch=master)](http://inch-ci.org/github/antipax/repg2) [![Hex.pm package version](https://img.shields.io/hexpm/v/repg2.svg)](https://hex.pm/packages/repg2) [![Hex.pm package license](https://img.shields.io/hexpm/l/repg2.svg)](https://github.com/antipax/repg2/blob/master/LICENSE)

# RePG2

A highly-documented translation of the original Erlang pg2 implementation to Elixir for educational purposes.

**Do not use RePG2 in production.** Instead, use the pg2 module from the Erlang stdlib.

## Rationale

We all agree that documentation is awesome. However, the true specification of a code's behavior is the code itself. By reading the code of our favorite software, we can gain a deeper understanding. The benefits of this deeper understanding range from exploiting the performance characteristics of a particular implementation to applying its design principles in our own code.

In my opinion, pg2 is one of the coolest tools in the OTP toolbox, and has been used in almost every distributed Elixir application I have ever worked with, including Phoenix. In a nutshell, pg2 allows you to group processes, using a simple API, across all of your nodes. In terms of the CAP theorem, pg2 is AP: available and partition tolerant. Despite the apparent complexity of such a task, it is (perhaps surprisingly) implemented in a single 400-line Erlang module using the same OTP modules available to our own code. The pg2 code is a great way to learn about distributed Erlang, and by extension, distributed Elixir.

That being said, if you are an Elixir developer, you don't necessarily know how to read Erlang. Additionally, despite the high quality of the implementation, pg2's Erlang code is not necessarily easy to read, even if you know Erlang. To aide my own understanding, I decided to attempt to translate the Erlang code into an idiomatic Elixir version, which I named RePG2.

## The Translation

My translation was guided by a few principles:

  * RePG2 code should be idiomatic, easy-to-read, fully (over?) documented Elixir

  * RePG2 should be identical to pg2 in terms of functionality and performance characteristics, even if it has been refactored to increase clarity

  * Code which exists purely for backwards compatibility may be eliminated in the interest of clarity

Tests were also written using ExUnit for full RePG2 code coverage. The existing pg2 tests in Erlang were not used as a basis for these tests. The ExUnit tests contain a distributed suite which interacts with a second node in the pursuit of full test coverage.

## RePG2 vs. pg2

I cannot guarantee that RePG2 is bug-free (or, at least, that it has the same bugs as the Erlang version), and thus I have placed a big warning to **not use RePG2 in production** at the top of this README.

Some (known) ways in which RePG2 is not functionally identical to pg2:

  * RePG2 does not have the same backwards compatibility as pg2, and has only been tested on Erlang/OTP 18.3 and Elixir 1.2.4

  * pg2 is started under the [kernel_safe_sup](https://github.com/erlang/otp/blob/6664eed/lib/kernel/src/kernel.erl#L67), a special OTP kernel supervisor for important services that are considered safe to restart. RePG2 is implemented as a normal OTP application.

  * pg2 will start itself if it is not yet started. RePG2 expects to be added to your :applications in mix.exs and will not start itself.

## How pg2 (and RePG2) Works

pg2 and RePG2 are both tools for managing distributed process groups.

From the [Erlang pg2 docs](http://erlang.org/doc/man/pg2.html):

> This module implements process groups. Each message may be sent to one,
> some, or all members of the group.
>
> A group of processes can be accessed by a common name. For example, if
> there is a group named foobar, there can be a set of processes (which
> can be located on different nodes) which are all members of the group
> foobar.
>
> If a member terminates, it is automatically removed from the group.

One example of pg2 in use is the default PubSub adapter for Phoenix's Channels. At the core of Channels are subscribers joining channels through which they can send and receive messages. Phoenix apps can be deployed on more than one node, but a given subscriber is only connected to one. This means that when a message is sent, all connected nodes have to be notified so that they can then notify all interested, connected, subscribers. In order to fulfill this requirement, all Phoenix nodes have a process join a pg2 group. When a message is sent, pg2 is asked for the members of the Phoenix group, and a message is sent to all of them.

pg2 is implemented using standard OTP modules. RePG2 is implemented using the same modules as pg2, via Elixir APIs whenever possible.

RePG2 is built on top of:

  * GenServer - basic client-server interactions
  * global - global locks
  * net_kernel - node up/down notifications
  * Node - information about node
  * ets - group data storage

`RePG2.Application` contains the entry point for the `:repg2` OTP application. Its only task is to start a `RePG2.Worker` GenServer, which is responsible for all inter-node communication.

The `RePG2` module provides the public interface. It is possible to create, delete, join, and leave groups. You can also get all the groups, get a group's members across the cluster, get all of a group's members on the local node, and find a random member (giving preference to members on the local node).

At the center of RePG2 is an ETS table. The table contains the group names and process memberships, is present on all RePG2 nodes, and is owned by a `RePG2.Worker`. `RePG2.ETS` contains functions that wrap the `ets` module for interaction with the RePG2 ETS table, and `RePG2.Impl` is the implementation of a low-level API on top of `RePG2.ETS`. `RePG2` then uses the `RePG2.Impl` API on top of `RePG2.Workers` to implement the functionality of the public interface.

When group/process information is read, the local node can simply read the data out of the ETS table. This is very fast, and because the ETS table can be accessed from any process, there is no possibility of one "gatekeeper" process becoming a bottleneck.

Updating group/process information is slightly more complicated. First, the calling process requests a lock across the cluster using the `global` module's `trans` function. This lock is scoped such that if another process attempts to modify the same group, the other process will be excluded. Once the lock is acquired, a GenServer call is made to every `RePG2.Worker` in the cluster. The lock isolates each update, ensuring that all connected nodes have the same view of the data.

If a joined process exits or, equivalently, the node a process is on goes down/is disconnected, a monitor which is started for each member PID sends a message to the node's `RePG2.Worker`. This message results in the removal of the affected process from the ETS table.

In the event of a new RePG2 node connecting, a partitioned node returning, or the RePG2 application being restarted, all group membership data is exchanged between the newly joined `RePG2.Worker` and all other `RePG2.Worker`s. When a node receives this exchange data, any memberships from the other node that are not present on the local node are added to the local node's ETS table.

Due to the monitoring of joined processes and the exchange of data when a new `RePG2.Worker` comes up, nodes will effectively have only reachable, up processes in their ETS table.

## Installation

  1. Add repg2 to your list of dependencies in `mix.exs`:

        def deps do
          [{:repg2, "~> 0.0.4"}]
        end

  2. Ensure repg2 is started before your application:

        def application do
          [applications: [:repg2]]
        end

