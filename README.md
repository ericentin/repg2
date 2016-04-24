[![Build Status](https://travis-ci.org/antipax/repg2.svg?branch=master)](https://travis-ci.org/antipax/repg2) [![Coverage Status](https://coveralls.io/repos/github/antipax/repg2/badge.svg?branch=master)](https://coveralls.io/github/antipax/repg2?branch=master) [![Inline docs](http://inch-ci.org/github/antipax/repg2.svg?branch=master)](http://inch-ci.org/github/antipax/repg2) [![Hex.pm package version](https://img.shields.io/hexpm/v/repg2.svg)](https://hex.pm/packages/repg2) [![Hex.pm package license](https://img.shields.io/hexpm/l/repg2.svg)](https://github.com/antipax/repg2/blob/master/LICENSE)

# RePG2

A translation of the original Erlang pg2 implementation to Elixir for educational purposes.

**Do not use this package in production.** Instead, use the :pg2 module from the Erlang stdlib.

## Installation

  1. Add repg2 to your list of dependencies in `mix.exs`:

        def deps do
          [{:repg2, "~> 0.0.3"}]
        end

  2. Ensure repg2 is started before your application:

        def application do
          [applications: [:repg2]]
        end

