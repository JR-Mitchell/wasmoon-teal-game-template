local type Pegasus = require('pegasus')
local type Handler = require('pegasus.handler')
local type WebsocketPlugin = require('server.websocket')
local socket = require("socket")
local Frame = require("server.frame")

local record ConnectionHandler
    server: socket.Server
    receivers: {any}
    senders: {socket.Client}
    nextIndex: integer
    indexMap: {socket.Client:integer}
end

function ConnectionHandler:new(server: socket.Server): ConnectionHandler
    local instance: ConnectionHandler = {
        server = server,
        receivers = {server},
        senders = {},
        nextIndex = 1,
        indexMap = {}
    }
    setmetatable(instance, {__index = ConnectionHandler})
    return instance
end

function ConnectionHandler:handleNext(pegasus: Pegasus, handler: Handler, websockets: WebsocketPlugin)
    local receivers, senders, err = socket.select(self.receivers, self.senders, 0)
    if not err then
        if receivers then
            for _, receiver in ipairs(receivers) do
                if (receiver == self.server) then
                    print("New connection available")
                    local client, errmsg = self.server:accept()
    
                    if client then
                        local wrappedClient: socket = {}
                        setmetatable(wrappedClient, {__index = client})
                        client:settimeout(pegasus.timeout, 'b')
                        handler:processRequest(pegasus.port, client, self.server)
                    elseif errmsg ~= "timeout" then
                        print("Failed to accept connection "..self.nextIndex..": "..errmsg)
                    end

                    if (websockets.clients[client]) then
                        print("Connection "..self.nextIndex.." converted to a websocket")
                        table.insert(self.receivers, client)
                        table.insert(self.senders, client)
                        self.indexMap[client] = self.nextIndex
                        self.nextIndex = self.nextIndex + 1
                        websockets.clients[client] = nil
                        client:setoption("keepalive", true)
                    else
                        print("Connection "..self.nextIndex.." completed and closed")
                    end
                    print(client:getstats())
                else
                    local client = receiver as socket.Client
                    local index = self.indexMap[client]
                    --[[
                    TODO: the below is wrong, because client:receive with no argument receives until the next newline.
                    As we are receiving binary data that we then need to interpret, and which is masked,
                    we might not receive the bytes that resemble a newline for a long time; OR we might receive them multiple times per frame.
                    Instead, we should receive the first 2 bytes, then interpret them, and read more bytes until the frame is complete.
                    ]]--
                    local line, errmsg = client:receive()
                    if (errmsg == "closed") then
                        client:close()
                        for i=1,#self.receivers do
                            if self.receivers[i] == client then
                                table.remove(self.receivers, i)
                                break
                            end
                        end
                        for i=1,#self.senders do
                            if self.senders[i] == client then
                                table.remove(self.senders, i)
                                break
                            end
                        end
                        self.indexMap[client] = nil
                        print("Websocket connection "..index.." closed.")
                    elseif (errmsg ~= "timeout") then
                        if (errmsg ~= nil) then
                            print("Error from connection "..index..": "..errmsg)
                        elseif (line ~= nil) then
                            local status, result = pcall(function(): string
                                local frame = Frame:parse(line)
                                return frame:string()
                            end)
                            if (status) then
                                print("Frame received from connection "..index..":\n"..result)
                            else
                                print("Error parsing frame from connection "..index..": "..result)
                            end
                        end
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