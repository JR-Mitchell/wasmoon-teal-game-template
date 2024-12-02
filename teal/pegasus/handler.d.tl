local Pegasus = require('pegasus')
local type socket = require("socket")

local record Handler
    new: function(self: Handler, callback: any, location: string, plugins: {Pegasus.Plugin}, logger: any): Handler
    processRequest: function(self: Handler, request: string, client: socket.Client, server: socket.Server)
    log: any
end

return Handler