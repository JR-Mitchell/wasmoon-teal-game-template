local type socket = require("socket")

local record ServerClientRegister
    server: socket.Server
    receivers: {any}
    senders: {socket.Client}
    nextIndex: integer
    indexMap: {socket.Client:integer}
end

function ServerClientRegister:new(server: socket.Server): ServerClientRegister
    local instance: ServerClientRegister = {
        server = server,
        receivers = {server},
        senders = {},
        nextIndex = 1,
        indexMap = {}
    }
    setmetatable(instance, {__index = ServerClientRegister})
    return instance
end

function ServerClientRegister:addClient(client: socket.Client)
    table.insert(self.receivers, client)
    table.insert(self.senders, client)
    self.indexMap[client] = self.nextIndex
    self.nextIndex = self.nextIndex + 1
end

function ServerClientRegister:containsClient(client: socket.Client): boolean
    return not not self.indexMap[client]
end

return ServerClientRegister