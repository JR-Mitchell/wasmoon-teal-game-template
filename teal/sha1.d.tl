local record sha1
    sha1: function(input: string): string
    binary: function(input: string): string
    hmac: function(key: string, message: string): string
    hmac_binary: function(key: string, message: string): string
end

return sha1