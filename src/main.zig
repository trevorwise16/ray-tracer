const std = @import("std");
const Io = std.Io;
const Vec3f = @import("vec3.zig").Vec3(f64);
const color = @import("color.zig");
const Ray = @import("ray.zig").Ray;
const Hittable = @import("hittable.zig").Hittable;
const HittableList = @import("hittable.zig").HittableList;
const Sphere = @import("sphere.zig").Sphere;
const Allocator = std.mem.Allocator;
const Interval = @import("interval.zig").Interval;
const Camera = @import("camera.zig").Camera;

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();

    // setting up prng - i have no idea if this is right
    // it feels kind of crazy
    var seed: u64 = undefined;
    init.io.random(std.mem.asBytes(&seed));
    var prng = std.Random.DefaultPrng.init(seed);
    const rng = prng.random();

    var world = try initWorld(allocator);
    defer world.clear(allocator);
    const camera = Camera.initialize(400, 16.0 / 9.0, 100, rng);
    try camera.render(init.io, &world);
}

fn initRng(io: Io) std.Random {
    var seed: u64 = undefined;
    io.random(std.mem.asBytes(&seed));
    return std.Random.DefaultPrng.init(seed).random();
}

fn initWorld(allocator: Allocator) !HittableList {
    var world = HittableList.init();
    try world.add(allocator, Hittable{ .sphere = Sphere{
        .center = Vec3f.init(0, 0, -1),
        .radius = 0.5,
    } });
    try world.add(allocator, Hittable{ .sphere = Sphere{
        .center = Vec3f.init(0, -100.5, -1),
        .radius = 100,
    } });
    return world;
}
