global type Config = record
    imageFilenames: {string}
    luaFilenames: {string}
    blankColour: string
    displayWidth: integer
    displayHeight: integer
    pageBackgroundColour: string
    entryPoint: string
end

global record Canvas
    clearCanvas: function()
    drawImage: function(path: string, sx: number, sy: number, sw: number, sh: number, dx: number, dy: number, dw: number, dh: number)
end