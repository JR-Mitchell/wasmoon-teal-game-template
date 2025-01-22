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
    record SubCanvas
        draw: function(x: number, y: number)
        drawImage: function(path: string, sx: number, sy: number, sw: number, sh: number, dx: number, dy: number, dw: number, dh: number)
        clearCanvas: function()
    end

    newCanvas: function(transparent: boolean): SubCanvas
end

global record Socket
    open: function(subprotocol: string)
    send: function(data: string)
    close: function()
end