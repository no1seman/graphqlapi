local checks = require('checks')

local function render_response(resp)
    return resp
end

local function authorize_request(req)
    checks('table')
    return true
end

return {
    render_response = render_response,
    authorize_request = authorize_request,
}
