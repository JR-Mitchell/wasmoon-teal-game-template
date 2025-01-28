local subprotocol = require("shared.subprotocol")
local type IGame = require("game.igame")
local type IGameState = require("game.igamestate")
local MainState = require("game.state.main.state")

global record Game is IGame
    keyStates: {string:boolean}
    socketOpen: boolean
    currentState: IGameState
end

Game.keyStates = {}
Game.socketOpen = false

function Game.init()
    Socket.open(subprotocol)
    Game.currentState = MainState.new()
end

function Game.socketSend(message: string)
    if (Game.socketOpen) then
        Socket.send(message)
    end
end

function Game.step(dt: number)
    Game.currentState:step(dt, Game)
end

function Game.draw()
    Game.currentState:draw()
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
    Game.currentState:websocketMessage(message, Game)
end

function Game.onClick(x: number, y: number)
    Game.currentState:onClick(x, y, Game)
end

function Game.onPointerDown(x: number, y: number)
    Game.currentState:onPointerDown(x, y)
end

function Game.onPointerUp(x: number, y: number)
    Game.currentState:onPointerUp(x, y)
end