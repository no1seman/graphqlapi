package = 'graphqlapi'
version = '0.0.1-1'
source  = {
    url = 'git+https://github.com/no1seman/graphqlapi.git',
    branch = 'master',
}
description = {
    summary     = "GraphQL API backend module for Tarantool and Tarantool Cartridge",
    homepage    = 'https://github.com/no1seman/graphqlapi',
    license     = 'BSD',
    maintainer  = "Yaroslav Shumakov <noiseman2000@mail.ru>";
}
dependencies = {
    'lua >= 5.1',
    'ddl ~> 1.4',
    'http == 1.1.0-1',
    'checks ~> 3.1',
    'errors ~> 2.1',
    'graphql ~> 0.1',
    'vshard ~> 0.1',
}
build = {
    type = 'builtin',
    modules = {
        ['graphqlapi'] = 'graphqlapi.lua',
        ['graphqlapi.cluster'] = 'graphqlapi/cluster.lua',
        ['graphqlapi.defaults'] = 'graphqlapi/defaults.lua',
        ['graphqlapi.funcall'] = 'graphqlapi/funcall.lua',
        ['graphqlapi.helpers'] = 'graphqlapi/helpers.lua',
        ['graphqlapi.helpers.data'] = 'graphqlapi/helpers/data.lua',
        ['graphqlapi.helpers.schema'] = 'graphqlapi/helpers/schema.lua',
        ['graphqlapi.helpers.spaceapi'] = 'graphqlapi/helpers/spaceapi.lua',
        ['graphqlapi.helpers.spaces'] = 'graphqlapi/helpers/spaces.lua',
        ['graphqlapi.middleware'] = 'graphqlapi/middleware.lua',
        ['graphqlapi.models'] = 'graphqlapi/models.lua',
        ['graphqlapi.operations'] = 'graphqlapi/operations.lua',
        --['graphqlapi.printer'] = 'graphqlapi/printer.lua',
        ['graphqlapi.spaces'] = 'graphqlapi/spaces.lua',
        ['graphqlapi.types'] = 'graphqlapi/types.lua',
        ['graphqlapi.utils'] = 'graphqlapi/utils.lua',
        ['graphqlapi.vars'] = 'graphqlapi/vars.lua',
        ['cartridge.roles.graphqlapi'] = 'cartridge/roles/graphqlapi.lua',
    },
}
