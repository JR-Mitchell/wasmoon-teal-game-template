local record luasocket
    record Client
        settimeout: function(self: Client, time: integer, mode: string)
        receive: function(self: Client, amount: any): string, string
        setoption: function(self: Client, key: string, value: any)
        getfd: function(self: Client): string
        getstats: function(self: Client): any
        getpeername: function(self: Client): string
        close: function(self: Client)
    end

    record Server
        getsockname: function(self: Server): string, string
        accept: function(self: Server): Client, string
        settimeout: function(self: Server, time: integer)
    end

    bind: function(address: string, port: string): Server
    select: function(recvt: {any}, sendt: {Client}, timeout: integer): {any}, {Client}, string
end

return luasocket