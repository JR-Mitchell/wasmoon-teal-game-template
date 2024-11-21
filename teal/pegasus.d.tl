local record Pegasus
    new: function(self: Pegasus, options: any): Server

    record Server
        start: function(self: Server)
    end
end

return Pegasus