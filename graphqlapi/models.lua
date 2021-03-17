local fio = require('fio')
local checks = require('checks')
local errors = require('errors')
local log = require('log')

local vars = require('graphqlapi.vars').new('graphqlapi.models')

vars:new('models', {})

local e_model_load = errors.new_class('Model load failed', { capture_stack = false })
local e_model_assert = errors.new_class('Model check failed', { capture_stack = false })
local e_model_execute = errors.new_class('Model execute failed', { capture_stack = false })


local function full_path(dir_name)
    return fio.pathjoin(package.searchroot(), dir_name)
end

local function assert_model(model)
    assert(type(model.spaces) == 'table', 'model.spaces must be a table')
    assert(type(model.model) == 'function', 'model.model must be function' )
    for _, space in pairs(model.spaces) do
        assert(type(space) == 'string', string.format('model.spaces item "%s" must be a string', tostring(space)))
    end
    return model
end

local function load_model(dir_name, filename)
    checks('string', 'string')

    local model_function, err = e_model_load:pcall(loadfile, fio.pathjoin(full_path(dir_name), filename))

    if model_function then
        local model = model_function()
        local res = e_model_assert:pcall(assert_model, model)
        if res then
            model.filename = filename
            log.info('loaded GraphQL model: "%s"', filename)
            return model
        else
            log.error('incorrect model format %s: %s', filename, res)
        end
    else
        log.error('model load "%s" failed: %s', filename, err)
    end
    return nil
end

local function load_models(dir_name)
    checks('string')
    local models = {}
    local search_folder = full_path(dir_name)
    if not fio.path.is_dir(search_folder) then error(('Path %s is not valid'):format(search_folder)) end
    local files = fio.listdir(search_folder) or {}
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
        log.error('Model %s not applied: %s', model.name, err)
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

local function init(dir_name)
    vars.models = load_models(dir_name)
    for _, model in ipairs(vars.models) do
        apply_model(model)
    end
end

return {
    init = init,
    update_space_models = update_space_models,
    apply_model = apply_model,
    load_model = load_model,
    remove_model = remove_model,
    remove_model_by_space_name = remove_model_by_space_name,
    remove_all = remove_all,
}
