local type Pegasus = require('pegasus')
local type ServerClientRegister = require('server.serverclientregister')
local sha1 = require('sha1')
local base64 = require('base64')

local magicString <const> = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

local record WebsocketPlugin
    path: string
    register: ServerClientRegister
end

local function getAcceptHeader(key: string): string
    local keyConcat = key..magicString
    local byteString = sha1.binary(keyConcat)
    return base64.encode(byteString)
end

function WebsocketPlugin:new(path: string): WebsocketPlugin
    local newInstance: WebsocketPlugin = {}
    newInstance.path = path
    setmetatable(newInstance, {__index = WebsocketPlugin})
    return newInstance
end

function WebsocketPlugin:setRegister(register: ServerClientRegister)
    self.register = register
end

function WebsocketPlugin:getPlugin(): Pegasus.Plugin
    local plugin: Pegasus.Plugin = {}
    plugin.newRequestResponse = function(_: Pegasus.Plugin, request: Pegasus.Request, response: Pegasus.Response): boolean
        local method = request:method()
        if (method ~= "GET") then return false end
        local path = request:path()
        if (path ~= self.path) then return false end
        local headers = request:headers()
        if (headers == nil) then return false end
        if (headers["connection"] == nil or not string.find(headers["connection"], "Upgrade")) then return false end
        if (headers["upgrade"] == nil or not string.find(headers["upgrade"], "websocket")) then return false end
        if (headers["sec-websocket-version"] ~= "13") then return false end
        -- TODO: we probably should check the host header and origin header
        local key = headers["sec-websocket-key"]
        if (key == nil) then return false end
        response:statusCode(101)
        response:addHeader("Upgrade", "websocket")
        response:addHeader("Connection", "Upgrade,Keep-Alive,keep-alive")
        response:addHeader("Sec-WebSocket-Accept", getAcceptHeader(key))
        response:addHeader("Sec-Websocket-Protocol", "json")
        response:sendHeaders(true, '')
        -- Mark that this client has been transformed into a websocket
        self.register:addClient(request.client)
        return true
    end
    return plugin
end

return WebsocketPlugin