local type IGame = require("game.igame")
local type IGameState = require("game.igamestate")

-- Base state with no-op definitions to ensure non-implemented methods can be called safely
local record BaseState is IGameState
end

function BaseState:step(_: number, _: IGame) end
function BaseState:draw() end
function BaseState:keyUp(_: string) end
function BaseState:keyDown(_: string) end
function BaseState:keyPress(_: string) end
function BaseState:onClick(_: number, _: number, _: IGame) end
function BaseState:onPointerUp(_: number, _: number) end
function BaseState:onPointerDown(_: number, _: number) end
function BaseState:websocketMessage(_: string, _: IGame) end
function BaseState:websocketClosed(_: IGame) end

local GameStateMetatable: metatable<IGameState> = {
    __index = BaseState
}

return GameStateMetatable