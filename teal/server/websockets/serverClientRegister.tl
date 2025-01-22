local type socket = require("socket")
local type Frame = require("server.websockets.frame")
local type SendableFrame = require("server.websockets.sendableFrame")

-- Class for containing info about all connected websocket clients
local record ServerClientRegister
    server: socket.Server
    receivers: {any}
    senders: {socket.Client}
    nextIndex: integer
    indexMap: {socket.Client:integer}
    immediateMessageQueue: {socket.Client:{SendableFrame}}
    messageQueue: {socket.Client:{SendableFrame}}
end

local ServerClientRegisterMetatable: metatable<ServerClientRegister> = {
    __index = ServerClientRegister
}

function ServerClientRegister:new(server: socket.Server): ServerClientRegister
    local instance: ServerClientRegister = {
        server = server,
        receivers = {server},
        senders = {},
        nextIndex = 1,
        indexMap = {},
        immediateMessageQueue = {},
        messageQueue = {}
    }
    setmetatable(instance, ServerClientRegisterMetatable)
    return instance
end

function ServerClientRegister:addClient(client: socket.Client)
    table.insert(self.receivers, client)
    table.insert(self.senders, client)
    self.messageQueue[client] = {}
    self.immediateMessageQueue[client] = {}
    self.indexMap[client] = self.nextIndex
    self.nextIndex = self.nextIndex + 1
end

function ServerClientRegister:removeClient(client: socket.Client)
    for i=#self.receivers,1,-1 do
        if (self.receivers[i] == client) then
            table.remove(self.receivers, i)
        end
    end
    for i=#self.senders,1,-1 do
        if (self.senders[i] == client) then
            table.remove(self.senders, i)
        end
    end
    self.messageQueue[client] = nil
    self.immediateMessageQueue[client] = nil
    self.indexMap[client] = nil
end

function ServerClientRegister:registerMessageToSend(recipient: socket.Client, message: Frame)
    table.insert(self.messageQueue[recipient], message:getSendable())
end

function ServerClientRegister:registerMessageToSendImmediately(recipient: socket.Client, message: Frame)
    table.insert(self.immediateMessageQueue[recipient], message:getSendable())
end

function ServerClientRegister:registerMessagesToSend(recipients: {socket.Client}, message: Frame)
    local sendable = message:getSendable()
    for _, recipient in ipairs(recipients) do
        table.insert(self.messageQueue[recipient], sendable)
    end
end

function ServerClientRegister:registerMessagesToSendImmediately(recipients: {socket.Client}, message: Frame)
    local sendable = message:getSendable()
    for _, recipient in ipairs(recipients) do
        table.insert(self.immediateMessageQueue[recipient], sendable)
    end
end

function ServerClientRegister:registerBroadcastToSend(message: Frame)
    self:registerMessagesToSend(self.senders, message)
end

function ServerClientRegister:registerBroadcastToSendImmediately(message: Frame)
    self:registerMessagesToSendImmediately(self.senders, message)
end

function ServerClientRegister:containsClient(client: socket.Client): boolean
    return not not self.indexMap[client]
end

return ServerClientRegister