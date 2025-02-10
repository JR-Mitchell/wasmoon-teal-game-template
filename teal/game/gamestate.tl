local interface IGame
    keyStates: {string:boolean}
    socketSend: function(message: string)
    changeState: function(gameState: IGameState)
end

local interface IGameState
    step: function(self: self, dt: number, game: IGame)
    draw: function(self: self)
    keyUp: function(self: self, key: string)
    keyDown: function(self: self, key: string)
    keyPress: function(self: self, key: string)
    onClick: function(self: self, x: number, y: number, game: IGame)
    onPointerUp: function(self: self, x: number, y: number)
    onPointerDown: function(self: self, x: number, y: number)
    websocketMessage: function(self: self, message: string, game: IGame)
    websocketClosed: function(self: self, game: IGame)
end

return {
    IGame = IGame,
    IGameState = IGameState
}