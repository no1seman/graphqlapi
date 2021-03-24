local fio = require('fio')
local checks = require('checks')
local errors = require('errors')
local log = require('log')
local json = require('json')

local utils = require('graphqlapi.utils')
local vars = require('graphqlapi.vars').new('graphqlapi.models')

vars:new('models', {})
vars:new('loaded', {})

local e_model_load = errors.new_class('Model load failed', { capture_stack = false })
local e_model_assert = errors.new_class('Model check failed', { capture_stack = false })
local e_model_execute = errors.new_class('Model execute failed', { capture_stack = false })

local function assert_model(model)
    assert(type(model.spaces) == 'table', 'model.spaces must be a table')
    assert(type(model.model) == 'function', 'model.model must be function' )
    for _, space in pairs(model.spaces) do
        assert(type(space) == 'string', string.format("model.spaces item '%s' must be a string", tostring(space)))
    end
    return model
end

local function list_modules()
    local _list = {}
    for key in pairs(package.loaded) do
        _list[key] = true
    end
    return _list
end

local function load_model(dir_name, filename)
    checks('string', 'string')
    local modules_before = list_modules()
    local model_function, err = e_model_load:pcall(loadfile, fio.pathjoin(dir_name, filename))

    if model_function then
        local model = model_function()
        local res, assert_err = e_model_assert:pcall(assert_model, model)
        if res then
            model.filename = filename
            model.name = string.split(filename, '.lua')[1]
            local modules_after = list_modules()
            utils.diff(modules_before, modules_after, vars.loaded)
            return model
        else
            log.error("incorrect GraphQL model format '%s': %s", filename, assert_err)
        end
    else
        log.error("GraphQL model '%s' load failed: %s", filename, err)
    end
    return nil
end

local function load_models(dir_name)
    checks('string')
    local models = {}
    local files = fio.listdir(dir_name) or {}
    table.sort(files)
    for _, filename in ipairs(files) do
        local model = load_model(dir_name, filename)
        table.insert(models, model)
    end
    return models
end

local function apply_model(model)
    local _, err = e_model_execute:pcall(model.model)
    if err ~= nil then
        log.error("model '%s' not applied: %s", model.name, err)
        return nil, err
    else
        log.info("model applied: '%s'", model.name)
    end
end

local function update_space_models(space_name)
    for _, model in ipairs(vars.models) do
        for _, space in pairs(model.spaces) do
            if space == space_name and model.model ~= nil then
                apply_model(model)
            end
        end
    end
end

local function remove_model(filename)
    for _, model in ipairs(vars.models) do
        if model.filename == filename then
            model = nil
        end
    end
end

local function remove_model_by_space_name(space_name)
    for _, model in ipairs(vars.models) do
        for space in pairs(model.spaces) do
            if space == space_name then
                model = nil
            end
        end
    end
end

local function remove_all()
    vars.models = nil
end

local function get_func(mod_name, fun_name)
    for _, model in ipairs(vars.models) do
        if model.name == mod_name then
            if model[fun_name] and type(model[fun_name]) then
                return model[fun_name]
            else
                return nil
            end
        end
    end
    return nil
end

local function init(dir_name)
    vars.models = load_models(dir_name)
    for _, model in ipairs(vars.models) do
        apply_model(model)
    end
end

local function stop()
    remove_all()
    for _, v in pairs(vars.loaded) do
        print(v)
        package.loaded[v] = nil
    end
    vars.loaded = nil
end

local function list_models()
    local models = {}
    for model in pairs(vars.models) do
        table.insert(models, model)
    end
    return models
end

local function list_loaded()
    local loaded = {}
    for module in pairs(vars.loaded) do
        table.insert(loaded, module)
    end
    return loaded
end

return {
    init = init,
    stop = stop,
    update_space_models = update_space_models,
    apply_model = apply_model,
    load_model = load_model,
    remove_model = remove_model,
    remove_model_by_space_name = remove_model_by_space_name,
    remove_all = remove_all,
    get_func = get_func,
    list_models = list_models,
    list_loaded = list_loaded,
    list_modules = list_modules,
}
