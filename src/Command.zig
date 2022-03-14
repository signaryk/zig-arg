const Command = @This();

const std = @import("std");
const parser = @import("parser.zig");
const Flag = @import("Flag.zig");
const ArgMatches = @import("ArgMatches.zig");

const mem = std.mem;
const Allocator = mem.Allocator;

allocator: Allocator,
name: []const u8,
about: ?[]const u8,
flags: ?std.ArrayList(Flag),
subcommands: ?std.ArrayList(Command),

pub fn new(allocator: Allocator, name: []const u8) Command {
    return Command{
        .allocator = allocator,
        .name = name,
        .about = null,
        .flags = null,
        .subcommands = null,
    };
}

pub fn newWithHelpTxt(allocator: Allocator, name: []const u8, about: []const u8) Command {
    var self = Command.new(allocator, name);
    self.about = about;
    return self;
}

pub fn flag(self: *Command, new_flag: Flag) !void {
    if (self.flags == null)
        self.flags = std.ArrayList(Flag).init(self.allocator);
    return self.flags.?.append(new_flag);
}

pub fn subCommand(self: *Command, new_subcommand: Command) !void {
    if (self.subcommands == null)
        self.subcommands = std.ArrayList(Command).init(self.allocator);
    return self.subcommands.?.append(new_subcommand);
}

pub fn parse(self: *Command, argv: []const [:0]const u8) !ArgMatches {
    return parser.parse(argv, self);
}

pub fn takesArg(self: *Command) bool {
    return (self.flags == null and self.subcommands == null);
}
