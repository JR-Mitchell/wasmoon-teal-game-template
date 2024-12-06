# Wasmoon Teal game template
A proof of concept / template for using Wasmoon and Teal to make a game that runs with wasm in the browser.

## Building
### Requirements
- [git](https://git-scm.com/)
- [npm](https://www.npmjs.com/)
- [lua](https://www.lua.org/)
- [luarocks](https://luarocks.org/)
- [teal](https://github.com/teal-language/tl)
- [pegasus](https://github.com/EvandroLG/pegasus.lua)

### Instant setup guide
Assuming all of the requirements are properly installed, then the following should clone, build, and run the template locally on `localhost:8080` from scratch.
(Only tested on linux - your mileage may vary).
```sh
git clone git@github.com:JR-Mitchell/wasmoon-teal-game-template.git
cd wasmoon-teal-game-template
tl build
npm i
npm run build
lua server/main.lua
```

### Rebuilding
To rebuild, simply run:
```sh
tl build
npm run build
```

### Dev server
Run these two commands *separately*, either in different terminal windows, using `screen` (or a similar utility), or just use an `&` at the end of each and remember to kill the processes once you're done:
```sh
npm start
```
```sh
lua server/server.lua
```
Then make your changes to the game code, and just run `tl build` every time you want to recompile.
Note that if you make changes to the *server* code, you'll have to kill the server process and restart it.