## Intro
This project is written in [Teal](https://github.com/teal-language), a typed dialect of the Lua programming language.
Lua is an interpreted language with a relatively lightweight interpreter, making it suitable for embedding in other applications or languages.
In this project, [wasmoon](https://github.com/ceifa/wasmoon) provides a compilation of the Lua compiler into WebAssembly, so that it can be run in the browser.
This Markdown file serves as a brief introduction to Lua, Teal, and the way that they are used in this project.

## Lua
### Basic primitive types
(See [lua docs](https://www.lua.org/manual/5.3/manual.html#2.1))

The basic primitive types that are useful to know about are:
- `boolean`
- `number`
- `integer`
- `string`

Booleans are written as `true` or `false`.
Numbers are written like `3.4`, and integers like `5`.
Strings can be surrounded with `'single quotes'`, `"double quotes"`, or (for multiline strings)
```lua
[[double
square
brackets]]
```

All types are nullable, and the null constant in lua is called `nil`.

`nil` can be checked for explicitly (`if (x == nil)`), but additionally `nil` is considered falsy, so code in an `if (x)` block will execute *unless* `x` is `nil` or `false`.

### Tables and functions
Tables and Functions are some of the most important types for writing Lua code.

#### Tables
A table is a lookup structure, like a python `dict`, a Java `MutableMap`, or a JavaScript `Map`.

Its keys can be any value except `nil`, and its values can also be any value except `nil` (setting a table value to `nil` is equivalent to removing that key from the table).

Tables can have values initialised inline:
```lua
local myTable = {
    x = 0,
    y = 0,
    name = "John Smith"
}
```

and values can be set after construction:
```lua
myTable["greeting"] = "hello"
myTable[3] = 4
```

String keys can also be set and accessed using dot syntax, similar to member properties in other languages
```lua
myTable.greeting = "hello" -- equivalent to myTable["greeting"] = "hello"
```

Because tables can have integer keys, they can also be used in a similar fashion to arrays / lists in other languages, and can even be constructed with implicit numeric keys.
These are 1-indexed (i.e. the first element is at index 1):

```lua
myArrayTable = {
    "hello",
    "hi"
}
print(myArrayTable[1]) -- prints "hello"
```

Some useful functions to know:
- `table.insert` and `table.remove` can be used to add and remove items from an array-like table:  
```lua
table.insert(myArrayTable, "howdy")
print(myArrayTable[3]) -- prints "howdy"
print(table.remove(myArrayTable, 1)) -- prints "hello"
print(myArrayTable[1]) -- prints "hi"
```
- `pairs` can be used to iterate over all of the keys and values of a table in an undetermined order:  
```lua
for key,value in pairs(myTable) do
    print(key)
end
-- prints "x", then "y", then "name"
```
- Similarly, `ipairs` can be used to iterate over a table like an array:
```lua
for index,value in pairs(myArrayTable) do
    print(value)
end
-- prints "hi", then "howdy"
```

#### Functions
You know what a function is.
In Lua, functions can take any number of arguments, and can return multiple values:
```lua
function runningSums(a, b, c)
    return a, a + b, a + b + c
end
```

Any additional argument will be discarded:
```lua
runningSums(1,2,3,4) -- equivalent to runningSums(1,2,3)
```
and additional return values will be assigned nil:
```lua
local a,b,c,d = runningSums(1,2,3)
print(d) -- prints "nil"
```

Similarly, fewer arguments can be passed, in which case they are taken to be `nil`
```lua
runningSums(1,2) -- equivalent to runningSums(1,2,nil) - will crash, because nil cannot be added to an integer
```
And return arguments will be discarded if not assigned:
```lua
local a = runningSums(1,2,3) -- a will be equal to 1, and the extra return values 3 and 6 are discarded
```

Because table keys and values can be any value other than `nil`, functions can be used as table keys or values (usually as values):

```lua
local numeric = {
    add = function(a, b)
        return a + b
    end,
    subtract = function(a, b)
        return a - b
    end
}
print(numeric.add(1,2)) -- prints 3
```

This can be used for namespacing and object-oriented programming.

A very useful syntax to know here is that functions indexed with `:` rather than `.` on a record will pass the record to the function as a first argument:

```lua
local nameCollection = {
    names = {},
    addName = function(self, name)
        table.insert(self.names, name)
    end
}

nameCollection:addName("Jeff")
nameCollection:addName("Stacy")
print(nameCollection.names[2]) -- prints "Stacy"
```

You can also use the following syntax to write functions within tables:
```lua
function nameCollection:printNames()
    for _,name in ipairs(self.names) do
        print(name)
    end
end

function nameCollection.randomName()
    return "If you named your child "..tostring(math.random())..", it would certainly be considered a very random name"
end
```

### Metatables and prototyping
Each table can contain a metatable, which can be used to define the behaviour of basic Lua operations on it, by defining metamethods.
This can be set using the `setmetatable` function:
```lua
local positionMetatable = {}
positionMetatable.__add = function(a, b)
    local newPosition = {
        x = a.x + b.x,
        y = a.y + b.y
    }
    setmetatable(newPosition, positionMetatable)
    return newPosition
end
positionMetatable.__tostring = function(position)
    return "{ x: "..position.x..", y: "..position.y.." }"
end
local firstPosition = {
    x = 3,
    y = 2
}
local secondPosition = {
    x = 4,
    y = 3
}
setmetatable(firstPosition, positionMetatable)
setmetatable(secondPosition, positionMetatable)
print(firstPosition + secondPosition) -- prints "{ x: 7, y: 5 }"
```

Possibly the most important metamethod is `__index`, which is used when trying to read a member of a table which does not have a key set:
```lua
local alwaysTrueTable = {}
setmetatable(alwaysTrueTable, {__index=function() return true end})
print(alwaysTrueTable.beans) -- prints "true"
```

This can be set to another table so that the properties of this other table can be transiently accessed:
```lua
local myNameCollection = {}
setmetatable(myNameCollection, {__index=nameCollection})
print(myNameCollection.names[2]) -- prints "Stacy"
```

crucially, this allows functions and methods to be used, providing a form of inheritance:
```lua
myNameCollection.names = {"Bob", "Bill"}
print(myNameCollection.names[2]) -- prints "Bill", since this key now has a value set
myNameCollection:addName("Ben")
print(myNameCollection.names[3]) -- prints "Ben"
```

In this above case, because `myNameCollection` now has the key `names` set, this isn't looked up in its "parent" table `nameCollection`.
But, it doesn't have a key `addName` set, so `nameCollection.addName` is used instead.
But the `addName` function is called with `myNameCollection` as the first item, and so the new name is added to `myNameCollection.names`.

So, in this case, using the `__index` metamethod in this way,
```lua
myNameCollection:addName("Ben")
```
is equivalent to the call
```lua
nameCollection.addName(myNameCollection, "Ben")
```

This enables us to define the functions which operate on a particular kind of data in a single place, and then create multiple instances of this kind of data, each of which can be made to effectively 'inherit' the functionality of the prototype.

### Modules and imports
Other bits of code are imported through use of the `require` function:

```lua
local socket = require("socket")
```

This will run all of the code in the `socket` dependency, or in a file named `socket.lua`.
It will then return `true` to denote that a successful require, *or* if the file `socket.lua` ends with a `return` statement, it will return the result of that return statement.

Usually, we return a single table from a file, containing all of the functions we want to be accessed from it:
```lua
-- point2d.lua
local Point2D = {}
local Point2DMetatable = {
    __index = Point2D
}

function Point2DMetatable.__tostring(point)
    return "{ x: "..point.x..", y: "..point.y.." }"
end

function Point2DMetatable.__add(first, second)
    return Point2D.new(
        first.x + second.x,
        first.y + second.y
    )
end

function Point2D.new(x, y)
    local point = {
        x = x,
        y = y
    }
    setmetatable(point, Point2DMetatable)
    return point
end

function Point2D:dot(other)
    return self.x * other.x + self.y * other.y
end

function Point2D:cross(other)
    return Point2D.new(
        self.x * other.y,
        -self.y * other.x
    )
end

return Point2D

-- main.lua
local Point2D = require("point2d")
local first = Point2D.new(4,4)
local second = Point2D.new(2,6)
print(first + second) -- prints "{ x: 6, y: 10 }"
print(first:dot(second)) -- prints "32"
print(first:cross(second)) -- prints "{ x: 24, y: -8 }"
```

## Teal
Teal is a typed dialect to Lua.
Writing in Teal increases the type safety of your written code, and the Teal source can then be compiled down to Lua.
The best documentation for Teal can be found [in the `tl` repo](https://github.com/teal-language/tl/blob/master/docs/tutorial.md), however some key points are covered below:

### Functions
The type of each parameter and return value is declared when the function is written:
```lua
local function add(first: number, second: number): number
    return first + second
end
```
The Teal compiler ensures that the function is not called with arguments of the wrong type, and that the return values are assigned or used correctly.

Functions can also be used as types, such as in this example:
```lua
local function getCallback(name: string): function(): string
    return function()
        return name
    end
end
```

### Arrays and Maps
Array types are declared like:
```lua
local myArrayTable: {string} = {
    "hello",
    "hi"
}
```

and simple maps like:
```lua
local myStringToIntMap: {string:integer} = {
    x = 0,
    y = 0,
    id = 3
}
```

### Records
A record is a declaration of a table that maps specific keys to specific types:
```lua
local record NameCollection
    names: {string}
end
```

Declaring a record creates an empty table, but a record can also be used as a type, to ensure conformance to the typing of its keys and values:
```lua
local myNameCollection: NameCollection = {
    names = {}
}
```

Note that all fields in a record are considered optional - so the following will also compile:

```lua
local myNameCollection: NameCollection = {}
```

Functions and methods on a record may be declared outside of the initial record declaration, as long as they are in the same file.
These functions will be added to the empty table created by the record declaration.
The `metatable` type can also be used to define metatables for a record type.

```lua
local record NameCollection
    names: {string}
end

local NameCollectionMetatable: metatable<NameCollection> = {
    __index = NameCollection
}

function NameCollection:addName(name)
    table.insert(self.names, name)
end

function NameCollection:printNames()
    for _,name in ipairs(self.names) do
        print(name)
    end
end

function NameCollection.randomName(): string
    return "If you named your child "..tostring(math.random())..", it would certainly be considered a very random name"
end

function NameCollection.new(): NameCollection
    local newInstance = {}
    setmetatable(new, NameCollectionMetatable)
    return newInstance
end
```

and these can then be called directly on the record:
```lua
local myNameCollection = NameCollection.new()
myNameCollection:addName("Xerxes")
```

In this way, a file can export a single record, and it can behave either like a singleton, or like a class (if it provides methods and a constructor-like function).

### Using Lua code in Teal code
#### Required code
You can `require` Lua libraries into your Teal code.
In order to do this, you need to give Teal the type information for the library.
Create a `.d.tl` file for defining the types in the library.
In this file, create a `record` which provides all of the fields and functions returned by the library, and then return it.
This provides type information for Teal to use to check that you are using the library correctly.
You only need to declare the fields in this record that you're currently using.
Then, you just require the library as per normal.

#### Global code
Sometimes, the interpreter of the Lua code may set up some global libraries which are not explicitly `require`d.
For instance, `wasmoon` allows you to pass JavaScript objects to the Lua interpreter via `lua.global.set`.
In this project, these types are declared in the `global-defs.d.tl` file.