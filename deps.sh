#!/bin/sh
# Call this script to install test dependencies

set -e

# Test dependencies:
tarantoolctl rocks install luatest 0.5.2
tarantoolctl rocks install luacov 0.15.0
tarantoolctl rocks install luacheck 0.26.0