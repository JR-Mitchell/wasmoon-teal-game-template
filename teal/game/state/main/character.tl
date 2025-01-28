local type IGame = require("game.igame")

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

function Character:step(dt: number, game: IGame)
    local prevX = self.x
    local prevY = self.y
    if (game.keyStates["w"] and not game.keyStates["s"]) then
        self.y = self.y - self.speed * dt
    end
    if (game.keyStates["a"] and not game.keyStates["d"]) then
        self.spriteIndex = 0
        self.x = self.x - self.speed * dt
    end
    if (game.keyStates["s"] and not game.keyStates["w"]) then
        self.y = self.y + self.speed * dt
    end
    if (game.keyStates["d"] and not game.keyStates["a"]) then
        self.spriteIndex = 1
        self.x = self.x + self.speed * dt
    end
    if (self.x ~= prevX or self.y ~= prevY) then
        game.socketSend("Position updated: x="..tostring(self.x)..", y="..tostring(self.y))
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