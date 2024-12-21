local function copyFile(source: string, destination: string)
    local inFile, readError = io.open(source, "rb")
    if (readError) then error(readError) end
    local content = inFile:read("*a")
    inFile:close()
    local outFile, writeError = io.open(destination, "wb")
    if (writeError) then error(writeError) end
    outFile:write(content)
    outFile:close()
end

local function copyFileToAssets(filename: string)
    copyFile("src/assets/"..filename, "dist/assets/"..filename)
end

require("init")
for _, filename in ipairs(config.imageFilenames) do
    copyFileToAssets(filename)
end

for _, filename in ipairs(config.luaFilenames) do
    copyFileToAssets(filename)
end

-- Needed to initialise client-side
copyFileToAssets("init.lua")

-- Icon for the webpage; not actually used in the game
copyFileToAssets("icon.png")