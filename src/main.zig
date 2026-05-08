const std = @import("std");
const Io = std.Io;
const Ray = @import("ray.zig").Ray;
const Allocator = std.mem.Allocator;
const Interval = @import("interval.zig").Interval;
const Camera = @import("camera.zig").Camera;
const worlds = @import("worlds.zig");
const Vec3f = @import("vec3.zig").Vec3(f64);
const HittableList = @import("hittable.zig").HittableList;
const ppm = @import("ppm.zig");

const RowCounter = std.atomic.Value(u32);

pub fn main(init: std.process.Init) !void {
    try run(init.io, init.arena.allocator());
}

pub fn run(io: Io, allocator: Allocator) !void {
    const num_threads = try std.Thread.getCpuCount() - 1;
    var row_counter = RowCounter.init(0);
    var prng = initRng(io);
    const rng = prng.random();

    const camera = initCamera();
    var world = try worlds.complexSpheres(allocator, rng);
    defer world.clear(allocator);

    // we need to collect all thread results into a single buffer
    // writing these out to a file from threads would be a pain
    const buffer = try allocator.alloc(Vec3f, camera.img_width * camera.img_height);
    defer allocator.free(buffer);

    const threads = try allocator.alloc(std.Thread, num_threads);
    defer allocator.free(threads);

    const root = std.Progress.start(io, .{ .root_name = "render" });
    defer root.end();
    const rows_node = root.start("rows", camera.img_height);
    defer rows_node.end();

    for (0..num_threads) |i| {
        const seed = rng.int(u64);
        const t = try std.Thread.spawn(.{}, runThread, .{ seed, &camera, &world, &row_counter, buffer, &rows_node });
        threads[i] = t;
    }

    for (threads) |t| t.join();

    try ppm.writeBuffer(io, buffer, camera.img_height, camera.img_width);
}

pub fn runThread(
    seed: u64,
    camera: *const Camera,
    world: *const HittableList,
    row_counter: *RowCounter,
    buffer: []Vec3f,
    rows_node: *const std.Progress.Node,
) void {
    var prng = std.Random.DefaultPrng.init(seed);
    const rng = prng.random();
    var row_idx = row_counter.fetchAdd(1, .monotonic);
    while (row_idx < camera.img_height) : (row_idx = row_counter.fetchAdd(1, .monotonic)) {
        const start = row_idx * camera.img_width;
        const end = start + camera.img_width;
        const row = buffer[start..end];
        camera.renderRowToBuffer(rng, world, row_idx, row);
        rows_node.completeOne();
    }
}

fn initCamera() Camera {
    const lookfrom = Vec3f.init(13, 2, 3);
    const lookat = Vec3f.init(0, 0, 0);
    const vup = Vec3f.init(0, 1, 0);
    return Camera.initialize(1200, 16.0 / 9.0, 500, 50, 20, lookfrom, lookat, vup, 0.6, 10.0);
}

fn initBasicCamera() Camera {
    const lookfrom = Vec3f.init(-2, 2, 1);
    const lookat = Vec3f.init(0, 0, -1);
    const vup = Vec3f.init(0, 1, 0);
    return Camera.initialize(400, 16.0 / 9.0, 100, 50, 20, lookfrom, lookat, vup, 0.0, 3.4);
}

fn initRng(io: Io) std.Random.DefaultPrng {
    var seed: u64 = undefined;
    io.random(std.mem.asBytes(&seed));
    return std.Random.DefaultPrng.init(seed);
}
