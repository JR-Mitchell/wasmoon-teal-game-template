local Pegasus = require('pegasus')
local FilesPlugin = require('pegasus.plugins.files')
local WebsocketHandshakePlugin = require('server.websockets.websocketHandshakePlugin')
local mimetypes = require('mimetypes')
local Handler = require('pegasus.handler')
local Frame = require('server.websockets.frame')
local FrameHandler = require('server.websockets.frameHandler')
local ConnectionHandler = require('server.websockets.connectionHandler')
local ServerClientRegister = require('server.websockets.serverClientRegister')
local socket = require("socket")

-- Patch the mimetypes.guess function to handle wasm
local super = mimetypes.guess
mimetypes.guess = function(filename: string): string
    if (string.find(filename, ".+%.wasm")) then
        return "application/wasm"
    end
    return super(filename)
end

-- This plugin allows the client to perform a websocket handshake
local websocketHandshakePlugin = WebsocketHandshakePlugin:new("/websocket")

-- Basic server setup
local pegasus = Pegasus:new({
    port = "8080",
    location = "dist/",
    plugins = {
        websocketHandshakePlugin:getPlugin(),
        FilesPlugin:new({
            location = "./",
            default = "index.html"
        })
    }
})

-- A FrameHandler which broadcasts any updates to position
local frameHandler = FrameHandler:new({
    onTextFrameParsed = function(_: FrameHandler, _: socket.Client, frame: Frame, register: ServerClientRegister)
        print("TEXT FRAME. CONTENT:\n"..frame.stringContent)
        if (string.find(frame.stringContent, "Position updated: x=%d+%.?%d*, y=%d+%.?%d*")) then
            local broadcast = Frame:newTextFrame(frame.stringContent)
            register:registerBroadcastToSend(broadcast)
        end
    end
})

-- A FrameHandler which pings a client after it is connected
local connectionHandler: ConnectionHandler = ConnectionHandler:new({
    onNewWebsocket = function(_: ConnectionHandler, client: socket.Client, register: ServerClientRegister)
        local pingFrame = Frame:newPingFrame()
        register:registerMessageToSend(client, pingFrame)
    end
})

pegasus.start = function(self: Pegasus)
    local handler = Handler:new(nil, self.location, self.plugins, self.log)
    local server = assert(socket.bind(self.host, self.port))
    -- Keeps track of connected websocket clients
    local register = ServerClientRegister:new(server)
    -- Makes sure that any successful websocket handshake stores the client in the register
    websocketHandshakePlugin:setRegister(register)
    local ip, port = server:getsockname()
  
    print('Pegasus is up on ' .. ip .. ":".. port)
  
    while 1 do
        connectionHandler:handleNext(self, handler, register, frameHandler)
    end
end

pegasus:start()