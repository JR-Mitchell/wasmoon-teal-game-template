print("Started initialising...")
global config: Config = {
    imageFilenames = {
        "guy.png"
    },
    luaFilenames = {
        "main.lua"
    },
    blankColour = "black",
    pageBackgroundColour = "powderblue",
    displayWidth = 1920,
    displayHeight = 1080,
    entryPoint = "main.lua"
}
Socket.open()
print("Completed initialising...")