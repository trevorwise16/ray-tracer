const std = @import("std");
const Allocator = std.mem.Allocator;

pub const ArgsError = error{InvalidArgs};

pub const Config = struct {
    seed: ?u64 = null,
    num_threads: ?u8 = null,
};

pub fn parseArgs(allocator: Allocator, args: std.process.Args) !Config {
    const parsed = try args.toSlice(allocator);
    defer allocator.free(parsed);

    if (parsed.len > 3) {
        return ArgsError.InvalidArgs;
    }

    var config = Config{};

    if (parsed.len > 1) {
        const seed_str = parsed[1];
        const seed = try std.fmt.parseInt(u64, seed_str, 10);
        config.seed = seed;
    }

    if (parsed.len > 2) {
        const num_threads_str = parsed[2];
        const num_threads = try std.fmt.parseInt(u8, num_threads_str, 10);
        config.num_threads = num_threads;
    }

    return config;
}
