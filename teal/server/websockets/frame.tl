local type socket = require("socket")
local type SendableFrame = require("server.websockets.sendableFrame")
local type ContainedError = require("containederror")

local record Frame
    fin: boolean
    rsv: {boolean}
    opcode: integer
    masked: boolean
    length: integer
    mask: {integer}
    payloadBytes: string
    stringContent: string
    binaryContent: {integer}
end

local FrameMetatable: metatable<Frame> = {
    __index = Frame
}

local powerTwoTable <const> = {
    [0] = 1,
    [1] = 2,
    [2] = 4,
    [3] = 8,
    [4] = 16,
    [5] = 32,
    [6] = 64,
    [7] = 128
}

local function sendError(errorString: string)
    local contained: ContainedError = {
        message = errorString
    }
    error(contained)
end

function Frame:setFirstByte(byte: integer)
    self.fin = (byte & powerTwoTable[7]) == powerTwoTable[7]
    self.rsv = {}
    for i=6,4,-1 do
        local mask = powerTwoTable[i]
        local value = (byte & mask) == mask
        table.insert(self.rsv, value)
    end
    self.opcode = byte % powerTwoTable[4]
end

function Frame:setMaskedAndLength(byte: integer, client: socket.Client)
    self.masked = (byte & powerTwoTable[7]) == powerTwoTable[7]
    self.length = byte % powerTwoTable[7]
    if (self.length == 126) then
        local nextTwoBytes, errorMessage = client:receive(2)
        if (errorMessage ~= nil) then sendError(errorMessage) end
        self.length = string.byte(nextTwoBytes, 1) + 256 * string.byte(nextTwoBytes, 2)
    elseif (self.length == 127) then
        local nextFourBytes, errorMessage = client:receive(4)
        if (errorMessage ~= nil) then sendError(errorMessage) end
        self.length = string.byte(nextFourBytes, 1) + 256 * (string.byte(nextFourBytes, 2) + 256 * (string.byte(nextFourBytes, 3) + 256 * string.byte(nextFourBytes, 4)))
    end
end

function Frame:setMask(message: string)
    self.mask = {}
    for i=1,4 do
        table.insert(self.mask, string.byte(message, i))
    end
end

function Frame:parseContentAsString()
    if (self.stringContent == nil) then
        self.stringContent = ""
    end
    for i=1,self.length do
        local byte = string.byte(self.payloadBytes, i)
        if (byte ~= nil) then
            if (self.masked) then
                byte = byte ~ self.mask[((i - 1) % 4) + 1]
            end
            self.stringContent = self.stringContent .. string.char(byte)
        end
    end
end

function Frame:parseContentAsBinary()
    if (self.binaryContent == nil) then
        self.binaryContent = {}
    end
    for i=1,self.length do
        local byte = string.byte(self.payloadBytes, i)
        if (byte ~= nil) then
            if (self.masked) then
                byte = byte ~ self.mask[((i - 1) % 4) + 1]
            end
            table.insert(self.binaryContent, byte)
        end
    end
end

function Frame:readNext(client: socket.Client): Frame
    local instance: Frame = {}
    setmetatable(instance, FrameMetatable)
    local firstTwoBytes, firstErrorMessage = client:receive(2)
    if (firstErrorMessage ~= nil) then sendError(firstErrorMessage) end
    instance:setFirstByte(string.byte(firstTwoBytes, 1))
    instance:setMaskedAndLength(string.byte(firstTwoBytes, 2), client)
    local remainingByteCount = instance.length
    if (instance.masked) then
        remainingByteCount = remainingByteCount + 4
    end
    local remainingBytes, secondErrorMessage = client:receive(remainingByteCount)
    if (secondErrorMessage ~= nil) then sendError(secondErrorMessage) end
    local contentIndex = 1
    if (instance.masked) then
        instance:setMask(remainingBytes)
        contentIndex = 5
    end
    instance.payloadBytes = string.sub(remainingBytes, contentIndex)
    return instance
end

function Frame:newPingFrame(payloadBytes: string): Frame
    local instance: Frame = {}
    setmetatable(instance, FrameMetatable)
    instance.fin = true
    instance.rsv = {false, false, false}
    instance.opcode = 9
    instance.masked = false
    instance.payloadBytes = payloadBytes or ""
    instance.length = string.len(instance.payloadBytes)
    return instance
end

function Frame:newPongFrame(payloadBytes: string): Frame
    local instance: Frame = {}
    setmetatable(instance, FrameMetatable)
    instance.fin = true
    instance.rsv = {false, false, false}
    instance.opcode = 10
    instance.masked = false
    instance.length = string.len(payloadBytes)
    instance.payloadBytes = payloadBytes
    return instance
end

function Frame:newTextFrame(payloadBytes: string): Frame
    local instance: Frame = {}
    setmetatable(instance, FrameMetatable)
    instance.fin = true
    instance.rsv = {false, false, false}
    instance.opcode = 1
    instance.masked = false
    instance.length = string.len(payloadBytes)
    instance.payloadBytes = payloadBytes
    return instance
end

function Frame:newCloseFrame(): Frame
    local instance: Frame = {}
    setmetatable(instance, FrameMetatable)
    instance.fin = true
    instance.rsv = {false, false, false}
    instance.opcode = 8
    instance.masked = false
    instance.length = 0
    instance.payloadBytes = ""
    return instance
end

function Frame:getSendable(): SendableFrame
    local firstByte = self.opcode
    for i=6,4,-1 do
        if (self.rsv[7-i]) then
            firstByte = firstByte + powerTwoTable[i]
        end
    end
    if (self.fin) then
        firstByte = firstByte + powerTwoTable[7]
    end
    local secondByte = self.length
    if (self.length > 65535) then
        secondByte = 127
    elseif (self.length > 126) then
        secondByte = 126
    end
    if (self.masked) then
        secondByte = secondByte + powerTwoTable[7]
    end
    local binaryString = string.char(firstByte) .. string.char(secondByte)
    if (self.length > 65535) then
        binaryString = binaryString .. string.char(self.length % 256) .. string.char((self.length // 256) % 256) .. string.char((self.length // (256*256)) % 256) .. string.char(self.length // (256*256*256))
    elseif (self.length > 126) then
        binaryString = binaryString .. string.char(self.length % 256) .. string.char(self.length // 256)
    end
    if (self.masked) then
        for i=1,4 do
            binaryString = binaryString .. string.char(self.mask[i])
        end
    end
    binaryString = binaryString .. self.payloadBytes
    return binaryString
end

return Frame