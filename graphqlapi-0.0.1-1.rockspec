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
    type = 'cmake';
    install = {
        lua = {
            ['graphqlapi'] = 'graphqlapi/init.lua',
            ['graphqlapi.funcall'] = 'graphqlapi/funcall.lua',
            ['graphqlapi.models'] = 'graphqlapi/models.lua',
            ['graphqlapi.spaces'] = 'graphqlapi/spaces.lua',
            ['graphqlapi.types'] = 'graphqlapi/types.lua',
            ['graphqlapi.vars'] = 'graphqlapi/vars.lua',
            ['cartridge.roles.graphqlapi'] = 'cartridge/roles/graphqlapi.lua',
        },
    },
    variables = {
        version = '0.0.1-1',
        TARANTOOL_DIR = '$(TARANTOOL_DIR)',
        TARANTOOL_INSTALL_LIBDIR = '$(LIBDIR)',
        TARANTOOL_INSTALL_LUADIR = '$(LUADIR)',
        TARANTOOL_INSTALL_BINDIR = '$(BINDIR)',
    },
    install_variables = {
        INST_LUADIR="$(LUADIR)",
    },

}
