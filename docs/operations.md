# Submodule **operations** methods

- [Submodule **operations** methods](#submodule-operations-methods)
  - [Lua API](#lua-api)
    - [stop()](#stop)
    - [remove_all()](#remove_all)
    - [get_queries()](#get_queries)
    - [get_mutations()](#get_mutations)
    - [add_queries_prefix()](#add_queries_prefix)
    - [remove_query_prefix()](#remove_query_prefix)
    - [add_mutations_prefix()](#add_mutations_prefix)
    - [remove_mutation_prefix()](#remove_mutation_prefix)
    - [add_query()](#add_query)
    - [remove_query()](#remove_query)
    - [list_queries()](#list_queries)
    - [add_mutation()](#add_mutation)
    - [remove_mutation()](#remove_mutation)
    - [list_mutations()](#list_mutations)
    - [add_space_query()](#add_space_query)
    - [add_space_mutation()](#add_space_mutation)
    - [remove_operations_by_space_name](#remove_operations_by_space_name)
    - [on_resolve](#on_resolve)


## Lua API

### stop()

`stop()` - function to deinit `operations` submodule, it removes all queries, mutations and cleanup all internal module variables including trigger function that controls any space format changes. This behavior is needed to make possible hot-reload of all GraphQL API operations.

### remove_all()

`remove_all()` - function to remove all queries, mutations and cleanup all internal module variables. Unlike `stop()` `remove_all()` doesn't remove space trigger function.

### get_queries()

`get_queries()` - function to get all GraphQL API schema registered queries,

returns:

* `queries` (`table`) - map with all registered queries.

### get_mutations()

`get_mutations()` - function to get all GraphQL API schema registered mutations,

returns:

* `mutations` (`table`) - map with all GraphQL API schema registered mutations.

### add_queries_prefix()

`add_queries_prefix(prefix, doc)` - function to add queries prefix,

where:

* `prefix` (`string`) - mandatory, queries prefix name compliant with [#2.1.9 GraphQL specification](http://spec.graphql.org/draft/#sec-Names);


* `doc` (`string`) - any arbitrary text that describes prefixed set of GraphQL queries.

Example:

```lua
    require('graphqlapi.operations').add_queries_prefix('entity', 'entity operations')
```

### remove_query_prefix()

`remove_query_prefix(prefix)` - function to remove queries prefix and all the underlying queries,

* `prefix` (`string`) - mandatory, queries prefix name to be removed.

Example:

```lua
    require('graphqlapi.operations').remove_query_prefix('entity')
```

### add_mutations_prefix()

`add_mutations_prefix(prefix, doc)` - function to add mutations prefix,

where:

* `prefix` (`string`) - mandatory, mutations prefix name according to [#2.1.9 GraphQL specification](http://spec.graphql.org/draft/#sec-Names);


* `doc` (`string`) - any arbitrary text that describes prefixed set of GraphQL mutations.

Example:

```lua
    require('graphqlapi.operations').add_mutations_prefix('entity', 'entity operations')
```

### remove_mutation_prefix()

`add_mutations_prefix(prefix)` - function to remove mutations prefix and all the underlying queries,

* `prefix` (`string`) - mandatory, mutations prefix name to be removed.

Example:

```lua
    require('graphqlapi.operations').remove_query_prefix('entity')
```

### add_query()

`add_query(opts)` - function to add GraphQL query, 

where:

* `opts` (`table`) - mandatory, GraphQL query which has the following parameters:
  * `prefix` (`string`) - optional, queries prefix name compliant with [#2.1.9 GraphQL specification](http://spec.graphql.org/draft/#sec-Names). Queries prefix must be created before using it;
  * `name` (`string`) - mandatory, query name compliant with [#2.1.9 GraphQL specification](http://spec.graphql.org/draft/#sec-Names); 
  * `doc` (`string`) - optional, any arbitrary text that describes query;
  * `args` (`table`) - optional, table of query arguments - list of GraphQL scalars compliant with [#2.6 GraphQL specification](http://spec.graphql.org/draft/#sec-Language.Arguments);
  * `kind` (`table|string`) - mandatory, list of GraphQL scalars compliant with [#2.6 GraphQL specification](http://spec.graphql.org/draft/#sec-Language.Arguments) or string; 
  * `callback` (`string`) - mandatory, path and name of function to be called to execute GraphQL query.

Example:

```lua
  require('operations').add_query({
        prefix = 'entities',
        name = 'entity',
        doc = 'Get entity object',
        args = {
            entity_id = types.string.nonNull,
        },
        kind = types.list(types.entity),
        callback = 'models.entity.entity_get',
    })
```

### remove_query()

`remove_query(name, prefix)` - function is used to remove GraphQL query,

where:

* `name` (`string`) - mandatory, query name;
  
* `prefix` (`string`) - optional, queries prefix name.

Example:

```lua
  require('operations').remove_query('entity', 'entities')
```

### list_queries()

`list_queries()` - function is used to get list of registered queries,

returns: 

* `queries` (`table`) - list of queries. If query has a prefix `list_queries()` returns it in the following format: 'entities.entity'.

### add_mutation()

`add_mutation(opts)` - function to add GraphQL mutation, 

where:

* `opts` (`table`) - mandatory, GraphQL mutation which has the following parameters:
  * `prefix` (`string`) - optional, mutations prefix name compliant with [#2.1.9 GraphQL specification](http://spec.graphql.org/draft/#sec-Names). Mutations prefix must be created before using it;
  * `name` (`string`) - mandatory, mutation name compliant with [#2.1.9 GraphQL specification](http://spec.graphql.org/draft/#sec-Names); 
  * `doc` (`string`) - optional, any arbitrary text that describes mutation;
  * `args` (`table`) - optional, table of mutation arguments - list of GraphQL scalars compliant with [#2.6 GraphQL specification](http://spec.graphql.org/draft/#sec-Language.Arguments);
  * `kind` (`table|string`) - mandatory, list of GraphQL scalars compliant with [#2.6 GraphQL specification](http://spec.graphql.org/draft/#sec-Language.Arguments) or string; 
  * `callback` (`string`) - mandatory, path and name of function to be called to execute GraphQL mutation.

Example:

```lua
  require('operations').add_mutation({
        prefix = 'entities',
        name = 'entity',
        doc = 'Update entity object',
        args = {
            entity_id = types.string.nonNull,
            entity = types.string.nonNull,
        },
        kind = types.list(types.entity),
        callback = 'models.entity.entity_update',
    })
```

### remove_mutation()

`remove_mutation(name, prefix)` - function is used to remove GraphQL mutation,

where:

* `name` (`string`) - mandatory, mutation name;
  
* `prefix` (`string`) - optional, mutations prefix name.

Example:

```lua
  require('operations').remove_mutation('entity', 'entities')
```

### list_mutations()

`list_mutations()` - function is used to get list of registered mutations,

returns: 

* `mutations` (`table`) - list of mutations. If query has a prefix `list_mutations()` returns it in the following format: 'entities.entity'.

### add_space_query()

`add_space_query(opts)` - function to add GraphQL space object type and space query based on provided space format. Query and related space GraphQL type (representation) can be flexibly configured by add_space_query() options,

where:

* `opts` (`table`) - mandatory, GraphQL space query which has the following parameters:
  * `type_name` (`string`) - optional, GraphQL type name related to specified space, if not provided space query related GraphQL type will be named exactly equal to space name;
  * `description` (`string`) - optional, any arbitrary text that describes space GraphQL type;
  * `space` (`string`) - mandatory, name of existing space;
  * `fields` (`string`) - optional, table with list of space GraphQL type. It's possible to add any additional fields to query results that can be returned by callback function, as well as remove any unneeded space fields from query result. For example, if space has `bucket_id` field and request must not return this field then that field may be removed by the following: 
  ```lua
    ...
    fields = { bucket_id = box.NULL }
    ...
  ```
  * `prefix` (`string`) - optional, queries prefix name compliant with [#2.1.9 GraphQL specification](http://spec.graphql.org/draft/#sec-Names). Queries prefix must be created before using it;
  * `name` (`string`) - optional, query name compliant with [#2.1.9 GraphQL specification](http://spec.graphql.org/draft/#sec-Names). if not provided will be named exactly equal to space name; 
  * `doc` (`string`) - optional, any arbitrary text that describes query;
  * `args` (`table`) - optional, table of query arguments - list of GraphQL scalars compliant with [#2.6 GraphQL specification](http://spec.graphql.org/draft/#sec-Language.Arguments);
  * `kind` (`boolean`) - optional, flag to set kind as list of datasets or single dataset; 
  * `callback` (`string`) - mandatory, path and name of function to be called to execute GraphQL query.

Example:

```lua
    local space = box.schema.space.create('entity', { 
        if_not_exists = true,
        format = {
          { name = 'bucket_id', type = 'unsigned', is_nullable = false },
          { name = 'entity_id', type = 'string', is_nullable = false },
          { name = 'entity', type = 'string', is_nullable = true },
        }
    })
    require('operations').add_space_query({
        type_name = 'entity_query_type',
        description = '"entity" query GraphQL type',
        space = 'entity',
        fields = {
            bucket_id = box.NULL
        },
        prefix = 'entities',
        name = 'entity query',
        doc = '"entity" GraphQL query',
        args = {
            entity_id = types.string.nonNull,
        },
        kind = true,
        callback = 'models.entity_get',
    })
```

### add_space_mutation()

`add_space_mutation(opts)` - function to add GraphQL space object type and space mutation based on provided space format. Mutation and related space GraphQL type (representation) can be flexibly configured by add_space_mutation() options,

where:

* `opts` (`table`) - mandatory, GraphQL space mutation which has the following parameters:
  * `type_name` (`string`) - optional, GraphQL type name related to specified space, if not provided space mutation related GraphQL type will be named exactly equal to space name;
  * `description` (`string`) - optional, any arbitrary text that describes space GraphQL type;
  * `space` (`string`) - mandatory, name of existing space;
  * `fields` (`string`) - optional, table with list of space GraphQL type. It's possible to add any additional fields to mutation results that can be returned by callback function, as well as remove any unneeded space fields from mutation result. For example, if space has `bucket_id` field and request must not return this field then that field may be removed by the following: 
  ```lua
    ...
    fields = { bucket_id = box.NULL }
    ...
  ```
  * `prefix` (`string`) - optional, mutations prefix name compliant with [#2.1.9 GraphQL specification](http://spec.graphql.org/draft/#sec-Names). Mutations prefix must be created before using it;
  * `name` (`string`) - optional, mutation name compliant with [#2.1.9 GraphQL specification](http://spec.graphql.org/draft/#sec-Names). if not provided will be named exactly equal to space name; 
  * `doc` (`string`) - optional, any arbitrary text that describes mutation;
  * `args` (`table`) - optional, table of mutation arguments - list of GraphQL scalars compliant with [#2.6 GraphQL specification](http://spec.graphql.org/draft/#sec-Language.Arguments);
  * `kind` (`boolean`) - optional, flag to set kind as list of datasets or single dataset; 
  * `callback` (`string`) - mandatory, path and name of function to be called to execute GraphQL mutation.

Example:

```lua
    local space = box.schema.space.create('entity', { 
        if_not_exists = true,
        format = {
          { name = 'bucket_id', type = 'unsigned', is_nullable = false },
          { name = 'entity_id', type = 'string', is_nullable = false },
          { name = 'entity', type = 'string', is_nullable = true },
        }
    })
    require('operations').add_space_mutation({
        type_name = 'entity_mutation_type',
        description = '"entity" mutation GraphQL type',
        space = 'entity',
        fields = {
            bucket_id = box.NULL
        },
        prefix = 'entities',
        name = 'entity mutation',
        doc = '"entity" GraphQL mutation',
        args = {
            entity_id = types.string.nonNull,
        },
        kind = true,
        callback = 'models.entity_update',
    })
```

### remove_operations_by_space_name


### on_resolve