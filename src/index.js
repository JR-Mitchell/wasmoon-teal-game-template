import wasmFile from 'wasmoon/dist/glue.wasm';
import { LuaFactory } from 'wasmoon';

// Get the canvas to draw on
const canvasElement = document.getElementById("canvas");
const canvas = canvasElement.getContext('2d');
const canvasStyle = window.getComputedStyle(canvasElement, null);

// Create a new factory
const factory = new LuaFactory(wasmFile);

// Stored properties
const initFilename = "shared/init.lua"
var blankColour = "white"
var imageMap = new Map();
var websocket;
var game;

function transformPointToCanvas(x,y) {
    const offsetWidthMinusPadding = canvasElement.offsetWidth - parseInt(canvasStyle.paddingLeft) - parseInt(canvasStyle.paddingRight);
    const offsetHeightMinusPadding = canvasElement.offsetHeight - parseInt(canvasStyle.paddingTop) - parseInt(canvasStyle.paddingBottom);
    const xScale = offsetWidthMinusPadding / canvasElement.width;
    const yScale = offsetHeightMinusPadding / canvasElement.height;
    var scale = xScale;
    var topOffset = canvasElement.offsetTop + canvasElement.clientTop + parseInt(canvasStyle.paddingTop);
    var leftOffset = canvasElement.offsetLeft + canvasElement.clientLeft + parseInt(canvasStyle.paddingLeft);
    if (xScale > yScale) {
        scale = yScale;
        const actualWidth = offsetWidthMinusPadding * yScale / xScale;
        leftOffset += (offsetWidthMinusPadding - actualWidth) / 2;
    } else if (yScale > xScale) {
        const actualHeight = offsetHeightMinusPadding * xScale / yScale;
        topOffset += (offsetHeightMinusPadding - actualHeight) / 2;
    }
    return [
        (x - leftOffset) / scale,
        (y - topOffset) / scale
    ];
}

function prefetchImage(path) {
    async function fetchFile() {
        const url = new URL("assets/"+path, window.location.origin);
        let blob = await fetch(url).then(r => r.blob());
        const bmp = await createImageBitmap(blob);
        imageMap.set(path, bmp);
    };

    return fetchFile();
};

function prefetchLuaFile(path) {
    async function fetchFile() {
        const url = new URL("assets/"+path, window.location.origin);
        let rawText = await fetch(url).then(r => r.text());
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

function registerWebsocketCallbacks(triggerOpen) {
    if (websocket) {
        if (game) {
            if (game["websocketMessage"] != undefined) {
                websocket.onmessage = function(event) {
                    game.websocketMessage(event.data);
                }
            }
            if (game["websocketOpened"] != undefined) {
                console.log("a")
                console.log(websocket.readyState)
                if (triggerOpen && websocket.readyState == WebSocket.OPEN) {
                    console.log("b")
                    game.websocketOpened();
                }
                websocket.onopen = function() {
                    console.log("c")
                    game.websocketOpened();
                }
            }
            if (game["websocketClosed"] != undefined) {
                websocket.onclose = function(event) {
                    game.websocketClosed(event.code, event.reason);
                }
            }
            
            if (game["websocketError"] != undefined) {
                websocket.onerror = function() {
                    game.websocketError();
                }
            }
        }
    }
};

// Interface enabling Lua to draw to canvas
const CanvasCalls = {
    newCanvas: function(transparent) {
        const newCanvasElement = document.createElement("canvas");
        newCanvasElement.width = canvasElement.width;
        newCanvasElement.height = canvasElement.height;
        const newCanvas = newCanvasElement.getContext("2d");

        const subCanvas = {
            drawImage: function(path, sx, sy, sw, sh, dx, dy, dw, dh) {
                if (imageMap.has(path)) {
                    const bmp = imageMap.get(path);
                    newCanvas.drawImage(bmp, sx, sy, sw, sh, dx, dy, dw, dh);
                }
            },

            draw: function(x, y) {
                canvas.drawImage(newCanvasElement, x, y)
            }
        }

        if (transparent) {
            subCanvas.clearCanvas = function() {
                newCanvas.clearRect(0, 0, newCanvasElement.width, newCanvasElement.height);
            }
        } else {
            subCanvas.clearCanvas = function() {
                newCanvas.clearRect(0, 0, newCanvasElement.width, newCanvasElement.height);
                newCanvas.fillStyle = blankColour;
                newCanvas.fillRect(0, 0, newCanvasElement.width, newCanvasElement.height);
            }
        }

        subCanvas.clearCanvas();

        return subCanvas;
    }
};

// Interface enabling Lua to interact with WebSockets
const SocketCalls = {
    open: function(subprotocol) {
        websocket = new WebSocket(`ws://${window.location.host}/websocket`, subprotocol);
        registerWebsocketCallbacks(false);
    },

    send: function(data) {
        if (websocket) {
            websocket.send(data)
        }
    },

    close: function() {
        if (websocket) {
            websocket.close()
        }
    }
}

function startGameLoop(game, lua) {
    game.init();
    let previousTime = Date.now();
    function loop() {
        try {
            const now = Date.now();
            game.step(now - previousTime);
            game.draw();
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
        // Set up websocket calls
        lua.global.set("Socket", SocketCalls);
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
        game = lua.global.get("Game");

        // Set up any listeners
        if (game["keyUp"] != undefined) {
            document.addEventListener('keyup', (event) => {
                game.keyUp(event.key);
            });
        };

        if (game["keyDown"] != undefined) {
            document.addEventListener('keydown', (event) => {
                game.keyDown(event.key);
            });
        };

        if (game["keyPress"] != undefined) {
            document.addEventListener('keypress', (event) => {
                game.keyPress(event.key);
            });
        };

        if (game["onClick"] != undefined) {
            canvasElement.addEventListener('click', (event) => {
                let x,y;
                [x,y] = transformPointToCanvas(event.pageX, event.pageY);
                if (x >= 0 && x <= canvasElement.width && y >= 0 && y <= canvasElement.height) {
                    game.onClick(x, y);
                }
            });
        };

        if (game["onPointerDown"] != undefined) {
            document.addEventListener('pointerdown', (event) => {
                let x, y;
                [x, y] = transformPointToCanvas(event.pageX, event.pageY);
                if (x >= 0 && x <= canvasElement.width && y >= 0 && y <= canvasElement.height) {
                    game.onPointerDown(x, y);
                }
            });
        };

        if (game["onPointerUp"] != undefined) {
            document.addEventListener('pointerup', (event) => {
                let x, y;
                [x, y] = transformPointToCanvas(event.pageX, event.pageY);
                game.onPointerUp(x, y);
            });
        };

        registerWebsocketCallbacks(true);

        // Start the game loop
        startGameLoop(game, lua)
    } catch (e) {
        console.log(e);
        lua.global.close();
    }
};

execute();