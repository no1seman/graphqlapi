# Submodule **cluster** functions

- [Submodule **cluster** functions](#submodule-cluster-functions)
  - [lua API](#lua-api)
    - [get_servers()](#get_servers)
    - [get_masters()](#get_masters)
    - [get_storages_masters()](#get_storages_masters)
    - [get_self_alias()](#get_self_alias)
    - [get_existing_spaces()](#get_existing_spaces)
    - [is_space_exists()](#is_space_exists)
    - [get_schema()](#get_schema)

Submodule `cluster.lua` provide some functions specific to cluster application architecture. This particular implementation was made for Tarantool Cartridge Application (requires: `Cartridge`, `VShard` and `DDL` modules), for any custom application architecture, for example for so called pure-Tarantool applications all function from this module may need to be overridden to comply it.

## lua API
### get_servers()

`get_servers()` - function to get connections to all cluster servers,

returns:

* `servers` (`table`) - array of conn objects to all servers. For more details see: [net_box module](https://www.tarantool.io/en/doc/latest/reference/reference_lua/net_box/#net-box-connect)

* `connect_errors` (`table`) - array of errors if some cluster instances is not available.

### get_masters()

`get_masters()` - function to get connections to master instances of all replicasets,

returns:

* `servers` (`table`) - array of conn objects to all servers. For more details see: [net_box module](https://www.tarantool.io/en/doc/latest/reference/reference_lua/net_box/#net-box-connect)

* `connect_errors` (`table`) - array of errors if some master instances is not available.

### get_storages_masters()

`get_storages_masters()` - function to get connections to master instances of all storage replicasets,

* `servers` (`table`) - array of conn objects to all servers. For more details see: [net_box module](https://www.tarantool.io/en/doc/latest/reference/reference_lua/net_box/#net-box-connect)

* `connect_errors` (`table`) - array of errors if some master instances is not available.

### get_self_alias()

`get_storages_masters()` - function to get instance alias this function called on,

returns:

* `instance_name` (`string`) - name of instance.

### get_existing_spaces()

`get_existing_spaces()` - function to get list of existing spaces on instance,

returns:

* `spaces` (`table`) - array of existing non-system spaces on instance.


### is_space_exists()

`is_space_exists(space)` - function to check if the desired space is exists on instance,

where:

* `space` (`string`) - name of space;

returns:

* `status` (`boolean`) - true if space exists, false - if not.


### get_schema()

`get_schema()` - function to get database schema,

returns:

* `schema` (`table`) - database schema, for additional info see [ddl.get_schema()](https://github.com/tarantool/ddl#get-spaces-format).
