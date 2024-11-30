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
                        pcall(function() frameHandler:handleFrame(client, result, register) end)
                    else
                        print("Error parsing frame from connection "..index..": "..tostring(result))
                    end

                    -- Send immediate responses, e.g ping or pong
                    for _, frame in ipairs(register.immediateMessageQueue[client]) do
                        client:send(frame)
                    end
                end
            end
        end
        if senders then
            for _, client in ipairs(senders) do
                local index = register.indexMap[client]
                -- Send non-immediate responses, e.g broadcasts
                for _, frame in ipairs(register.messageQueue[client]) do
                    print("Sending frame to client "..tostring(index))
                    client:send(frame)
                end
            end
        end
    end
    
end

return ConnectionHandler