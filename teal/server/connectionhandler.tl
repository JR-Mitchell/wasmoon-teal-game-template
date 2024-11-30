local type Pegasus = require('pegasus')
local type Handler = require('pegasus.handler')
local type FrameHandler = require('server.framehandler')
local type ServerClientRegister = require('server.serverclientregister')
local socket = require("socket")
local Frame = require("server.frame")

local record ConnectionHandler
end

function ConnectionHandler:handleNext(pegasus: Pegasus, handler: Handler, register: ServerClientRegister, frameHandler: FrameHandler)
    local receivers, senders, err = socket.select(register.receivers, register.senders, 0)
    if not err then
        if receivers then
            for _, receiver in ipairs(receivers) do
                if (receiver == register.server) then
                    print("New connection available")
                    local client, errmsg = register.server:accept()
    
                    if client then
                        local wrappedClient: socket = {}
                        setmetatable(wrappedClient, {__index = client})
                        client:settimeout(pegasus.timeout, 'b')
                        handler:processRequest(pegasus.port, client, register.server)
                    elseif errmsg ~= "timeout" then
                        print("Failed to accept connection "..register.nextIndex..": "..errmsg)
                    end

                    if (register:containsClient(client)) then
                        print("Connection "..register.nextIndex.." converted to a websocket")
                        client:setoption("keepalive", true)
                    else
                        print("Connection "..register.nextIndex.." completed and closed")
                    end
                else
                    local client = receiver as socket.Client
                    local index = register.indexMap[client]
                    local status, result = pcall(function(): Frame
                        local frame = Frame:readNext(client)
                        return frame
                    end)
                    if (status) then
                        print("New frame received from connection "..index)
                        pcall(function() frameHandler:handleFrame(result) end)
                    else
                        print("Error parsing frame from connection "..index..": "..tostring(result))
                    end
                end
            end
        end
        if senders then
            -- TODO: send
        end
    end
    
end

return ConnectionHandler