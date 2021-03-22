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
    maintainer  = "Yaroslav Shumakov <noiseman2000@gmail.com>";
}
dependencies = {
    'lua >= 5.1',
    'ddl >= 1.1.0-1',
    'http == 1.1.0-1',
    'checks >= 3.0.1-1',
    'errors >= 2.1.4-1',
    'graphql >= 0.1.0',
}
build = {
    type = 'builtin',
    modules = {
        ['graphqlapi'] = 'graphqlapi/init.lua',
        ['graphqlapi.funcall'] = 'graphqlapi/funcall.lua',
        ['graphqlapi.helpers'] = 'graphqlapi/helpers.lua',
        ['graphqlapi.middleware'] = 'graphqlapi/middleware.lua',
        ['graphqlapi.models'] = 'graphqlapi/models.lua',
        --['graphqlapi.printer'] = 'graphqlapi/printer.lua',
        ['graphqlapi.spaceapi'] = 'graphqlapi/spaceapi.lua',
        ['graphqlapi.spaces'] = 'graphqlapi/spaces.lua',
        ['graphqlapi.types'] = 'graphqlapi/types.lua',
        ['graphqlapi.utils'] = 'graphqlapi/utils.lua',
        ['graphqlapi.vars'] = 'graphqlapi/vars.lua',
        ['cartridge.roles.graphqlapi'] = 'cartridge/roles/graphqlapi.lua',
    },
}
