# Module **graphqlapi** methods

- [Module **graphqlapi** methods](#module-graphqlapi-methods)
  - [init](#init)
  - [stop](#stop)
  - [reload](#reload)
  - [set models dir](#set-models-dir)
  - [get models dir](#get-models-dir)
  - [set endpoint](#set-endpoint)
  - [get endpoint](#get-endpoint)
  - [VERSION](#version)


`graphqlapi.lua` - is a common module which provides general methods to init/stop/reload module and also for setting/getting http-endpoint and for setting/getting GraphQLAPI models dir path.

It can be loadded by the following code:

```lua
    local graphqlapi = require('graphqlapi')
```

If module runs in Tarantool Cartridge Application Role you can also use the following syntax:

```lua
    local cartridge = require('cartridge')
    local graphqlapi = cartridge.service_get('cartridge')
```

## init

`init(httpd, middleware, endpoint, models_dir, opts)` - used to initialize GraphQLAPI module,

where:

* `httpd` (`table`) - mandatory, instance of a Tarantool HTTP server;

* `middleware` (`table`) - optional, instance of set of middleware callbacks;

* `endpoint` (`string`) - optional, URI of http endpoint to be used for interacting with GraphQLAPI module, default value: `http(s)://<server:port>/admin/graphql`;

* `models_dir` (`string`)  - optional, path to dir with customer GraphQL models, default value: `<app_root>/models`;

* `opts` (`table`) - optional, options of http-route, options are the same as http:route [HTTP routes](https://github.com/tarantool/http/tree/1.1.0#using-routes)

Example:

```lua
    local http = require('http.server')
    local graphqlapi = require('graphqlapi')

    local HOST = '0.0.0.0'
    local PORT = 8081
    local ENDPOINT = '/graphql'

    box.cfg({work_dir = './tmp'})

    local httpd = http.new(HOST, PORT,{ log_requests = false })

    httpd:start()
    graphqlapi.init(httpd, nil, ENDPOINT, '../example/models')
```

## stop

`stop()` - used to deinit GraphQL API module, remove all used variables, cleanup cache and destroy http-endpoint.

## reload

`reload()` - used to reload all models from disk. Usually used to load new models, that must be places to the same models_dir.

## set models dir

`set_models_dir(models_dir)` - method is used to get GraphQL API models dir path, 

where:

* `models_dir` (`string`) - path to GraphQL API models. Base path - is the path to root dir of the application.

Example:

```lua
    local graphqlapi = require('graphqlapi')
    graphqlapi.set_models_dir('models')
```

## get models dir

`get_models_dir()` - method is used to get GraphQL API models dir path, 

Returns `models_dir` (`string`) - path to GraphQL API models.

Example:

```lua
    local graphqlapi = require('graphqlapi')
    local log = require('log')
    local models_dir = graphqlapi.get_models_dir()
    log.info('GraphQL API models dir path: %s', models_dir)
```

## set endpoint

`set_endpoint(endpoint)` - method is used to set endpoint in runtime.

where:

* `endpoint` (`string`) - URI-endpoint of GraphQL API. Parameter is mandatory.

Example:

```lua
    local graphqlapi = require('graphqlapi')
    local endpoint = '/admin/graphql'
    graphqlapi.set_endpoint(endpoint)
```

## get endpoint

`get_endpoint()` - method is used to get endpoint.

Returns:

* `endpoint` (`string`).

Example:

```lua
    local graphqlapi = require('graphqlapi')
    local log = require('log')
    local graphqlapi_endpoint = graphqlapi.get_endpoint()
    log.info('GraphQL API endpoint: %s', graphqlapi_endpoint)
```

## VERSION

GraphQLAPI module and Tarantool Cartridge role has `VERSION` constant to determine which version is installed.

Example:

```lua
    local graphqlapi = require('graphqlapi')
    local log = require('log')
    log.info('GraphQL API version: %s', graphqlapi.VERSION)
```
