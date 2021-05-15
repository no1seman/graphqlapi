#!/bin/sh
# Call this script to install test dependencies

set -e

# Test dependencies:
tarantoolctl rocks install luatest scm-1
tarantoolctl rocks install luacov 0.13.0
tarantoolctl rocks install luacheck 0.26.0
tarantoolctl rocks install cartridge 2.6.0
