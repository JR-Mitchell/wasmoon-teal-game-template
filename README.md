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
npm i
npm start
```

### Commands
- `npm run copy` will copy all necessary assets from `src/assets` to `dist/assets`.
- `npm run build` will rebuild all javascript and teal, and copy everything over to `dist`.
- `npm run run` will run the server without rebuilding or copying anything.
- `npm start` builds and copies everything, and then runs the server.