local subprotocol = require("shared.subprotocol")
local Background = require("game.background")

global record Game
    keyStates: {string:boolean}
    speed: number
    background: Background
    spriteCanvas: Canvas.SubCanvas
    spriteIndex: integer
    prevSpriteIndex: integer
    x: number
    y: number
    socketOpen: boolean
    step: function(dt: number)
    draw: function()
    keyUp: function(key: string)
    keyDown: function(key: string)
    keyPress: function(key: string)
end

Game.keyStates = {}
Game.speed = 0.5
Game.spriteIndex = 0
Game.x = 300
Game.y = 400
Game.socketOpen = false

function Game.init()
    Socket.open(subprotocol)
    Game.spriteCanvas = Canvas.newCanvas(true)
    Game.background = Background.new()
end

function Game.step(dt: number)
    local prevX = Game.x
    local prevY = Game.y
    if (Game.keyStates["w"] and not Game.keyStates["s"]) then
        Game.y = Game.y - Game.speed * dt
    end
    if (Game.keyStates["a"] and not Game.keyStates["d"]) then
        Game.spriteIndex = 0
        Game.x = Game.x - Game.speed * dt
    end
    if (Game.keyStates["s"] and not Game.keyStates["w"]) then
        Game.y = Game.y + Game.speed * dt
    end
    if (Game.keyStates["d"] and not Game.keyStates["a"]) then
        Game.spriteIndex = 1
        Game.x = Game.x + Game.speed * dt
    end
    if (Game.socketOpen and (Game.x ~= prevX or Game.y ~= prevY)) then
        Socket.send("Position updated: x="..tostring(Game.x)..", y="..tostring(Game.y))
    end
end

function Game.draw()
    if (Game.spriteIndex ~= Game.prevSpriteIndex) then
        Game.spriteCanvas.clearCanvas()
        Game.spriteCanvas.drawImage("guy.png", Game.spriteIndex * 64, 0, 64, 64, 0, 0, 64, 64)
        Game.prevSpriteIndex = Game.spriteIndex
    end
    Game.background:draw()
    Game.spriteCanvas.draw(Game.x, Game.y)
end

function Game.keyUp(key: string)
    Game.keyStates[key] = false
end

function Game.keyPress(key: string)
    Game.keyStates[key] = true
end

function Game.websocketOpened()
    Socket.send("Hello World!")
    Game.socketOpen = true
end

function Game.websocketClosed(code: integer, reason: string)
    print("Websocket closed with code "..code..", reason: "..tostring(reason))
    Game.socketOpen = false
end

function Game.websocketMessage(message: string)
    print(message)
    local _, _, x, y = string.find(message, "Position updated: x=(%d+%.?%d*), y=(%d+%.?%d*)")
    print(x)
    print(y)
    if (x and y) then
        Game.x = tonumber(x)
        Game.y = tonumber(y)
    end
end

function Game.onClick(x: number, y: number)
    Game.x = x - 32 -- account for sprite width
    Game.y = y - 32
    Socket.send("Position updated: x="..tostring(Game.x)..", y="..tostring(Game.y))
end