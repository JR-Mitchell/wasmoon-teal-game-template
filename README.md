# Wasmoon Teal game template
A proof of concept / template for using Wasmoon and Teal to make a game that runs with wasm in the browser.

## Building
### Requirements
- [npm](https://www.npmjs.com/)
- [lua](https://www.lua.org/)
- [luarocks](https://luarocks.org/)
- [teal](https://github.com/teal-language/tl)

### Steps
```sh
cd wasmoon-teal-game-template
tl build
npm run build
```

## Quick local run (after building)
### Requirements
- [python 3+](https://www.python.org/downloads/)

### Steps
```sh
cd dist
python3 -m http.server
```