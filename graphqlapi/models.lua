local checks = require('checks')
local errors = require('errors')
local fio = require('fio')
local log = require('log')

local utils = require('graphqlapi.utils')
local vars = require('graphqlapi.vars').new('graphqlapi.models')

vars:new('models', {})
vars:new('loaded', {})
vars:new('dir_name', nil)

local e_model_load = errors.new_class('GraphQLAPI model load failed', { capture_stack = true })
local e_model_assert = errors.new_class('GraphQLAPI model check failed', { capture_stack = true })
local e_model_execute = errors.new_class('GraphQLAPI model execute failed', { capture_stack = true })

local function list_modules()
    local list = {}
    for key in pairs(package.loaded) do
        list[key] = true
    end
    return list
end

local function list_models()
    local models = {}
    for key in pairs(vars.models) do
        table.insert(models, key)
    end
    return models
end

local function list_loaded()
    return vars.loaded
end

local function assert_model(model)
    assert(type(model) == 'table', 'model must be a table')
    if model.model == nil then
        error('model must contain \'model\' function')
    end
    assert(type(model.model) == 'function', 'model.model must be function')
    if model.spaces then
        assert(type(model.spaces) == 'table', 'model.spaces must be a table')
        for _, space in pairs(model.spaces) do
            assert(type(space) == 'string', string.format("model.spaces item '%s' must be a string", tostring(space)))
        end
    end
    return model
end

local function load_model(filename)
    checks('string')
    local modules_before = list_modules()
    local model_function, err = e_model_load:pcall(loadfile, fio.pathjoin(package.searchroot(), filename))
    if model_function then
        local model = model_function()
        local res, assert_err = e_model_assert:pcall(assert_model, model)
        if res then
            model.filename = filename
            model.name = filename:match("^(.+)%.lua$"):gsub('/', '%.'):lstrip('.')
            model.spaces = model.spaces or {}
            local modules_after = list_modules()
            utils.diff_maps(modules_before, modules_after, vars.loaded)
            vars.models[model.name] = model
            return model
        else
            log.error(assert_err.err)
            return nil, assert_err
        end
    else
        log.error(err)
        return nil, err
    end
end

local function load_models(dir_name)
    checks('string')
    local files = {}

    local function scandir(directory)
        local full_path = fio.pathjoin(package.searchroot(), directory)
        local pfile = assert(io.popen(
            ("find '%s' -mindepth 1 -maxdepth 1 -printf '%%f\\0'"):format(full_path), 'r'))
        local list = pfile:read('*a')
        pfile:close()

        for filename in string.gmatch(list, '[^%z]+') do
            local abs_path = fio.pathjoin(directory, filename)
            if fio.path.is_dir(fio.pathjoin(package.searchroot(), abs_path)) then
                scandir(abs_path)
            else
                if filename:match("^.+(%..+)$") == '.lua' then
                    local path = fio.pathjoin(directory, filename)
                    if path:startswith('./') then
                        path = path:sub(3)
                    end
                    table.insert(files, path)
                end
            end
        end
    end

    scandir(dir_name)

    table.sort(files)
    for _, filename in ipairs(files) do
        if filename:match("^.+(%..+)$") == '.lua' then
            load_model(filename)
        end
    end
end

local function apply_model(model)
    local _, err = e_model_execute:pcall(model.model)
    if err ~= nil then
        log.error("GraphQLAPI model '%s' not applied: %s", model.filename or 'unknown', err)
        return nil, err
    else
        log.info("GraphQLAPI model '%s' applied", model.filename)
        return true
    end
end

local function update_space_models(space_name)
    for _, model in pairs(vars.models) do
        for _, space in pairs(model.spaces) do
            if space == space_name and model.model ~= nil then
                apply_model(model)
            end
        end
    end
end

local function remove_model(filename)
    checks('string')
    if type(vars.models) == 'table' then
        local model = filename:match("^(.+)%.lua$")
        if model then
            vars.models[model:gsub('/', '%.'):lstrip('.')] = nil
        else
            vars.models[filename] = nil
        end
    end
end

local function remove_model_by_space_name(space_name)
    checks('string')
    for key, model in pairs(vars.models) do
        for _,space in pairs(model.spaces) do
            if space == space_name then
                vars.models[key] = nil
            end
        end
    end
end

local function remove_all()
    vars.models = nil
    for _, v in pairs(vars.loaded) do
        package.loaded[v] = nil
    end
    vars.loaded = nil
end

local function get_func(mod_path, mod_name, fun_name)
    if mod_name and fun_name then
        mod_path = mod_path or ''
        local model = vars.models[mod_path..'.'..mod_name]
        if model and model[fun_name] and type(model[fun_name]) == 'function' then
            return model[fun_name]
        else
            return nil
        end
    end
    return nil
end

local function init(dir_name)
    vars.dir_name = dir_name
    load_models(dir_name)
    for _, model in pairs(vars.models) do
        apply_model(model)
    end
end

local function stop()
    remove_all()
    vars.dir_name = nil
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
}
