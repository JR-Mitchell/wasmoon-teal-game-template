local Pegasus = require('pegasus')
local Files = require('pegasus.plugins.files')
local Websocket = require('server.websocket')
local mimetypes = require('mimetypes')
local Handler = require('pegasus.handler')
local FrameHandler = require('server.framehandler')
local ConnectionHandler = require('server.connectionhandler')
local socket = require("socket")

-- Patch the mimetypes.guess function to handle wasm
local super = mimetypes.guess
mimetypes.guess = function(filename: string): string
    if (string.find(filename, ".+%.wasm")) then
        return "application/wasm"
    end
    return super(filename)
end

local websocket = Websocket:new("/websocket")

local pegasus = Pegasus:new({
    port = "8080",
    location = "dist/",
    plugins = {
        websocket:getPlugin(),
        Files:new({
            location = "./",
            default = "index.html"
        })
    }
})

local frameHandler: FrameHandler = FrameHandler:new({})

pegasus.start = function(self: Pegasus)
    local handler = Handler:new(nil, self.location, self.plugins, self.log)
    local server = assert(socket.bind(self.host, self.port))
    local connectionHandler = ConnectionHandler:new(server, frameHandler)
    local ip, port = server:getsockname()
  
    print('Pegasus is up on ' .. ip .. ":".. port)
  
    while 1 do
        connectionHandler:handleNext(self, handler, websocket)
    end
end

pegasus:start()