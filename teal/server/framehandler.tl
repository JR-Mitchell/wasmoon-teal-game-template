local type Frame = require("server.frame")
local type ServerClientRegister = require('server.serverclientregister')

local record FrameHandler
    unfinishedFrame: Frame
    optable: {integer: function(FrameHandler, Frame, ServerClientRegister)}
    handleFrame: function(self: FrameHandler, frame: Frame, register: ServerClientRegister)
end

function FrameHandler:handleUnfinishedContinuationFrame(frame: Frame, _: ServerClientRegister)
    print("CONTINUATION FRAME.")
    self.unfinishedFrame.payloadBytes = self.unfinishedFrame.payloadBytes .. frame.payloadBytes
end

function FrameHandler:handleFinalContinuationFrame(frame: Frame, register: ServerClientRegister)
    print("FINAL CONTINUATION FRAME.")
    local finishedFrame = self.unfinishedFrame
    self.unfinishedFrame = nil
    finishedFrame.payloadBytes = finishedFrame.payloadBytes .. frame.payloadBytes
    finishedFrame.fin = true
    self:handleFrame(finishedFrame, register)
end

function FrameHandler:onTextFrameParsed(frame: Frame, _: ServerClientRegister)
    print("TEXT FRAME. CONTENT:\n"..frame.stringContent)
end

function FrameHandler:handleUnfinishedTextFrame(frame: Frame, _: ServerClientRegister)
    print("UNFINISHED TEXT FRAME.")
    self.unfinishedFrame = frame
end

function FrameHandler:handleFinalTextFrame(frame: Frame, register: ServerClientRegister)
    frame:parseContentAsString()
    self:onTextFrameParsed(frame, register)
end

function FrameHandler:onBinaryFrameParsed(frame: Frame, _: ServerClientRegister)
    local printText = "Binary FRAME. CONTENT:\n"
    for _, byte in ipairs(frame.binaryContent) do
        printText = printText .. tostring(byte//16) .. tostring(byte%16) .. " "
    end
    print(printText)
end

function FrameHandler:handleUnfinishedBinaryFrame(frame: Frame, _: ServerClientRegister)
    print("UNFINISHED BINARY FRAME.")
    self.unfinishedFrame = frame
end

function FrameHandler:handleFinalBinaryFrame(frame: Frame, register: ServerClientRegister)
    frame:parseContentAsBinary()
    self:onBinaryFrameParsed(frame, register)
end

function FrameHandler:handleCloseFrame(frame: Frame, register: ServerClientRegister)
    -- TODO
    print("CLOSE FRAME.")
end

function FrameHandler:handlePingFrame(frame: Frame, register: ServerClientRegister)
    -- TODO
    print("PING FRAME.")
end

function FrameHandler:handlePongFrame(frame: Frame, register: ServerClientRegister)
    -- TODO
    print("PONG FRAME.")
end

function FrameHandler:handleUnknownFrameType(frame: Frame, register: ServerClientRegister)
    print("UNKNOWN FRAME OPCODE: "..tonumber(frame.opcode))
end

function FrameHandler:handleFrame(frame: Frame, register: ServerClientRegister)
    local methodToCall = self.optable[frame.opcode]
    if (methodToCall == nil) then
        self:handleUnknownFrameType(frame, register)
    else
        methodToCall(self, frame, register)
    end
end

function FrameHandler:new(instance: FrameHandler): FrameHandler
    local newInstance = instance or {}
    setmetatable(newInstance, {__index = FrameHandler})
    newInstance.optable = newInstance.optable or {
        [0] = function(self: FrameHandler, frame: Frame, register: ServerClientRegister)
            if (frame.fin) then
                self:handleFinalContinuationFrame(frame, register)
            else
                self:handleUnfinishedContinuationFrame(frame, register)
            end
        end,
        [1] = function(self: FrameHandler, frame: Frame, register: ServerClientRegister)
            if (frame.fin) then
                self:handleFinalTextFrame(frame, register)
            else
                self:handleUnfinishedTextFrame(frame, register)
            end
        end,
        [2] = function(self: FrameHandler, frame: Frame, register: ServerClientRegister)
            if (frame.fin) then
                self:handleFinalContinuationFrame(frame, register)
            else
                self:handleUnfinishedContinuationFrame(frame, register)
            end
        end,
        [8] = function(self: FrameHandler, frame: Frame, register: ServerClientRegister) self:handleCloseFrame(frame, register) end,
        [9] = function(self: FrameHandler, frame: Frame, register: ServerClientRegister) self:handlePingFrame(frame, register) end,
        [10] = function(self: FrameHandler, frame: Frame, register: ServerClientRegister) self:handlePongFrame(frame, register) end
    }
    return newInstance
end

return FrameHandler