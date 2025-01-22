print("Started initialising...")
global config: Config = {
    imageFilenames = {
        "guy.png"
    },
    luaFilenames = {
        "game/main.lua",
        "shared/subprotocol.lua"
    },
    blankColour = "black",
    pageBackgroundColour = "powderblue",
    displayWidth = 1920,
    displayHeight = 1080,
    entryPoint = "game/main.lua"
}
print("Completed initialising...")