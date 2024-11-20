global record Game
    keyStates: {string:boolean}
    speed: number
    spriteIndex: integer
    x: number
    y: number
    step: function(self: Game, dt: number)
    draw: function(self: Game)
    keyUp: function(self: Game, key: string)
    keyDown: function(self: Game, key: string)
    keyPress: function(self: Game, key: string)
end

Game.keyStates = {}
Game.speed = 0.5
Game.spriteIndex = 0
Game.x = 300
Game.y = 400

Game.step = function(self: Game, dt: number)
    if (self.keyStates["w"] and not self.keyStates["s"]) then
        self.y = self.y - self.speed * dt
    end
    if (self.keyStates["a"] and not self.keyStates["d"]) then
        self.spriteIndex = 0
        self.x = self.x - self.speed * dt
    end
    if (self.keyStates["s"] and not self.keyStates["w"]) then
        self.y = self.y + self.speed * dt
    end
    if (self.keyStates["d"] and not self.keyStates["a"]) then
        self.spriteIndex = 1
        self.x = self.x + self.speed * dt
    end
end

Game.draw = function(self: Game)
    Canvas.clearCanvas()
    Canvas.drawImage("guy.png", self.spriteIndex * 64, 0, 64, 64, self.x, self.y, 64, 64)
end

Game.keyUp = function(self: Game, key: string)
    self.keyStates[key] = false
end

Game.keyPress = function(self: Game, key: string)
    self.keyStates[key] = true
end