# Submodule **types** methods

- [Submodule **types** methods](#submodule-types-methods)
  - [GraphQL types](#graphql-types)
    - [Field](#field)
    - [scalar()](#scalar)
    - [enum()](#enum)
    - [types.nonNull()](#typesnonnull)
    - [list()](#list)
    - [object()](#object)
    - [inputObject()](#inputobject)
    - [interface()](#interface)
    - [union()](#union)
    - [directive()](#directive)
  - [GraphQL types extensions](#graphql-types-extensions)
    - [double](#double)
    - [mapper](#mapper)
  - [Lua API](#lua-api)
    - [add()](#add)
    - [remove()](#remove)
    - [remove_recursive()](#remove_recursive)
    - [remove_types_by_space_name()](#remove_types_by_space_name)
    - [remove_all()](#remove_all)
    - [add_space_object()](#add_space_object)
    - [add_space_input_object()](#add_space_input_object)
    - [list_types()](#list_types)

Submodule `types.lua` - is a part of GraphQL API module which provides a set of functions to add/remove GraphQL types. It's an extension of [Tarantool GraphQL module type system](https://github.com/tarantool/graphql).

## GraphQL types

GraphQL for Tarantool module provides a base set of GraphQL types to be described in this paragraph. For more detailed information refer to:

[Lua implementation of GraphQL for Tarantool](https://github.com/tarantool/graphql)
[GraphQL specification](https://spec.graphql.org/draft/)

### Field

Many GraphQL types has fields that describes one discrete piece of information available to request within a selection set or represent an input data. Every field may have the following structure:

* `kind` (`table`) - any GraphQL type presents in GraphQL schema,

or

* `field` (`table`) - mandatory, field name key where value has the following parameters:
  * `kind` (`table`) - any GraphQL type presents in GraphQL schema;
  * `description` (`string`) - optional, any arbitrary text that describes field;
  * `deprecationReason` (`string`) - optional, any arbitrary text that describes field deprecation reason;
  * `arguments` (`table`) - optional, list of GraphQL directives;
  * `resolve` (`function`) - optional, resolve function.

Examples:

```lua
    types.add(types.object({
        name = 'Entity',
        description = 'Entity object',
        fields = {
            entity_new = types.string.nonNull,
            entity = {
                kind = types.string.nonNull,
                description = 'Old entity representation',
                deprecationReason = 'Deprecated in favor of entity_new',
                arguments = { types.include },
            }
        }
    }), 'MyEntity')
```

### scalar()

Scalar types represent primitive leaf values in a GraphQL type system. GraphQL responses take the form of a hierarchical tree; the leaves of this tree are typically GraphQL Scalar types (but may also be Enum types or null values).

Default GraphQL scalar types:
- int;
- long;
- float;
- string;
- boolean;
- id.

`types.scalar(opts)` - function is used to create a custom instance of GraphQL scalar type,

where:

* `opts` (`table`) - mandatory, GraphQL scalar type with the following parameters:
  * `name` (`string`) - mandatory, name of created GraphQL scalar type;
  * `description` (`string`) - optional, any arbitrary text that describes created GraphQL scalar type;
  * `serialize` (`function`) - mandatory, function that takes as input string representation of scalar and coerce it to desired lua type;
  * `parseValue` (`function`) - optional, function that takes as input string representation of scalar and coerce it to desired lua type;
  * `parseLiteral` (`function`) - mandatory, function that takes as input a node of GraphQL tree representation, extracts nodes value and returns coerced to desired lua type;  
  * `isValueOfTheType` (`function`) - mandatory, function that takes lua variable and checks it's type. If type is OK it returns true, if not - false.

returns:

`scalar` (`table`) - GraphQL scalar type map, which has the following structure:

```json
    {
        "__type": "Scalar",
        "name": "<scalar_name> (string)",
        "description": "<description> (string)",
        "serialize": "<serialize> (function)",
        "parseValue": "<parseValue> (function)",
        "parseLiteral": "<parseLiteral> (function)",
        "isValueOfTheType": "<isValueOfTheType> (function)",
    }
```

Example:

```lua
    local double = types.scalar({
        name = 'Double',
        serialize = tonumber,
        parseValue = tonumber,
        parseLiteral = function(node)
          -- 'float' and 'int' are names of immediate value types
          if node.kind == 'float' or node.kind == 'int' then
            return tonumber(node.value)
          end
        end,
        isValueOfTheType = function(value)
          return type(value) == 'number'
        end,
    })
```

### enum()

GraphQL Enum types, like Scalar types, also represent leaf values in a GraphQL type system. However Enum types describe the set of possible values.

`types.enum(opts)` - function is used to create a custom GraphQL enum type,

where:

* `opts` (`table`) - mandatory, GraphQL enum type with the following parameters:
  * `name` (`string`) - mandatory, name of created GraphQL enum type;
  * `description` (`string`) - optional, any arbitrary text that describes created GraphQL enum type;
  * `values` (`table`) - mandatory, set of possible values.

returns:

`enum` (`table`) - GraphQL enum type map, which has the following structure:

```json
    {
        "__type": "Enum",
        "name": "<enum_name> (string)",
        "description": "<description> (string)",
        "values": "<values> (table)",
        "serialize": "<serialize> (function)",
    }
```

Example:

```lua
    local index_type = types.enum({
        name = 'SpaceIndexType',
        description = 'Space index type',
        values = {
            tree = 'TREE',
            hash = 'HASH',
            bitset = 'BITSET',
            rtree = 'RTREE',
        }
    })

    types.add(index_type)
```

this will create a new enum:

```graphql
    """Space index type"""
    enum SpaceIndexType {
        tree
        hash
        bitset
        rtree
    }
```

### types.nonNull()

By default, all types in GraphQL are nullable; the null value is a valid response for all Scalars, Objects, Interfacesm Unions and Enums types. To declare a type that disallows null, the GraphQL Non-Null type can be used. This type wraps an underlying type, and this type acts identically to that wrapped type, with the exception that null is not a valid response for the wrapping type.

`nonNull(kind)` - function to wrap any GraphQL type to disallow it's nullability,

where: 

* `kind` (`any`) - mandatory, any type but can't be nil.

returns:

`nonNull` (`table`) - GraphQL nonNull type map, which has the following structure:

```json
    {
        "__type": "NonNull",
        "ofType": "<kind> (table)",
    }
```

Example:

```lua
    types.add(types.object({
        name = 'Entity',
        description = 'Entity object',
        fields = {
            entity = types.nonNull(types.string), -- also can be used shorten symantec: types.string.nonNull
        }
    }), 'MyEntity')
```

this will create an GraphQL object with the following structure:

```graphql
    """Entity object"""
    type entity {
        entity: String!
    }
```

### list()

A GraphQL list is a special collection type which declares the type of each item in the List.

`types.list(kind)` - function to create GraphQL list structure,

where:

* `kind` (`string|table`) - mandatory, GraphQL type.

returns:

`list` (`table`) - GraphQL list type map, which has the following structure:

```json
    {
        "__type": "List",
        "ofType": "<kind> (table)",
    }
```

Example:

```lua
    local entity_list = types.list(types.object({
        name = 'Entity',
        description = 'Entity object',
        fields = {
            entity = types.string.nonNull,
        }
    })
```

### object()

GraphQL Objects represent a list of named fields, each of which yield a value of a specific type.

`types.object(opts)`  - function to create GraphQL object structure,

where:

* `opts` (`table`) - mandatory, GraphQL object type with the following parameters:
  * `name` (`string`) - mandatory, name of created GraphQL object type;
  * `description` (`string`) - optional, any arbitrary text that describes created GraphQL object type;
  * `fields` (`table|function`) - mandatory, single GraphQL type or map of fields where keys are GraphQL types or function that returns GraphQL type map;
  * `interfaces` (`table`) - optional, map of GraphQL interfaces.

returns:

`object` (`table`) - GraphQL object type map, which has the following structure:

```json
    {
        "__type": "Object",
        "name": "<object_name> (string)",
        "description": "<description> (string)",
        "isTypeOf": "<isTypeOf> (function)",
        "fields": "<fields> (table)",
        "interfaces": "<interfaces> (table)",
    }
```

Example:

```lua
    local object = types.object({
        name = 'SpaceField',
        description = 'Space field',
        fields = {
            name = types.string,
            type = types.SpaceFieldType,
            is_nullable = types.boolean,
        }
    })
```

### inputObject()

A GraphQL Input Object defines a set of input fields; the input fields are either scalars, enums, or other input objects.

`types.inputObject(opts)` - function to create GraphQL input object structure,

where:

* `opts` (`table`) - mandatory, GraphQL input object type with the following parameters:
  * `name` (`string`) - mandatory, name of created GraphQL input object type;
  * `description` (`string`) - optional, any arbitrary text that describes created GraphQL input object type;
  * `fields` (`table`) - mandatory, single GraphQL type or map of fields where keys are GraphQL type.

returns:

* `inputObject` (`table`) - GraphQL input object type map, which has the following structure:

```json
    {
        "__type": "InputObject",
        "name": "<input_object_name> (string)",
        "description": "<description> (string)",
        "fields": "<fields> (table)",
    }
```

### interface()

GraphQL interfaces represent a list of named fields and their arguments. GraphQL objects and interfaces can then implement these interfaces which requires that the implementing type will define all fields defined by those interfaces.

`types.interface(opts)` - function to create GraphQL interface structure,

where:

* `opts` (`table`) - mandatory, GraphQL interface type with the following parameters:
  * `name` (`string`) - mandatory, name of created GraphQL interface type;
  * `description` (`string`) - optional, any arbitrary text that describes created GraphQL interface type;
  * `fields` (`table`) - mandatory, single GraphQL type or map of fields where keys are GraphQL type;
  * `resolveType` - optional, resolve function.

returns:

`interface` (`table`) - GraphQL interface type map, which has the following structure:

```json
    {
        "__type": "Interface",
        "name": "<interface_name> (string)",
        "description": "<description> (string)",
        "fields": "<fields> (table)",
        "resolveType": "<resolveType> (function)",
    }
```

### union()

GraphQL Unions represent an object that could be one of a list of GraphQL Object types, but provides for no guaranteed fields between those types.

`types.union(opts)` - function to create GraphQL union structure,

where:

* `opts` (`table`) - mandatory, GraphQL interface type with the following parameters:
  * `name` (`string`) - mandatory, name of created GraphQL interface type;
  * `types` (`table`) - mandatory, list of GraphQL types;

returns:

`interface` (`table`) - GraphQL union type map, which has the following structure:

```json
    {
        "__type": "Union",
        "name": "<union_name> (string)",
        "types": "<types> (table)"
    }
```

### directive()

A GraphQL schema describes directives which are used to annotate various parts of a GraphQL document as an indicator that they should be evaluated differently by a validator, executor.

`directive(opts)` - function to create GraphQL directive structure,

where:

* `opts` (`table`) - mandatory, GraphQL directive type with the following parameters:
  * `name` (`string`) - mandatory, name of created GraphQL directive type;
  * `description` (`string`) - optional, any arbitrary text that describes created GraphQL directive type;
  * `arguments ` (`table`) - optional, list of GraphQL types;
  * `onQuery` (`boolean`) - optional, flag to indicate that directive is applicable to queries;
  * `onMutation` (`boolean`) - optional, flag to indicate that directive is applicable to mutations;
  * `onField` (`boolean`) - optional, flag to indicate that directive is applicable to fields;
  * `onFragmentDefinition` (`boolean`) - optional, flag to indicate that directive is applicable to fragment definitions;
  * `onFragmentSpread` (`boolean`) - optional, flag to indicate that directive is applicable to fragment spreads;
  * `onInlineFragment` (`boolean`) - optional, flag to indicate that directive is applicable to inline fragments.

returns:

`directive` (`table`) - GraphQL directive type map, which has the following structure:

```json
  {
    "__type": "Directive",
    "name": "<directive_name> (string)",
    "description": "<description> (string)",
    "arguments": "<arguments> (table)",
    "onQuery": "<onQuery> (boolean)",
    "onMutation": "<onMutation> (boolean)",
    "onField": "<onField> (boolean)",
    "onFragmentDefinition": "<onFragmentDefinition> (boolean)",
    "onFragmentSpread": "<onFragmentSpread> (boolean)",
    "onInlineFragment": "<onInlineFragment> (boolean)",
  }
```

Example:

```lua
    local exclude = types.directive({
        name = 'exclude',
        description = 'Directs the executor to exclude this field or fragment only when the `if` argument is true.',
        arguments = {
            ['if'] = { kind = types.boolean.nonNull, description = 'Excluded when true.'}
        },
        onField = true,
        onFragmentSpread = true,
        onInlineFragment = true
    })
```

## GraphQL types extensions

Lua used in Tarantool as a main scripting and configuring language have a several types that is not covered by default GrpahQL type system. For these types GraphQL API have some extensions described below.
### double

Double is a custom GraphQL scalar for representing float numbers of double precision.

Example:

```lua
    local object = types.object({
        name = 'entity',
        description = 'Entity object',
        fields = {
            name = types.string,
            double = types.double,
            is_nullable = types.boolean,
        }
    })
```

### mapper

`types.mapper` - static map with predefined lua types mapping to GraphQL types:

```lua
    types.mapper = {
        ['unsigned'] = types.long,
        ['integer'] = types.int,
        ['number'] = types.float,
        ['string'] = types.string,
        ['scalar'] = types.scalar,
        ['boolean'] = types.boolean,
        ['varbinary'] = types.bare,
        ['array'] = types.list,
        ['map'] = types.bare,
        ['any'] = types.scalar,
        ['decimal'] = types.long,
        ['double'] = types.double,
        ['uuid'] = types.id,
    }
```

## Lua API

### add()

`add(type, type_name)` - function to add new GraphQL type or override existing one,

where:

* `type` (`table`) - mandatory, any GraphQL type provided by GraphQL API module including custom user types;
* `type_name` - optional, GraphQL type name alias. If not provided then GraphQL type name will be used as a name of new GraphQL type.

After creating new GraphQL type it will be accessible in all types and operations of GraphQL schema that will be created after.

Example:

```lua
    types.add(types.object({
        name = 'Entity',
        description = 'Entity type',
        fields = {
            entity = types.string,
        }
    }), 'MyEntity')
```

### remove()

`remove(type_name)` - function to remove any GraphQL type from GraphQL schema excluding internal types that can't be removed anyway,

where:

* `type_name` - mandatory, GraphQL type name to be removed.

Example:

```lua
    types.remove('MyEntity')
```

### remove_recursive()

`remove_recursive(type_name)` - function to remove any GraphQL type from GraphQL schema excluding internal types that can't be removed anyway and also remove all types and operations using this type to avoid queries and mutations execution errors,

where:

* `type_name` - mandatory, GraphQL type name to be removed.

Example:

```lua
    types.remove_recursive('MyEntity')
```

### remove_types_by_space_name()

`remove_types_by_space_name(space_name)` - function is used to remove all objects and input objects related to provided space and created by `types.add_space_object()` and `add_space_input_object()`, 

where:

* `space_name` (`string`) - mandatory,  name of the space.

Example:

```lua
    types.remove_types_by_space_name('entity')
```

### remove_all()

`remove_all()` - function to remove all GraphQL schema types excluding internal types that can't be removed anyway.

### add_space_object()

`add_space_object(opts)` - helper function to create GraphQL object type with fieldset based on current space format. Function also allows to flexibly set additional fields or mask any space fields to comply your goals,

where:

* `opts` (`table`) - mandatory, description of GraphQL space object which has the following parameters:
  * `name` (`string`) - mandatory, name of created GraphQL object;
  * `description` (`string`) - optional, any arbitrary text that describes created space object;
  * `space` (`string`) - mandatory, space name created GraphQL space object will be based on;
  * `fields` (`table`) - optional, a map of fields need to be added, overridden or masked in created GraphQL space object.

Example:

If we have the following space:

```lua
    local format = {
        { name = 'bucket_id', type = 'unsigned', is_nullable = false },
        { name = 'entity_id', type = 'string', is_nullable = false },
        { name = 'entity', type = 'string', is_nullable = true },
    }
```

and need to add it to GraphQL schema we can do it:

```lua
    types.add_space_object({
        name = 'entity',
        description = 'Entity object',
        space = 'entity',
    })
```

this will create an GraphQL space object and also register a relation between space and created type with the following structure:

```graphql
    """Entity object"""
    type entity {
        bucket_id: Long!
        entity_id: String!
        entity: String
    }
```

If we want to mask some fields and add some custom fields we can use the following trick:

```lua
    types.add_space_object({
        name = 'entity',
        description = 'Entity object',
        space = 'entity',
        fields = {
            bucket_id = box.NULL,
            entity_id_hash = types.string,
        }
    })
```

this will create an GraphQL space object and also register a relation between space and created type with th following structure:

```graphql
    """Entity object"""
    type entity {
        entity_id: String!
        entity: String,
        entity_id_hash: String,
    }
```

### add_space_input_object()

`add_space_input_object(opts)` - helper function to create GraphQL input object type with fieldset based on current space format. Function also allows to flexibly set additional fields or mask any space fields to comply your goals,

where:

* `opts` (`table`) - mandatory, description of GraphQL space input object which has the following parameters:
  * `name` (`string`) - mandatory, name of created GraphQL input object;
  * `description` (`string`) - optional, any arbitrary text that describes created space input object;
  * `space` (`string`) - mandatory, space name created GraphQL space input object will be based on;
  * `fields` (`table`) - optional, a map of fields need to be added, overridden or masked in created GraphQL space input object.

Example:

If we have the following space:

```lua
    local format = {
        { name = 'bucket_id', type = 'unsigned', is_nullable = false },
        { name = 'entity_id', type = 'string', is_nullable = false },
        { name = 'entity', type = 'string', is_nullable = true },
    }
```

and need to add it to GraphQL schema we can do it:

```lua
    types.add_space_input_object({
        name = 'entity',
        description = 'Entity input object',
        space = 'entity',
    })
```

this will create an GraphQL space input object and also register a relation between space and created type with the following structure:

```graphql
    """Entity input object"""
    input entity {
        bucket_id: Long!
        entity_id: String!
        entity: String
    }
```

### list_types()

`list_types()` - function to get a list of all registered in GraphQL schema types,

returns:

* `types` (`table`) - map with all registered types.
