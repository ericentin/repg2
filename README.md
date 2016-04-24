[![Build Status](https://travis-ci.org/antipax/repg2.svg?branch=master)](https://travis-ci.org/antipax/repg2) [![Coverage Status](https://coveralls.io/repos/github/antipax/repg2/badge.svg?branch=master)](https://coveralls.io/github/antipax/repg2?branch=master)

# RePG2

A translation of the original Erlang pg2 implementation to Elixir for educational purposes.

**Do not use this package in production.** Instead, use the :pg2 module from the Erlang stdlib.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add repg2 to your list of dependencies in `mix.exs`:

        def deps do
          [{:repg2, "~> 0.0.2"}]
        end

  2. Ensure repg2 is started before your application:

        def application do
          [applications: [:repg2]]
        end

