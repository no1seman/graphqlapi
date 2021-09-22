SHELL := /bin/bash

.PHONY: .rocks
.rocks: graphqlapi-0.0.1-1.rockspec Makefile
		tarantoolctl rocks make
		tarantoolctl rocks install luatest 0.5.5
		tarantoolctl rocks install luacov 0.13.0
		tarantoolctl rocks install luacheck 0.26.0
		tarantoolctl rocks install cartridge 2.7.1

.PHONY: lint
lint:
		.rocks/bin/luacheck .

.PHONY: test
test: 	lint
		rm -f tmp/luacov*
		.rocks/bin/luatest --verbose --coverage --shuffle group
		.rocks/bin/luacov . && grep -A999 '^Summary' tmp/luacov.report.out

.PHONY: clean
clean:
		rm -rf .rocks

.PHONY: build
build:	
		tarantoolctl rocks make
		tarantoolctl rocks pack graphqlapi 0.0.1-1	
