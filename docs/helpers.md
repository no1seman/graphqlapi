# Submodule **helpers** functions

- [Submodule **helpers** functions](#submodule-helpers-functions)
  - [Lua API](#lua-api)
    - [init()](#init)
    - [stop()](#stop)
    - [update_lists()](#update_lists)
    - [space_info_init()](#space_info_init)
    - [space_info_remove()](#space_info_remove)
    - [space_drop_init()](#space_drop_init)
    - [space_drop_remove()](#space_drop_remove)
    - [space_truncate_init()](#space_truncate_init)
    - [space_truncate_remove()](#space_truncate_remove)
    - [space_update_init()](#space_update_init)
    - [space_update_remove()](#space_update_remove)
    - [space_create_init()](#space_create_init)
    - [space_create_remove()](#space_create_remove)

Module `helpers.lua` is used to flexibly add types, queries and mutations to GraphQL schema for all common operations with spaces and data: info, drop, truncate, create, update.

## Lua API

### init()

`init(opts)` - function is used to add all desired types, queries and mutations to GraphQL schema to make it possible to use these queries and mutations using GraphQL requests.

where:

* `opts` (`table`) - optional, init options for flexible adding types, queries and mutations to GraphQL schema for all common operations with spaces and data: info, drop, truncate, create, update. Here is a full list of possible options:

```lua
local helpers_opts = {
    info = {
        -- indicates whether space_info query will be added or not to GraphQL schema
        enabled = true, 
        -- list of spaces that will be available in space_info query
        include = {'space_to_include_1', ..., 'space_to_include_n'},
        --  list of spaces that will not be available in space_info query, 
        --  even if space was not exists on the moment of calling helpers.init() 
        exclude = {'space_to_exclude_1', ..., 'space_to_exclude_n'},
    },
    drop = { 
        -- indicates whether space_drop mutation will be added or not to GraphQL schema
        enabled = true, 
        -- list of spaces that will be available in space_drop mutation
        include = {'space_to_include_1', ..., 'space_to_include_n'},
        --  list of space names that will not be available in space_drop mutation, 
        --  even if space was not exists on the moment of calling helpers.init() 
        exclude = {'space_to_exclude_1', ..., 'space_to_exclude_n'},
    },
    truncate = {
        -- indicates whether space_truncate mutation will be added or not to GraphQL schema
        enabled = true, 
        -- list of spaces that will be available in space_truncate mutation
        include = {'space_to_include_1', ..., 'space_to_include_n'},
        --  list of space names that will not be available in space_truncate mutation, 
        --  even if space was not exists on the moment of calling helpers.init() 
        exclude = {'space_to_exclude_1', ..., 'space_to_exclude_n'},
    },
    update = { 
        -- indicates whether space_update mutation will be added or not to GraphQL schema
        enabled = true, 
        -- list of spaces that will be available in space_update mutation
        include = {'space_to_include_1', ..., 'space_to_include_n'},
        --  list of space names that will not be available in space_update mutation, 
        --  even if space was not exists on the moment of calling helpers.init() 
        exclude = {'space_to_exclude_1', ..., 'space_to_exclude_n'},
    },
    create = {
        -- indicates whether space_create mutation will be added or not to GraphQL schema
        enabled = true
    },
}

helpers.init(helpers_opts)
```

### stop()

`stop()` - function is used to deinit helpers, remove all types, queries and mutations from GraphQL schema created by functions of this particular module.

### update_lists()

`update_lists()` - function is used to update space lists enums. Generally this function is called by internal purposes when database schema changes to apply these changes to GraphQL schema. It can be called from user routines to force update space lists enums for info, drop, truncate, create, update operations.

### space_info_init()

`space_info_init(include, exclude)` - function is used to add all desired types and space_info query to GraphQL schema to make it possible to request space_info with use of GraphQL requests,

where:

* `include` (`table`) - optional, list of spaces that will be available in space_info query;

* `exclude` (`table`) - optional, list of spaces that will not be available in space_info query, even if space was not exists on the moment of calling `helpers.space_info_init()`.

Example:

```lua
helpers.space_info_init({'space_to_include'}, {'space_to_exclude'})
```

### space_info_remove()

`space_info_remove()` - function is used to remove space_info helpers: all types and queries from GraphQL schema created by `helpers.space_info_init()` or `helpers.init()` functions.

### space_drop_init()

`space_drop_init(include, exclude)` - function is used to add all desired types and space_drop mutation to GraphQL schema to make it possible to request space_drop with use of GraphQL requests,

where:

* `include` (`table`) - optional, list of spaces that will be available in space_drop query;

* `exclude` (`table`) - optional, list of spaces that will not be available in space_drop query, even if space was not exists on the moment of calling `helpers.space_drop_init()`.

Example:

```lua
helpers.space_drop_init({'space_to_include'}, {'space_to_exclude'})
```

### space_drop_remove()

`space_drop_remove()` - function is used to remove space_drop helpers: all types and queries from GraphQL schema created by `helpers.space_drop_init()` or `helpers.init()` functions.

### space_truncate_init()

`space_truncate_init(include, exclude)` - function is used to add all desired types and space_truncate mutation to GraphQL schema to make it possible to request space_truncate with use of GraphQL requests,

where:

* `include` (`table`) - optional, list of spaces that will be available in space_truncate query;

* `exclude` (`table`) - optional, list of spaces that will not be available in space_truncate query, even if space was not exists on the moment of calling `helpers.space_truncate_init()`.

Example:

```lua
helpers.space_truncate_init({'space_to_include'}, {'space_to_exclude'})
```

### space_truncate_remove()

`space_truncate_remove()` - function is used to remove space_truncate helpers: all types and queries from GraphQL schema created by `helpers.space_truncate_init()` or `helpers.init()` functions.

### space_update_init()

`space_update_init(include, exclude)` - function is used to add all desired types and space_update mutation to GraphQL schema to make it possible to request space_update with use of GraphQL requests,

where:

* `include` (`table`) - optional, list of spaces that will be available in space_update query;

* `exclude` (`table`) - optional, list of spaces that will not be available in space_update query, even if space was not exists on the moment of calling `helpers.space_update_init()`.

Example:

```lua
helpers.space_truncate_init({'space_to_include'}, {'space_to_exclude'})
```

### space_update_remove()

`space_update_remove()` - function is used to remove space_update helpers: all types and queries from GraphQL schema created by `helpers.space_update_init()` or `helpers.init()` functions.

### space_create_init()

`space_create_init(include, exclude)` - function is used to add all desired types and space_create mutation to GraphQL schema to make it possible to request space_create with use of GraphQL requests,

where:

* `include` (`table`) - optional, list of spaces that will be available in space_create query;

* `exclude` (`table`) - optional, list of spaces that will not be available in space_create query, even if space was not exists on the moment of calling `helpers.space_create_init()`.

Example:

```lua
helpers.space_create_init({'space_to_include'}, {'space_to_exclude'})
```

### space_create_remove()

`space_create_remove()` - function is used to remove space_create helpers: all types and queries from GraphQL schema created by `helpers.space_create_init()` or `helpers.init()` functions.
