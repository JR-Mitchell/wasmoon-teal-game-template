local type Frame = require("server.frame")

local record FrameHandler
    unfinishedFrame: Frame
    optable: {integer: function(FrameHandler, Frame)}
    handleFrame: function(self: FrameHandler, frame: Frame)
end

function FrameHandler:handleUnfinishedContinuationFrame(frame: Frame)
    print("CONTINUATION FRAME.")
    self.unfinishedFrame.content = self.unfinishedFrame.content .. frame.content
end

function FrameHandler:handleFinalContinuationFrame(frame: Frame)
    print("FINAL CONTINUATION FRAME.")
    local finishedFrame = self.unfinishedFrame
    self.unfinishedFrame = nil
    finishedFrame.content = finishedFrame.content .. frame.content
    finishedFrame.fin = true
    self:handleFrame(finishedFrame)
end

function FrameHandler:handleUnfinishedTextFrame(frame: Frame)
    print("UNFINISHED TEXT FRAME.")
    self.unfinishedFrame = frame
end

function FrameHandler:handleFinalTextFrame(frame: Frame)
    print("TEXT FRAME. CONTENT:\n"..frame.content)
end

function FrameHandler:handleUnfinishedBinaryFrame(frame: Frame)
    print("UNFINISHED BINARY FRAME.")
    self.unfinishedFrame = frame
end

function FrameHandler:handleFinalBinaryFrame(frame: Frame)
    -- TODO
    print("BINARY FRAME.")
end

function FrameHandler:handleCloseFrame(frame: Frame)
    -- TODO
    print("CLOSE FRAME.")
end

function FrameHandler:handlePingFrame(frame: Frame)
    -- TODO
    print("PING FRAME.")
end

function FrameHandler:handlePongFrame(frame: Frame)
    -- TODO
    print("PONG FRAME.")
end

function FrameHandler:handleUnknownFrameType(frame: Frame)
    -- TODO
    print("UNKNOWN FRAME OPCODE: "..tonumber(frame.opcode))
end

function FrameHandler:handleFrame(frame: Frame)
    local methodToCall = self.optable[frame.opcode]
    if (methodToCall == nil) then
        self:handleUnknownFrameType(frame)
    else
        methodToCall(self, frame)
    end
end

function FrameHandler:new(instance: FrameHandler): FrameHandler
    local newInstance = instance or {}
    setmetatable(newInstance, {__index = FrameHandler})
    newInstance.optable = newInstance.optable or {
        [0] = function(self: FrameHandler, frame: Frame)
            if (frame.fin) then
                self:handleFinalContinuationFrame(frame)
            else
                self:handleUnfinishedContinuationFrame(frame)
            end
        end,
        [1] = function(self: FrameHandler, frame: Frame)
            if (frame.fin) then
                self:handleFinalTextFrame(frame)
            else
                self:handleUnfinishedTextFrame(frame)
            end
        end,
        [2] = function(self: FrameHandler, frame: Frame)
            if (frame.fin) then
                self:handleFinalContinuationFrame(frame)
            else
                self:handleUnfinishedContinuationFrame(frame)
            end
        end,
        [8] = function(self: FrameHandler, frame: Frame) self:handleCloseFrame(frame) end,
        [9] = function(self: FrameHandler, frame: Frame) self:handleCloseFrame(frame) end,
        [10] = function(self: FrameHandler, frame: Frame) self:handleCloseFrame(frame) end
    }
    return newInstance
end

return FrameHandler