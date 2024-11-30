local type socket = require("socket")
local type Frame = require("server.frame")
local type SendableFrame = require("server.sendableframe")

local record ServerClientRegister
    server: socket.Server
    receivers: {any}
    senders: {socket.Client}
    nextIndex: integer
    indexMap: {socket.Client:integer}
    immediateMessageQueue: {socket.Client:{SendableFrame}}
    messageQueue: {socket.Client:{SendableFrame}}
end

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
    setmetatable(instance, {__index = ServerClientRegister})
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

function ServerClientRegister:registerMessageToSend(recipient: socket.Client, message: Frame)
    table.insert(self.messageQueue[recipient], message:getSendable())
end

function ServerClientRegister:registerMessageToSendImmediately(recipient: socket.Client, message: Frame)
    table.insert(self.immediateMessageQueue[recipient], message:getSendable())
end

function ServerClientRegister:containsClient(client: socket.Client): boolean
    return not not self.indexMap[client]
end

return ServerClientRegister