# Submodule **middleware** Lua API

- [Submodule **middleware** Lua API](#submodule-middleware-lua-api)
  - [Lua API](#lua-api)
    - [render_response()](#render_response)
    - [authorize_request()](#authorize_request)

Submodule `middleware.lua` is a part of GraphQL API module that provide two simple stub triggers that may be used in some simple non Tarantool Cartridge Applications to make module work from the box. In real non Tarantool Cartridge application these stubs must be replaced with any desired logic.

If GraphQL API Tarantool Cartridge Role is used than `cartridge.auth` functions is used by default.

## Lua API

### render_response()

`middleware.render_response(resp)` - trigger function that can be used to inject of filter or modify request response. Triggered after rendering each http response,

where:

- `resp` (`table`) - http response table (for more info see: [response object](https://github.com/tarantool/http#fields-and-functions-of-the-response-object))

returns:

- `resp` (`table`) - http response table (for more info see: [response object](https://github.com/tarantool/http#fields-and-functions-of-the-response-object))

### authorize_request()

`middleware.authorize_request(req)` - trigger function that can be used for custom request processing: logging or requests filtering,

where:

- `req` (`table`) - http request table (for more info see: [request object](https://github.com/tarantool/http#fields-and-functions-of-the-request-object))
  
returns:

- `state` (`boolean`) - true if authorize is successful, false - if not.
  