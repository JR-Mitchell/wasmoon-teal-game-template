# Wasmoon Teal game template
A proof of concept / template for using Wasmoon and Teal to make a game that runs with wasm in the browser.

## Building
### Requirements
- [git](https://git-scm.com/)
- [npm](https://www.npmjs.com/)
- [lua](https://www.lua.org/)
- [luarocks](https://luarocks.org/)

### Lua requirements (installed using luarocks)
- [teal](https://github.com/teal-language/tl)
    - While [this issue](https://github.com/teal-language/tl/issues/865) is outstanding, this won't work on the latest teal version. Install with `luarocks install tl 0.15.3-1`
- [pegasus](https://github.com/EvandroLG/pegasus.lua)
- [sha1](https://github.com/mpeterv/sha1)
- [base64](https://github.com/iskolbin/lbase64)

### Instant setup guide
Assuming all of the requirements are properly installed, then the following should clone, build, and run the template locally on `localhost:8080` from scratch.
(Only tested on linux - your mileage may vary).
```sh
git clone git@github.com:JR-Mitchell/wasmoon-teal-game-template.git
cd wasmoon-teal-game-template
tl build
npm i
npm run build
tl run teal/server/main.tl
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
tl run teal/server/main.tl
```
Then make your changes to the game code, and just run `tl build` every time you want to recompile.
Note that if you make changes to the *server* code, you'll have to kill the server process and restart it.