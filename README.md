# Tarantool GraphQL API module

- [Tarantool GraphQL API module](#tarantool-graphql-api-module)
  - [General description](#general-description)
  - [Install pre-built rock](#install-pre-built-rock)
  - [Lua API](#lua-api)

## General description

Module based on:

- [Tarantool 1.10.x or 2.x.x](https://www.tarantool.io/en/download/)
- [Tarantool Cartridge 2.3.0+](https://github.com/tarantool/cartridge) (optional)
- [Tarantool Graphql 0.1.1+](https://github.com/tarantool/graphql)
- [Tarantool DDL 1.2.0+](https://github.com/tarantool/ddl)
- [Tarantool VShard 0.1.15](https://github.com/tarantool/vshard)
- [Tarantool Checks 1.1.0+](https://github.com/tarantool/checks)
- [Tarantool Errors 2.1.3+](https://github.com/tarantool/errors)

## Install pre-built rock

Simply run from the root of Tarantool App root the following:

```sh
    cd <tarantool-application-dir>
    tarantoolctl rocks install https://github.com/no1seman/graphqlapi/releases/download/0.0.1/graphqlapi-0.0.1-1.all.rock
```
## Lua API

This module has a several submodules:

- [graphqlapi](./docs/graphqlapi.md)
- [graphqlapi.cluster](./docs/cluster.md)
- [graphqlapi.helpers](./docs/helpers.md)
- [graphqlapi.middleware](./docs/middleware.md)
- [graphqlapi.models](./docs/models.md)
- [graphqlapi.operations](./docs/operations.md)
- [graphqlapi.spaceapi](./docs/spaceapi.md)
- [graphqlapi.types](./docs/types.md)
