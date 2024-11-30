local Pegasus = require('pegasus')
local Files = require('pegasus.plugins.files')
local Websocket = require('server.websocket')
local mimetypes = require('mimetypes')
local Handler = require('pegasus.handler')
local Frame = require('server.frame')
local FrameHandler = require('server.framehandler')
local ConnectionHandler = require('server.connectionhandler')
local ServerClientRegister = require('server.serverclientregister')
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

local frameHandler = FrameHandler:new({
    onTextFrameParsed = function(_: FrameHandler, _: socket.Client, frame: Frame, register: ServerClientRegister)
        print("TEXT FRAME. CONTENT:\n"..frame.stringContent)
        if (string.find(frame.stringContent, "Position updated: x=%d+%.?%d*, y=%d+%.?%d*")) then
            local broadcast = Frame:newTextFrame(frame.stringContent)
            register:registerBroadcastToSend(broadcast)
        end
    end
})
local connectionHandler: ConnectionHandler = ConnectionHandler:new({
    onNewWebsocket = function(_: ConnectionHandler, client: socket.Client, register: ServerClientRegister)
        local pingFrame = Frame:newPingFrame()
        register:registerMessageToSend(client, pingFrame)
    end
})

pegasus.start = function(self: Pegasus)
    local handler = Handler:new(nil, self.location, self.plugins, self.log)
    local server = assert(socket.bind(self.host, self.port))
    local register = ServerClientRegister:new(server)
    websocket:setRegister(register)
    local ip, port = server:getsockname()
  
    print('Pegasus is up on ' .. ip .. ":".. port)
  
    while 1 do
        connectionHandler:handleNext(self, handler, register, frameHandler)
    end
end

pegasus:start()