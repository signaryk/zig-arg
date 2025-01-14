# zig-arg
zig-arg is a [clap-rs](https://github.com/clap-rs/clap) inspired command line argument parser library for [zig](https://ziglang.org).

It supports flag, subcommand, nested subcommands and has a flexible and easy to use API for defining custom [Argument](#arg).

### Note
zig-arg is still in early development compared to [other parsers](#alternate-parsers).

## Features
* [x] Short flags
    - `-b`, `-1 value`, `-o <a | b | c>`

* [x] Long flag
    - `--bool`
    - `--arg 1, --arg 1 2 `
    - `--option <a | b | c>`

* [x] Support passing flag value using space `-f value`
    no space `-fvalue` and using `=` (`-f=value`)

* [x] Support chaining multiple short flags
    - `-xy` where both `x` and `y` does not take value
    - `-xyz=value`

    Note: Currently if you provided a value for chained flags using space (`-xyz arg`)
    where all of them takes value it will be not parse as you expect. Which means it will
    not take `arg` as a value for `xyz` flags instead it will take `yz` as value for `x`
    even if you pass them as a flags and the `arg` will be parsed a argument or subcommand.

* [x] Support flag that can specified multiple times `-x 1 -x 2 -x 3`

* [x] Subcommand
    - `app bool-cmd`
    - `app single-arg-cmd <ARG>`
    - `app multi-arg-cmd <ARG1> <ARG2> <ARGS3...>`
    - `app flag-cmd [flags]`
    - `app arg-and-flag-cmd <ARG> [FLAGS]`

* [x] Nested subcommand
    - `app cmd1 cmd1.1`


## Installation Guide
Before you follow below steps be sure to initialize your project as repo by running `git init`

1. On your root project make a directory named `libs`
2. Run `git submodule add https://github.com/PrajwalCH/zig-arg libs/zig-arg`
3. After above step is complete add the following code snippet on your `build.zig` file
    ```zig
    exe.addPackagePath("zig-arg", "libs/zig-arg/src/lib.zig");
    ```
4. Now you can import this library on your src file as
    ```zig
    const zig_arg = @import("zig-arg");
    ```

## Examples
## Command
The `Command` module represents your app therefore to define what args your app will take
initilize it with `Command.new(allocator, "your app name")` then use the provided  methods
to define arg, subcommand and flags.

### takesSingleValue
```zig
fn takesSingleValue(self: *Command, arg_name: []const u8) !void
```
Creates a new [Arg](#Arg) with given name and specifies that the command will takes a single value.

You can also use [addArg](#addArg) to manually add [Arg](#Arg) with custom options.

<details>
    <summary>Example</summary>

```zig
var app = Command.new(allocator, "app");
defer app.deinit();

try app.takesValue("ARG");
```
</details>

### takesNValues
```zig
fn takesNValues(self: *Command, arg_name: []const u8, max_values: usize) !void
```
Creates a new [Arg](#Arg) with given name and specifies that the command will takes `max_values`.

You can also use [addArg](#addArg) to manually add [Arg](#Arg) with custom options.

<details>
    <summary>Example</summary>

```zig
var app = Command.new(allocator, "app");
defer app.deinit();

try app.takesNValues("ARGS", 2);
```
</details>

### addArg
```zig
fn addArg(self: *Command, new_arg: Arg) !void
```
Appends a `new_arg` in the list of valid arguments.

<details>
    <summary>Example</summary>

```zig
var app = Command.new(allocator, "app");
defer app.deinit();

// below code is equivalent to try app.takesSingleValue("ARG");
var arg = Arg.new("ARG");
arg.takesValue(true);
try app.addArg(arg);

// below code is equivalent to try app.takesNValues("ARGS", 2);
var args = Arg.new("ARGS");
arg.maxValues(2);
arg.valuesDelimiter(",");
try app.addArg(args);
```
</details>

### addSubcommand
```zig
fn addSubcommand(self: *Command, new_subcommand: Command) !void
```
Appends a `new_subcommand` to the list of valid subcommands.

Subcommand can also have its own arg, flags and subcommand too.

<details>
    <summary>Example</summary>

```zig
var app = Command.new(allocator, "app");
defer app.deinit();

var subcmd = Command.new(allocator, "subcmd");
// Add its arguments
// subcmd.deinit() call is not needed here because app.deinit()
// will handle it

try app.addSubcommand(subcmd);
```
</details>

### argRequired
```zig
fn argRequired(self: *Command, b: boolean) void
```
Specifics that the command's argument is necessary.

<details>
    <summary>Example</summary>

```zig
var app = Command.new(allocator, "app");
defer app.deinit();

try app.takesSingleValue("ARG");
app.argRequired(true);
```
</details>

### subcommandRequired
```zig
fn subcommandRequired(self: *Command, b: boolean) void
```
Specifics that the command's subcommand is necessary to provide.

<details>
    <summary>Example</summary>

```zig
var app = Command.new(allocator, "app");
defer app.deinit();

var subcmd = Command.new("subcmd");
// Add its arguments

try app.addSubcommand(subcmd);
app.subcommandRequired(true);
```
</details>

### parseProcess
```zig
fn parseProcess(self: *Command) parser.Error!ArgsContext
```
Parse process args. Internally it calls to `std.process.argsAlloc` to obtain args.

<details>
    <summary>Example</summary>

```zig
var app = Command.new(allocator, "app");
defer app.deinit();

try app.takesSingleValue("ARG");
try app.takesNValues("ARGS", 3);
// Add more args

// Once you are done adding args
var app_args = try app.parseProcess();
defer app_args.deinit();

// logics starts here
```
</details>

### parseFrom
```zig
fn parseFrom(self: *Command, argv: []const [:0]const u8) parser.Error!ArgsContext
```
Parse args from given `argv`. Useful to use it on test.

<details>
    <summary>Example</summary>

```zig
var cmd = Command.new(allocator, "app");
defer cmd.deinit();

// add args

var app_args = try cmd.parseFrom(&[_][:0]const u8 {
    "--flag",
    // and more
});
defer app_args.deinit();
```
</details>

## flag
The `flag` modules contains 4 methods `boolean`, `argOne`, `argN` and `option` which helps to define 4 kind of flag for you
by taking care of all the necessary settings and values.
Read below for more details on them.

### boolean
```zig
fn boolean(name: []const u8, short_name: ?u8) Arg
```
Defines a bool flag with short name if given.

<details>
    <summary>Example</summary>

```zig
const std = @import("std");
const zig_arg = @import("zig-arg");

pub fn main() anyerror!void {
    var app = zig_arg.Command.new(allocator, "my app");
    defer app.deinit();

    try app.addArg(zig_arg.flag.boolean("version", 'v'));
    try app.addArg(zig_arg.flag.boolean("help", 'h'));

    var app_args = try app.parseProcess();
    defer app_args.deinit();

    if (app_args.isPresent("version")) {
        std.log.info("v0.1.0", .{});
    } else if (app_args.isPresent("help")) {
        std.log.info("show help", .{});
    }

}
```
</details>

### argOne
```zig
fn argOne(name: []const u8, short_name: ?u8) Arg
```
Defines a flag that takes one value.

<details>
    <summary>Example</summary>

```zig
const std = @import("std");
const zig_arg = @import("zig-arg");

pub fn main() anyerror!void {
    var app = zig_arg.Command.new(allocator, "my app");
    defer app.deinit();

    try app.addArg(zig_arg.flag.argOne("name", 'n'));
    try app.addArg(zig_arg.flag.argOne("cast", 'c'));

    var app_args = try app.parseProcess();
    defer app_args.deinit();

    if (app_args.valueOf("name")) |n| {
        std.log.info("name = {s}\n", .{n});
    }

    if (app_args.isPresent("cast")) {
        std.log.info("cast = {s}\n", .{app_args.valueOf("cast").?});
    }
}
```
</details>

### argN
```zig
fn argN(name: []const u8, short_name: ?u8, max_values: usize) Arg
```
Defines a flag with max values to max_values and implicitly setting min values to 1
and values delimiter to `,` if max_values is greater then 1 which means user must have to
use `,` to seperate multiple values.

For ex:- `-f=v1,v2,v3`

If you want to use custom delimiter you have to use `Arg` to manually define
flag with custom settings. [See here to learn how](#Arg)

<details>
    <summary>Example</summary>

```zig
const std = @import("std");
const zig_arg = @import("zig-arg");

pub fn main() anyerror!void {
    var app = zig_arg.Command.new(allocator, "my app");
    defer app.deinit();

    try app.addArg(zig_arg.flag.argN("values", 'n', 3));

    var app_args = try app.parseProcess();
    defer app_args.deinit();

    if (app_args.valuesOf("values")) |vals| {
        for (vals) |v| {
            std.log.info("value={s}\n", .{v});
        }
    }
}
```
</details>

### option
```zig
fn option(name: []const u8, short_name: ?u8, options: [][]const u8) Arg
```
Defines a flag that takes single value with all possible values.

<details>
    <summary>Example</summary>

 ```zig
 const std = @import("std");
 const zig_arg = @import("zig-arg");

 pub fn main() anyerror!void {
     var app = zig_arg.Command.new(allocator, "my app");
     defer app.deinit();

     try app.addArg(zig_arg.flag.option("color", 'c', &[_][]const u8{
         "on",
         "off",
     }));

     var app_args = try app.parseProcess();
     defer app_args.deinit();

     if (app_args.valueOf("color")) |state| {
         std.log.info("color={s}", .{state});
     }
 }
 ```
</details>

### Making simple ls program
```zig
const std = @import("std");
const zig_arg = @import("zig-arg");

const log = std.log;
const Command = zig_arg.Command;
const flag = zig_arg.flag;

pub fn main() anyerror!void {
    var ls = Command.new(allocator, "ls");
    defer ls.deinit();

    try ls.addArg(flag.boolean("all", 'a'));
    try ls.addArg(flag.boolean("recursive", 'R'));
    // For now short name can be null but not long name
    // that's why one-line long name is used for -1 short name
    try ls.addArg(flag.boolean("one-line", '1'));
    try ls.addArg(flag.boolean("size", 's'));
    try ls.addArg(flag.boolean("version", null));
    try ls.addArg(flag.boolean("help", null));

    try ls.addArg(flag.argOne("ignore", 'I'));
    try ls.addArg(flag.argOne("hide", null));

    try ls.addArg(flag.option("color", 'C', &[_][]const u8{
        "always",
        "auto",
        "never",
    }));

    var ls_args = try ls.parseProcess();
    defer ls_args.deinit();

    // It's upto you how you check for each args
    // for now i am showing you in a straightforward way

    if (ls_args.isPresent("help")) {
       log.info("show help", .{});
       return;
    }

    if (ls_args.isPresent("version")) {
        log.info("v0.1.0", .{});
        return;
    }

    if (ls_args.isPresent("all")) {
        log.info("show all");
        return;
    }

    if (ls_args.isPresent("recursive")) {
        log.info("show recursive", .{});
        return;
    }

    if (ls_args.valueOf("ignore")) |pattern| {
        log.info("ignore pattern = {s}", .{pattern});
        return;
    }

    if (ls_args.isPresent("color")) {
        const when = ls_args.valueOf("color").?;

        log.info("color={s}", .{when});
        return;
    }
}
```

```zig
const std = @import("std");
const zig_arg = @import("zig-arg");

const allocator = std.heap.page_allocator;
const Command = zig_arg.Command;
const Flag = zig_arg.Flag;

pub fn main() anyerror!void {
    var app = Command.new(allocator, "app");
    defer app.deinit();

    // app <ARG>
    try app.takesSingleValue("ARG");

    // app [FLAGS]
    try app.addArg(Flag.boolean("--bool-flag"));
    try app.addArg(Flag.argOne("--arg-flag"));

    // app bool-subcmd
    try app.addSubcommand(Command.new(allocator, "bool-subcmd"));

    // app subcmd1 <ARGS...>
    var cmd1 = Command.new(allocator, "subcmd-1");
    try cmd1.takesNValues("ARGS", 3);

    // app subcmd2 <ARG>
    var cmd2 = Command.new(allocator, "subcmd-2");
    try cmd2.takesSingleValue("ARG");

    // app subcmd3 <ARG0> <ARG1>
    var cmd3 = Command.new(allocator, "subcmd-3");
    try cmd3.takesSingleValue("ARG0");
    try cmd3.takesSingleValue("ARG1");

    // app subcmd4 <ARG2> [flags]
    var cmd4 = Command.new(allocator, "subcmd-4");
    try cmd4.takesSingleValue("ARG2");
    try cmd4.addArg(Flag.boolean("--bool-flag"));
    try cmd4.addArg(Flag.argOne("--arg-flag"));
    // app submd4 --opt-flag [opt1, opt2, opt3]
    // parse method will return error.ValueIsNotInAllowedValues if provided value does not match with options
    try cmd4.addArg(Flag.option("--opt-flag", &[_]{
        "opt1",
        "opt2",
    }));

    try app.addSubcommand(cmd1);
    try app.addSubcommand(cmd2);
    try app.addSubcommand(cmd3);
    try app.addSubcommand(cmd4);

    const argv = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, argv);

    var app_args = try app.parse(argv);
    defer app_args.deinit();

    if (app_args.isPresent("bool-flag")) {
        // logic here
    }

    // You can use isPresent to check any argument whether
    // if it's exist or not before querying it
    if (app_args.isPresent("ARG")) {
        var single_value = app_arg.valueOf("ARG").?;
    }

    if (app_args.valueOf("arg-flag")) |value| {
        // logic here
    }

    if (app_args.isPresent("bool-cmd")) {
        // logic here
    }

    if (app_args.valuesOf("ARGS")) |values| {
        // logic here
    }

    // valueOf recursively search for an argument but if app and subcommand have same argument name
    // like in this example app and subcmd2 have same ARG argument in that case it will return the value
    // of app ARG because it will tries to find in self.args then it will begin to search in self.subcommand
    // if not found. Therefore to get the value of subcmd2 ARG call subcommandMatches(cmd_name) to get args
    // of cmd_name then you can call valueOf

    if (app_args.subcommandMatches("subcmd-2")) |subcmd2_args| {
        // Here no need call subcm2_args.deinit() because app_args.deinit() will
        // be sufficient

        if (subcmd2_args.valueOf("ARG")) |value| {
            // logic here
        }
    }

   if (app_args.subcommandMatches("subcmd-4")) |subcmd4_args| {
       if (subcmd4_args.isPresent("bool-flag")) {
           // logic here
       }

       if (subcmd4_args.valueOf("arg-flag")) |arg_flag_value|{
           // logic here
       }
   }
}
```

### `Arg`
`Arg` is an abstract representation of argument which has all the options and settings
to define valid argument and to tell parser how it should parse. Let's take a simple example
to learn how you can use `Arg` to define argument for command and subcommand.

```zig
const std = @import("std");
const zig_arg = @import("zig-arg");

const allocator = std.heap.page_allocator;
const Command = zig_arg.Command;
const Arg = zig_arg.Arg;

pub fn main() anyerror!void {
    var app = Command.new(allocator, "app");
    defer app.deinit();

    var app_single_arg = Arg.new("ARG");
    app_single_arg.minValues(1);
    app_single_arg.maxValues(1);
    app_single_arg.allValuesRequired(true);

    var app_many_args = Arg.new("ARGS");
    app_many_args.minValue(1);
    app_many_args.maxValues(5);
    // When set true parse method will return error.IncompleteArgValues if provided values
    // is less then maxValues
    app_many_args.allValuesRequired(true);

    var app_opt_flag = Arg.new("--option-flag");
    // parse method will return error.ValueIsNotInAllowedValues
    // if provided value does not match with any allowed values
    app_opt_flag.allowedValues(&[_]{
        "opt1",
        "opt2",
    });

    try app.addArg(Arg.new("--bool-flag"));
    try app.addArg(app_single_arg);
    try app.addArg(app_many_args);
    try app.addArg(app_opt_flag);

    const argv = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, argv);

    var app_args = try app.parse(argv);
    defer app_args.deinit();

    // use just like above example
}
```

## Alternate Parsers
- [Hejsil/zig-clap](https://github.com/Hejsil/zig-clap) - Simple command line argument parsing library
- [winksaville/zig-parse-args](https://github.com/winksaville/zig-parse-args) - Parse command line arguments
- [MasterQ32/zig-args](https://github.com/MasterQ32/zig-args) - Simple-to-use argument parser with struct-based config

