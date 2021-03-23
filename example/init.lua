local http = require('http.server')
local graphqlapi = require('graphqlapi')

local HOST = '0.0.0.0'
local PORT = 8081
local ENDPOINT = '/graphql'

box.cfg({work_dir = './tmp'})

local httpd = http.new(HOST, PORT,{ log_requests = false })

httpd:start()
graphqlapi.init(httpd, nil, ENDPOINT, '../example/models')

