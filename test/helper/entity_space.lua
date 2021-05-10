local helper = require('test.helper.integration')

local function sample_data(length)
    local bsize

    if length == 0 then
        bsize = 0
    else
        bsize = length*16+(length-1)*2
    end

    return {{
        format = {
            { type = 'unsigned', name = 'bucket_id', is_nullable = false, },
            { type = 'string', name = 'entity_id', is_nullable = false, },
            { type = 'string', name = 'entity', is_nullable = false, },
            { type = 'number', name = "entity_value", is_nullable = true, }
        },
        id = 512, engine = 'memtx', field_count = 4, is_sync = false,
        index = {
            {
                parts = {{ type = 'string', fieldno = 2, is_nullable = false, }},
                id = 0, space_id = 512, len = length, unique = true, bsize = 49152*length,
                hint = true, type = 'TREE', name = 'primary',
            },
            {
                parts = {{ type = 'number', fieldno = 4, is_nullable = true, }},
                id = 1, space_id = 512, len = length, unique = true, bsize = 49152*length,
                hint = true, type = 'TREE', name = 'secondary',
            },
            {
                parts = {{ type = 'unsigned', fieldno = 1, is_nullable = false, }},
                id = 2, space_id = 512, len = length, unique = false, bsize = 49152*length,
                hint = true, type = 'TREE', name = 'bucket_id',
            }
        },
        bsize = bsize,
        temporary = false,
        ck_constraint = {
            {
                space_id = 512, is_enabled = false,
                name = 'entity_value', expr = "'entity_value' > 0",
            }
        },
        is_local = false, enabled = true, name = 'entity', len = length,
    }}
end

local function create_test_space(cluster, space_name)
    local format = {
        {name = 'bucket_id', type = 'unsigned', is_nullable = false},
        {name = 'entity_id', type = 'string', is_nullable = false},
        {name = 'entity', type = 'string', is_nullable = false},
        {name = 'entity_value', type = 'number', is_nullable = true}
    }

    local primary_index_parts = { {field = 'entity_id'} }
    local secondary_index_parts = { {field = 'entity_value'} }
    local sharding_key = {{'entity_id'}}

    helper.create_space_on_cluster(cluster, space_name, format)
    helper.create_primary_index_on_cluster(cluster, space_name, primary_index_parts)
    helper.create_secondary_index_on_cluster(cluster, space_name, 'secondary', true, secondary_index_parts)
    helper.create_bucket_index_on_cluster(cluster, space_name, sharding_key)
    helper.create_check_constraint_on_cluster(cluster, space_name, 'entity_value', [['entity_value' > 0]])
end

return {
    sample_data = sample_data,
    create_test_space = create_test_space,
}
