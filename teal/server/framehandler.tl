local type socket = require("socket")
local type ServerClientRegister = require('server.serverclientregister')
local Frame = require("server.frame")

local record FrameHandler
    unfinishedFrameLookup: {socket.Client:Frame}
    optable: {integer: function(FrameHandler, socket.Client, Frame, ServerClientRegister)}
    handleFrame: function(self: FrameHandler, client: socket.Client, frame: Frame, register: ServerClientRegister)
end

function FrameHandler:handleUnfinishedContinuationFrame(client: socket.Client, frame: Frame, _: ServerClientRegister)
    print("CONTINUATION FRAME.")
    self.unfinishedFrameLookup[client].payloadBytes = self.unfinishedFrameLookup[client].payloadBytes .. frame.payloadBytes
end

function FrameHandler:handleFinalContinuationFrame(client: socket.Client, frame: Frame, register: ServerClientRegister)
    print("FINAL CONTINUATION FRAME.")
    local finishedFrame = self.unfinishedFrameLookup[client]
    self.unfinishedFrameLookup[client] = nil
    finishedFrame.payloadBytes = finishedFrame.payloadBytes .. frame.payloadBytes
    finishedFrame.fin = true
    self:handleFrame(client, finishedFrame, register)
end

function FrameHandler:onTextFrameParsed(_: socket.Client, frame: Frame, _: ServerClientRegister)
    print("TEXT FRAME. CONTENT:\n"..frame.stringContent)
end

function FrameHandler:handleUnfinishedTextFrame(client: socket.Client, frame: Frame, _: ServerClientRegister)
    print("UNFINISHED TEXT FRAME.")
    self.unfinishedFrameLookup[client] = frame
end

function FrameHandler:handleFinalTextFrame(client: socket.Client, frame: Frame, register: ServerClientRegister)
    frame:parseContentAsString()
    self:onTextFrameParsed(client, frame, register)
end

function FrameHandler:onBinaryFrameParsed(_: socket.Client, frame: Frame, _: ServerClientRegister)
    local printText = "Binary FRAME. CONTENT:\n"
    for _, byte in ipairs(frame.binaryContent) do
        printText = printText .. tostring(byte//16) .. tostring(byte%16) .. " "
    end
    print(printText)
end

function FrameHandler:handleUnfinishedBinaryFrame(client: socket.Client, frame: Frame, _: ServerClientRegister)
    print("UNFINISHED BINARY FRAME.")
    self.unfinishedFrameLookup[client] = frame
end

function FrameHandler:handleFinalBinaryFrame(client: socket.Client, frame: Frame, register: ServerClientRegister)
    frame:parseContentAsBinary()
    self:onBinaryFrameParsed(client, frame, register)
end

function FrameHandler:handleCloseFrame(client: socket.Client, _: Frame, register: ServerClientRegister)
    print("CLOSE FRAME.")
    local index = register.indexMap[client]
    print("Closing connection "..index)
    register:removeClient(client)
    client:close()
end

function FrameHandler:handlePingFrame(client: socket.Client, frame: Frame, register: ServerClientRegister)
    print("PING FRAME.")
    frame:parseContentAsString()
    local pongFrame = Frame:newPongFrame(frame.stringContent)
    register:registerMessageToSendImmediately(client, pongFrame)
end

function FrameHandler:handlePongFrame(_: socket.Client, _: Frame, _: ServerClientRegister)
    -- TODO
    print("PONG FRAME.")
end

function FrameHandler:handleUnknownFrameType(_: socket.Client, frame: Frame, _: ServerClientRegister)
    print("UNKNOWN FRAME OPCODE: "..tonumber(frame.opcode))
end

function FrameHandler:handleFrame(client: socket.Client, frame: Frame, register: ServerClientRegister)
    local methodToCall = self.optable[frame.opcode]
    if (methodToCall == nil) then
        self:handleUnknownFrameType(client, frame, register)
    else
        methodToCall(self, client, frame, register)
    end
end

function FrameHandler:new(instance: FrameHandler): FrameHandler
    local newInstance = instance or {}
    setmetatable(newInstance, {__index = FrameHandler})
    newInstance.optable = newInstance.optable or {
        [0] = function(self: FrameHandler, client: socket.Client, frame: Frame, register: ServerClientRegister)
            if (frame.fin) then
                self:handleFinalContinuationFrame(client, frame, register)
            else
                self:handleUnfinishedContinuationFrame(client, frame, register)
            end
        end,
        [1] = function(self: FrameHandler, client: socket.Client, frame: Frame, register: ServerClientRegister)
            if (frame.fin) then
                self:handleFinalTextFrame(client, frame, register)
            else
                self:handleUnfinishedTextFrame(client, frame, register)
            end
        end,
        [2] = function(self: FrameHandler, client: socket.Client, frame: Frame, register: ServerClientRegister)
            if (frame.fin) then
                self:handleFinalContinuationFrame(client, frame, register)
            else
                self:handleUnfinishedContinuationFrame(client, frame, register)
            end
        end,
        [8] = function(self: FrameHandler, client: socket.Client, frame: Frame, register: ServerClientRegister) self:handleCloseFrame(client, frame, register) end,
        [9] = function(self: FrameHandler, client: socket.Client, frame: Frame, register: ServerClientRegister) self:handlePingFrame(client, frame, register) end,
        [10] = function(self: FrameHandler, client: socket.Client, frame: Frame, register: ServerClientRegister) self:handlePongFrame(client, frame, register) end
    }
    newInstance.unfinishedFrameLookup = {}
    return newInstance
end

return FrameHandler