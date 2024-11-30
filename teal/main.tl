global record Game
    keyStates: {string:boolean}
    speed: number
    spriteIndex: integer
    x: number
    y: number
    socketOpen: boolean
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
Game.socketOpen = false

Game.step = function(self: Game, dt: number)
    local prevX = self.x
    local prevY = self.y
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
    if (self.socketOpen and (self.x ~= prevX or self.y ~= prevY)) then
        Socket.send("Position updated: x="..tostring(self.x)..", y="..tostring(self.y))
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

function Game:websocketOpened()
    Socket.send("Hello World!")
    self.socketOpen = true
end

function Game:websocketClosed(code: integer, reason: string)
    print("Websocket closed with code "..code..", reason: "..tostring(reason))
    self.socketOpen = false
end

function Game:websocketMessage(message: string)
    print(message)
    local _, _, x, y = string.find(message, "Position updated: x=(%d+%.?%d*), y=(%d+%.?%d*)")
    print(x)
    print(y)
    if (x and y) then
        self.x = tonumber(x)
        self.y = tonumber(y)
    end
end