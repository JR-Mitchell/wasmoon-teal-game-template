local Pegasus = require('pegasus')
local Files = require('pegasus.plugins.files')
local Websocket = require('server.websocket')
local mimetypes = require('mimetypes')

-- Patch the mimetypes.guess function to handle wasm
local super = mimetypes.guess
mimetypes.guess = function(filename: string): string
    if (string.find(filename, ".+%.wasm")) then
        return "application/wasm"
    end
    return super(filename)
end

local server = Pegasus:new({
    port = "8080",
    location = "dist/",
    plugins = {
        Websocket:new("/websocket"):getPlugin(),
        Files:new({
            location = "./",
            default = "index.html"
        })
    }
})

server:start()