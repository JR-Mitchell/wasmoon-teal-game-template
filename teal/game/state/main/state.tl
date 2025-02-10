local type IGame = require("game.igame")
local type IGameState = require("game.igamestate")
local GameStateMetatable = require("game.gamestatemetatable")
local Background = require("game.state.main.background")
local Character = require("game.state.main.character")

local record MainState is IGameState
    background: Background
    character: Character
end

setmetatable(MainState, GameStateMetatable)

local MainStateMetatable: metatable<MainState> = {
    __index = MainState
}

function MainState.new(): MainState
    local instance: MainState = {}
    setmetatable(instance, MainStateMetatable)
    instance.background = Background.new()
    instance.character = Character.new()
    return instance
end

function MainState:step(dt: number, game: IGame)
    self.character:step(dt, game)
end

function MainState:draw() 
    self.background:draw()
    self.character:draw()
end

function MainState:websocketMessage(message: string, _: IGame)
    local _, _, x, y = string.find(message, "Position updated: x=(%d+%.?%d*), y=(%d+%.?%d*)")
    if (x and y) then
        print("From Lua: "..message)
        self.character:updatePosition(tonumber(x), tonumber(y))
    end
end

function MainState:onClick(x: number, y: number, game: IGame)
    -- The -32 accounts for sprite width
    self.character:updatePosition(x - 32, y - 32)
    game.socketSend("Position updated: x="..tostring(self.character.x)..", y="..tostring(self.character.y))
end

return MainState