import wasmFile from 'wasmoon/dist/glue.wasm';
import { LuaFactory } from 'wasmoon';

// Get the canvas to draw on
const canvasElement = document.getElementById("canvas");
const canvas = canvasElement.getContext('2d');

// Create a new factory
const factory = new LuaFactory(wasmFile);

// Stored properties
const initFilename = "init.lua"
var blankColour = "white"
var imageMap = new Map();

function prefetchImage(path) {
    async function fetchFile() {
        const url = require("./assets/"+path);
        let blob = await fetch(url).then(r => r.blob());
        const bmp = await createImageBitmap(blob);
        imageMap.set(path, bmp);
    };

    return fetchFile();
};

function prefetchLuaFile(path) {
    async function fetchFile() {
        const rawText = require("./assets/"+path);
        await factory.mountFile(path, rawText);
    };

    return fetchFile();
};

async function initialise(config) {
    const prefetchArray = new Array();
    config.imageFilenames.forEach(name => {
        const promise = prefetchImage(name);
        prefetchArray.push(promise);
    });
    config.luaFilenames.forEach(name => {
        const promise = prefetchLuaFile(name);
        prefetchArray.push(promise);
    });
    canvasElement.width = config.displayWidth;
    canvasElement.height = config.displayHeight;
    blankColour = config.blankColour;
    document.getElementById("background").style.backgroundColor = config.pageBackgroundColour;
    await Promise.all(prefetchArray);
};

// Interface enabling Lua to draw to canvas
const CanvasCalls = {
    clearCanvas: function() {
        canvas.clearRect(0, 0, canvasElement.width, canvasElement.height);
        canvas.fillStyle = blankColour;
        canvas.fillRect(0, 0, canvasElement.width, canvasElement.height);
    },

    drawImage: function(path, sx, sy, sw, sh, dx, dy, dw, dh) {
        if (imageMap.has(path)) {
            const bmp = imageMap.get(path);
            canvas.drawImage(bmp, sx, sy, sw, sh, dx, dy, dw, dh);
        }
    }
};

function startGameLoop(game, lua) {
    let previousTime = Date.now();
    function loop() {
        try {
            const now = Date.now();
            game.step(game, now - previousTime);
            game.draw(game);
            previousTime = now;
            window.requestAnimationFrame(loop);
        } catch (e) {
            console.log(e);
            lua.global.close();
        }
    };

    loop();
};

async function execute() {
    // Create the lua environment
    const lua = await factory.createEngine();

    try {
        // First load the init file
        await prefetchLuaFile(initFilename);
        // Then execute it
        await lua.doFile(initFilename);
        // Get the game config
        const config = lua.global.get("config");
        // Initialise
        await initialise(config);

        // Set up canvas
        lua.global.set("Canvas", CanvasCalls);

        // Run the main file
        await lua.doFile(config.entryPoint);

        // Get the game hook
        const game = lua.global.get("Game");

        // Set up any listeners
        if (game["keyUp"] != undefined) {
            document.addEventListener('keyup', (event) => {
                game.keyUp(game, event.key);
            });
        }

        if (game["keyDown"] != undefined) {
            document.addEventListener('keydown', (event) => {
                game.keyDown(game, event.key);
            });
        }

        if (game["keyPress"] != undefined) {
            document.addEventListener('keypress', (event) => {
                game.keyPress(game, event.key);
            });
        }

        // Start the game loop
        startGameLoop(game, lua)
    } catch (e) {
        console.log(e);
        lua.global.close();
    }
};

execute();