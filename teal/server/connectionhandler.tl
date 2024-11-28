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
                        print("New message from connection "..index..": "..(line or "nil")..", error: "..(errmsg or "nil"))
                        if (errmsg == nil and line ~= nil) then
                            local str, err2 = pcall(function(): string
                                local frame = Frame:parseAsBits(line)
                                return frame.content
                            end)
                            if (str) then print(str) end
                            if (err2) then print("Error: "..err2) end
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