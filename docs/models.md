# Submodule **models** functions

- [Submodule **models** functions](#submodule-models-functions)
  - [GraphQL API model structure](#graphql-api-model-structure)
  - [Lua API](#lua-api)
    - [init()](#init)
    - [stop()](#stop)
    - [update_space_models()](#update_space_models)
    - [apply_model()](#apply_model)
    - [load_model()](#load_model)
    - [remove_model()](#remove_model)
    - [remove_model_by_space_name()](#remove_model_by_space_name)
    - [remove_all()](#remove_all)
    - [list_models()](#list_models)
    - [list_loaded()](#list_loaded)

Submodule `models.lua` is a part of GraphQL API module that is used to load, remove and manipulate custom user GraphQL models. GraphQL models for this module must be written using GraphQL API module API and placed to project's subdirectory.

## GraphQL API model structure

Each model must be a valid *.lua which returns a table of the following structure:

```lua
    return {
        -- main model function
        model = function()
            _G._test_model = (_G._test_model or 0) + 1
            return {}
        end,
        -- list of spaces names
        spaces = {}, 
        ...
        func_1 = function() end,
        func_n = function() end,
        ...
    }
```

where:

* `model` (`function`) - mandatory, main function of GraphQL API model that can perform all needed operations to add GraphQL types or/and queries or/and mutations;

* `spaces` (`table`) - optional, array of strings with spaces names.

Model function (`model.model()`) must be idempotent because it will be called on every space changes:
- any space format changes;
- any space indexes changes.

It's highly recommended not to use fiber.yield() inside model() function because it can lead to undefined behavior.

GraphQL API model may require any available module including module placed in the same directory tree as models itself. 

If any lua-file in models dir tree doesn't return model function - it will not be loaded as GraphQL API model.

## Lua API

### init()

`models.init(dir_name)` - function to init `models` module including loading and apply custom GraphQL models provided by application,

where:

`dir_name` (`string`) - optional, GraphQL API models dir path. Base path - is the path to root dir of the application, but absolute path is also possible.

This function is used by internal routines and performs the following actions:

- validate and load all models (*.lua) from `dir_name` including all subdirectories;
- save all models and provided settings to internal module variables;
- apply models that was successfully validated and loaded in previous steps;
- save list of required modules.

### stop()

`models.stop()` - function to deinit `models` module, it removes all models and cleanup all internal module variables including unload all modules that was required by all models functions. This behavior is needed to make possible hot-reload of all models.

### update_space_models()

`models.update_space_models(space_name)` - function to reload models related to provided `space_name`,

where:

`space_name` (`string`) - mandatory, space_name related models that have to be reloaded.

This function is usually called when space with `space_name` is changed. It makes full reload of all loaded models that includes space_name in spaces parameter.

### apply_model()

`models.apply_model(model)` - function to apply model,

where: 

* `model` (`table`) - mandatory, GraphQL API model.

returns:

* `result` (`boolean`) - true if success, false if not

* `error` (`error`) - if apply model fails second return value will contain an error object. 

### load_model()

`models.load_model(filename)` - function to load GraphQL API model from file,

where:

* `filename` (`string`) - mandatory, path to GraphQL API model file. Base path - is the path to root dir of the application, but absolute path is also possible.

Function `load_model()` performs the following actions:

- validate and load model's lua-file;
- save model to internal modules cache if valid;
- save list of modules required by model.

### remove_model()

`models.remove_model(filename)` - function is used to remove GraphQL API model from models internal cache,

where:

* `filename` (`string`) - mandatory, path to GraphQL API model file.

Note: internal model cache is indexed by GraphQL API model filenames.

### remove_model_by_space_name()

`models.remove_model_by_space_name(space_name)` - function is used to remove all GraphQL API model(s) from models internal cache by spaces names,

where:

`space_name` (`string`) - mandatory, space_name related models that have to be reloaded.

Function `remove_model_by_space_name()` is called when space is removed.

### remove_all()

`models.remove_all()` - function to remove all GraphQL API models from models internal cache.

### list_models()

`models.list_models()` - function is used to get array of path's of loaded models,

returns:

* `models` (`table`) - array of loaded models paths. Each model is represented by model lua-file path divided by dot instead of "/".

### list_loaded()

`models.list_loaded()` - function is used to get array of loaded models,

returns:

* `models` (`table`) - array of loaded models ([GraphQL API model structure](#graphql-api-model-structure)).
