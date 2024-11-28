local record Frame
    fin: boolean
    rsv: {boolean}
    opcode: integer
    masked: boolean
    length: integer
    mask: {integer}
    content: string
end

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

function Frame:setFirstByte(message: string, index: integer): integer
    local byte = string.byte(message, index)
    self.fin = (byte & powerTwoTable[7]) == powerTwoTable[7]
    self.rsv = {}
    for i=6,4,-1 do
        local mask = powerTwoTable[i]
        local value = (byte & mask) == mask
        table.insert(self.rsv, value)
    end
    self.opcode = byte % powerTwoTable[4]
    return index + 1
end

function Frame:setMaskedAndLength(message: string, index: integer): integer
    local firstByte = string.byte(message, index)
    self.masked = (firstByte & powerTwoTable[7]) == powerTwoTable[7]
    self.length = firstByte % powerTwoTable[7]
    if (self.length < 126) then
        return index + 1
    elseif (self.length == 126) then
        self.length = string.byte(message, index + 1) + 256 * string.byte(message, index + 2)
        return index + 3
    else
        -- Must be 127
        self.length = string.byte(message, index + 1) + 256 * (string.byte(message, index + 2) + 256 * (string.byte(message, index + 3) + 256 * string.byte(message, index + 4)))
        return index + 5
    end
end

function Frame:setMask(message: string, index: integer): integer
    self.mask = {}
    for i=index,index+3 do
        table.insert(self.mask, string.byte(message, i))
    end
    return index + 4
end

function Frame:readContent(message: string, index: integer): integer
    self.content = ""
    for i=index,index+self.length-1 do
        local byte = string.byte(message, i)
        if (byte ~= nil) then
            if (self.masked) then
                byte = byte ~ self.mask[((i - index) % 4) + 1]
            end
            self.content = self.content .. string.char(byte)
        end
    end
end

function Frame:parse(message: string): Frame
    local index = 1
    local instance: Frame = {}
    setmetatable(instance, {__index=Frame})
    index = instance:setFirstByte(message, index)
    index = instance:setMaskedAndLength(message, index)
    if (instance.masked) then
        index = instance:setMask(message, index)
    end
    index = instance:readContent(message, index)

    return instance
end

function Frame:maskString(): string
    return "{" .. tostring(self.mask[1]) .. "," .. tostring(self.mask[2]) .. "," .. tostring(self.mask[3]) .. "," .. tostring(self.mask[4]) .. "}"
end

function Frame:string(): string
    return "FIN: "..tostring(self.fin)..", OPCODE: "..self.opcode..", MASKED: "..tostring(self.masked)..", LENGTH: "..tostring(self.length).."\nMASK: "..self:maskString().."\nCONTENT:\n"..self.content
end

return Frame