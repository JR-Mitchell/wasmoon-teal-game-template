local record Character
    canvas: Canvas.SubCanvas
    spriteIndex: integer
    prevSpriteIndex: integer
    x: number
    y: number
    speed: number
end

local CharacterMetatable: metatable<Character> = {
    __index = Character,
 }

function Character.new(): Character
    local instance: Character = {}
    setmetatable(instance, CharacterMetatable)    
    instance.speed = 0.5
    instance.spriteIndex = 0
    instance.x = 300
    instance.y = 400
    instance.canvas = Canvas.newCanvas(true)
    return instance
end

function Character:step(dt: number, keyStates: {string:boolean}, socketSend: function(string))
    local prevX = self.x
    local prevY = self.y
    if (keyStates["w"] and not keyStates["s"]) then
        self.y = self.y - self.speed * dt
    end
    if (keyStates["a"] and not keyStates["d"]) then
        self.spriteIndex = 0
        self.x = self.x - self.speed * dt
    end
    if (keyStates["s"] and not keyStates["w"]) then
        self.y = self.y + self.speed * dt
    end
    if (keyStates["d"] and not keyStates["a"]) then
        self.spriteIndex = 1
        self.x = self.x + self.speed * dt
    end
    if (self.x ~= prevX or self.y ~= prevY) then
        socketSend("Position updated: x="..tostring(self.x)..", y="..tostring(self.y))
    end
end

function Character:draw()
    if (self.spriteIndex ~= self.prevSpriteIndex) then
        self.canvas.clearCanvas()
        self.canvas.drawImage("guy.png", self.spriteIndex * 64, 0, 64, 64, 0, 0, 64, 64)
        self.prevSpriteIndex = self.spriteIndex
    end
    self.canvas.draw(self.x, self.y)
end

function Character:updatePosition(x: number, y: number)
    self.x = x
    self.y = y
end

return Character