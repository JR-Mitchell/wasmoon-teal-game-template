global record Initialisation
    prefetchImage: function(path: string)
    prefetchLuaFile: function(path: string)
    setBlankColour: function(colour: string)
    setMainFile: function(path: string)
end

global record Canvas
    clearCanvas: function()
    drawImage: function(path: string, sx: number, sy: number, sw: number, sh: number, dx: number, dy: number, dw: number, dh: number)
end