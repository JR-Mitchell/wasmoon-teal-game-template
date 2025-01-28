print("Started initialising...")
global config: Config = {
    imageFilenames = {
        "guy.png",
        "block.png"
    },
    luaFilenames = {
        "game/main.lua",
        "game/gamestatemetatable.lua",
        "game/state/main/background.lua",
        "game/state/main/character.lua",
        "game/state/main/state.lua",
        "shared/subprotocol.lua"
    },
    blankColour = "black",
    pageBackgroundColour = "powderblue",
    displayWidth = 1920,
    displayHeight = 1080,
    entryPoint = "game/main.lua"
}
print("Completed initialising...")