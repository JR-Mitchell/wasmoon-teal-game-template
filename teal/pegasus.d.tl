local type socket = require("socket")

local record Pegasus
    location: string
    host: string
    port: string
    timeout: integer
    plugins: {Pegasus.Plugin}
    log: any

    record Options
        host: string
        port: string
        location: string
        plugins: {Plugin}
        timeout: integer
        log: any
    end

    new: function(self: Pegasus, options: Options): Server

    record Server
        start: function(self: Server)
    end

    record Request
        client: socket.Client
        method: function(self: Request): string
        path: function(self: Request): string
        headers: function(self: Request): {string:string}
    end

    record Response
        redirect: function(self: Response, url: string)
        write: function(self: Response, body: string, stayOpen: boolean)
        addHeader: function(self: Response, key: string, value: string)
        addHeaders: function(self: Response, headers: {string:string})
        statusCode: function(self: Response, statusCode: integer, statusText: string)
        sendHeaders: function(self: Response, stayOpen: boolean, body: string)
    end

    record Plugin
        newRequestResponse: function(self: Plugin, request: Request, response: Response): boolean
    end
end

return Pegasus