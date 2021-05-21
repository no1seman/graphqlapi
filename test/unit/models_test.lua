local t = require('luatest')
local g = t.group('models')

local helper = require('test.helper')
local models = require('graphqlapi.models')

g.after_each(function()
    models.stop()
end)

g.test_apply_model = function()
    local model = {}
    local ok, err = models.apply_model(model)
    t.assert_equals(ok, nil)
    t.assert_equals(err.err, 'attempt to call a nil value')

    model = { model = nil }
    ok, err = models.apply_model(model)
    t.assert_equals(ok, nil)
    t.assert_equals(err.err, 'attempt to call a nil value')

    model = { model = function() return 1+nil end }
    ok, err = models.apply_model(model)
    t.assert_equals(ok, nil)
    t.assert_str_contains(err.err, 'attempt to perform arithmetic on a nil value')

    model = { model = function() return true end }
    local res = models.apply_model(model)
    t.assert_equals(res, true)
end

g.test_load_model = function()
    package.path = helper.project_root.. '/test/models/suite1/?.lua;' .. package.path

    -- check non-existent file
    local ok, err = models.load_model('test/models/suite1/empty1.lua')
    t.assert_equals(ok, nil)
    t.assert_equals(err,
        'cannot open '..(package.searchroot())..'/test/models/suite1/empty1.lua: No such file or directory')

    -- check empty file
    ok, err = models.load_model('test/models/suite1/empty.lua')
    t.assert_equals(ok, nil)
    t.assert_str_contains(err.err, 'model must be a table')

    -- check file with syntax error
    ok, err = models.load_model('test/models/suite1/syntax_error.lua')
    t.assert_equals(ok, nil)
    t.assert_str_contains(err, 'unexpected symbol near \'111\'')

    -- check file with missing model
    ok, err = models.load_model('test/models/suite1/missing_model.lua')
    t.assert_equals(ok, nil)
    t.assert_str_contains(err.err, 'model must contain \'model\' function')

    -- check file with invalid spaces
    ok, err = models.load_model('test/models/suite1/invalid_spaces.lua')
    t.assert_equals(ok, nil)
    t.assert_str_contains(err.err, 'model.spaces must be a table')

    -- check file with invalid space in spaces array
    ok, err = models.load_model('test/models/suite1/invalid_space.lua')
    t.assert_equals(ok, nil)
    t.assert_str_contains(err.err, 'model.spaces item \'1\' must be a string')

    -- check file with missing spaces
    local model = models.load_model('test/models/suite1/missing_spaces.lua')
    t.assert_equals(type(model.model), 'function')

    -- check file with valid model
    model = models.load_model('test/models/suite1/valid_model.lua')
    t.assert_items_equals(model.spaces, {'model'})
    t.assert_equals(type(model.model), 'function')
    t.assert_equals(type(model.f), 'function')
end

g.test_init_stop = function()
    package.path = helper.project_root.. '/test/models/suite1/?.lua;' .. package.path
    models.init('test/models/suite1')
    t.assert_items_equals(models.list_models(), {
        'test.models.suite1.missing_spaces',
        'test.models.suite1.valid_model',
        'test.models.suite1.spaces.spaces',
    })
    t.assert_items_equals(models.list_loaded(), {'module'})

    models.stop()
    t.assert_items_equals(models.list_models(), {})
    t.assert_equals(package.loaded['module'], nil)
end

g.test_remove_model = function()
    package.path = helper.project_root.. '/test/models/suite1/?.lua;' .. package.path
    models.init('test/models/suite1/')
    t.assert_items_equals(models.list_models(), {
        'test.models.suite1.missing_spaces',
        'test.models.suite1.valid_model',
        'test.models.suite1.spaces.spaces',
    })
    t.assert_items_equals(models.list_loaded(), {'module'})

    models.remove_model('test/models/suite1/valid_model.lua')
    t.assert_items_equals(models.list_models(), {
        'test.models.suite1.missing_spaces',
        'test.models.suite1.spaces.spaces',
    })

    models.stop()

    models.init('./test/models/suite1/')
    t.assert_items_equals(models.list_models(), {
        'test.models.suite1.missing_spaces',
        'test.models.suite1.valid_model',
        'test.models.suite1.spaces.spaces',
    })
    t.assert_items_equals(models.list_loaded(), {'module'})

    models.remove_model('test.models.suite1.valid_model')
    t.assert_items_equals(models.list_models(), {
        'test.models.suite1.missing_spaces',
        'test.models.suite1.spaces.spaces',
    })
end

g.test_remove_model_by_space_name = function ()
    package.path = helper.project_root.. '/test/models/suite1/?.lua;' .. package.path
    models.init('test/models/suite1/')
    t.assert_items_equals(models.list_models(), {
        'test.models.suite1.missing_spaces',
        'test.models.suite1.valid_model',
        'test.models.suite1.spaces.spaces',
    })
    t.assert_items_equals(models.list_loaded(), {'module'})

    models.remove_model_by_space_name('model')

    t.assert_items_equals(models.list_models(), {
        'test.models.suite1.missing_spaces',
        'test.models.suite1.spaces.spaces',
    })
end

g.test_update_space_models = function()
    _G._test_model = 0
    package.path = helper.project_root.. '/test/models/suite1/?.lua;' .. package.path
    models.init('test/models/suite1')
    t.assert_items_equals(models.list_models(), {
        'test.models.suite1.missing_spaces',
        'test.models.suite1.valid_model',
        'test.models.suite1.spaces.spaces',
    })
    t.assert_equals(_G._test_model, 1)
    models.update_space_models('model')
    t.assert_equals(_G._test_model, 2)
end

g.test_get_func = function()
    package.path = helper.project_root.. '/test/models/suite1/?.lua;' .. package.path
    local model = models.load_model('test/models/suite1/valid_model.lua')
    models.apply_model(model)

    local mod_path = ('test/models/suite1'):gsub('/', '%.'):lstrip('.')
    local mod_name = 'valid_model'
    local fun_name = 'f'
    local fun = models.get_func(mod_path, mod_name, fun_name)
    t.assert_items_equals(fun(), {module = 'model function'})
    models.stop()

    models.init('test/models/suite1/')
    fun = models.get_func(mod_path, mod_name, fun_name)
    t.assert_items_equals(fun(), {module = 'model function'})

    fun = models.get_func()
    t.assert_equals(fun, nil)
end
