import wasmFile from 'wasmoon/dist/glue.wasm';
import { LuaFactory } from 'wasmoon';

// Get the canvas to draw on
const canvasElement = document.getElementById("canvas");
const canvas = canvasElement.getContext('2d');

// Create a new factory
const factory = new LuaFactory(wasmFile);

// Used for storing the result of initialisation
const setupCache = {
    imageMap: new Map(),
    prefetchArray: new Array(),
    blankColour: "white",
    initFilename: "init.lua",
    mainFilename: ""
};

// Interface enabling lua to initialise
const InitialisationCalls = {
    prefetchImage: function(path) {
        async function fetchFile() {
            const url = require("./assets/"+path);
            let blob = await fetch(url).then(r => r.blob());
            const bmp = await createImageBitmap(blob);
            setupCache.imageMap.set(path, bmp);
        };
    
        setupCache.prefetchArray.push(fetchFile());
    },

    prefetchLuaFile: function(path) {
        async function fetchFile() {
            const rawText = require("./assets/"+path);
            await factory.mountFile(path, rawText);
        };
        
        setupCache.prefetchArray.push(fetchFile());
    },

    setBlankColour: function(colour) {
        setupCache.blankColour = colour;
    },

    setMainFile: function(path) {
        setupCache.mainFilename = path;
    }
};

// Interface enabling Lua to draw to canvas
const CanvasCalls = {
    clearCanvas: function() {
        canvas.clearRect(0, 0, canvasElement.width, canvasElement.height);
        canvas.fillStyle = setupCache.blankColour;
        canvas.fillRect(0, 0, canvasElement.width, canvasElement.height);
    },

    drawImage: function(path, sx, sy, sw, sh, dx, dy, dw, dh) {
        if (setupCache.imageMap.has(path)) {
            const bmp = setupCache.imageMap.get(path);
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
        // Initialisation
        lua.global.set("Initialisation", InitialisationCalls);
        // First load the init file
        InitialisationCalls.prefetchLuaFile(setupCache.initFilename);
        await Promise.all(setupCache.prefetchArray);
        // Then execute it
        await lua.doFile(setupCache.initFilename);
        await Promise.all(setupCache.prefetchArray);
        // Initialisation no longer needed
        lua.global.set("Initialisation", null);

        // Set up canvas
        lua.global.set("Canvas", CanvasCalls);

        // Run the main file
        await lua.doFile(setupCache.mainFilename);

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