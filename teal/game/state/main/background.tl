local record Background
    canvas: Canvas.SubCanvas
end

local BackgroundMetatable: metatable<Background> = {
    __index = Background
}

function Background:draw()
    self.canvas.draw(0, 0)
end

function Background.new(): Background
    local instance: Background = {}
    setmetatable(instance, BackgroundMetatable)
    instance.canvas = Canvas.newCanvas(false)
    instance.canvas.drawImage("block.png", 0, 0, 64, 64, 0, 888, 64, 64)
    instance.canvas.drawImage("block.png", 0, 0, 64, 64, 0, 952, 64, 64)
    instance.canvas.drawImage("block.png", 0, 0, 64, 64, 0, 1016, 64, 64)
    instance.canvas.drawImage("block.png", 0, 0, 64, 64, 64, 1016, 64, 64)
    instance.canvas.drawImage("block.png", 0, 0, 64, 64, 1856, 1016, 64, 64)
    return instance
end

return Background