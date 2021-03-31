local checks = require('checks')
local errors = require('errors')
local models = require('graphqlapi.models')
local log = require('log')
local json = require('json')

local e_funcall = errors.new_class("Funcall failed")

local function call(function_name, ...)
    checks('string')

    local parts = function_name:split('.')

    local mod_name
    local fun_name
    local mod_path
    for index, value in ipairs(parts) do
        if index <= #parts-2 then
            mod_path = (mod_path or '')..value
            if index < #parts-2 then
                mod_path = mod_path .. '.'
            end
        elseif index == #parts-1 then
            mod_name = value
        else
            fun_name = value
        end
    end

    if (mod_name == nil) or (fun_name == nil) then
        return nil, e_funcall:new(
            'funcall.call() expects function_name' ..
            ' to contain module name. Got: %q', function_name
        )
    end

    local fun = models.get_func(mod_path, mod_name, fun_name)

    if fun == nil then
        local mod
        if mod_path then
            mod = package.loaded[mod_path..'.'..mod_name]
        else
            mod = package.loaded[mod_name]
        end

        if mod == nil then
            return nil, e_funcall:new(
                'Can not find module %q', mod_name
            )
        end
        fun = mod[fun_name]
    end

    if fun == nil then
        return nil, e_funcall:new(
            'No function %q in module %q', fun_name, mod_name
        )
    end

    return fun(...)
end

return {
    call = call,
}
