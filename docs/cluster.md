# Module **cluster** methods

- [Module **cluster** methods](#module-cluster-methods)
  - [get_servers](#get_servers)
  - [get_masters](#get_masters)
  - [get_storages_masters](#get_storages_masters)
  - [get_self_alias](#get_self_alias)

Module `cluster` provide some methods specific to cluster application architecture. This particular implementation was made for Tarantool Cartridge Application, for any custom application architecture all function from this module may be overridden to comply it. 

## get_servers

`get_servers()` - method to get connections to all cluster servers,

returns:

* `servers` (`table`) - array of conn objects to all servers. For more details see: [net_box module](https://www.tarantool.io/en/doc/latest/reference/reference_lua/net_box/#net-box-connect)

* `connect_errors` (`table`) - array of errors if some cluster instances is not available.

## get_masters

`get_masters()` - method to get connections to master instances of all replicasets,

returns:

* `servers` (`table`) - array of conn objects to all servers. For more details see: [net_box module](https://www.tarantool.io/en/doc/latest/reference/reference_lua/net_box/#net-box-connect)

* `connect_errors` (`table`) - array of errors if some master instances is not available.

## get_storages_masters

`get_storages_masters()` - method to get connections to master instances of all storage replicasets,

* `servers` (`table`) - array of conn objects to all servers. For more details see: [net_box module](https://www.tarantool.io/en/doc/latest/reference/reference_lua/net_box/#net-box-connect)

* `connect_errors` (`table`) - array of errors if some master instances is not available.

## get_self_alias

`get_storages_masters()` - method to get instance alias this method called on,

returns:

* `instance_name` (`string`) - name of instance.
