const std = @import("std");
const HittableList = @import("hittable.zig").HittableList;
const Hittable = @import("hittable.zig").Hittable;
const Sphere = @import("sphere.zig").Sphere;
const Vec3f = @import("vec3.zig").Vec3(f64);
const Material = @import("materials.zig").Material;
const utils = @import("math_utils.zig");
const Allocator = std.mem.Allocator;

pub fn initBasicSpheres(allocator: Allocator) !HittableList {
    var world = HittableList.init();
    try world.add(allocator, Hittable{ .sphere = Sphere{
        .center = Vec3f.init(0, 0, -1),
        .radius = 0.5,
        .material = Material{ .lambertian = .{ .albedo = Vec3f.init(0.5, 0.5, 0.5) } },
    } });
    try world.add(allocator, Hittable{ .sphere = Sphere{
        .center = Vec3f.init(0, -100.5, -1),
        .radius = 100,
        .material = Material{ .lambertian = .{ .albedo = Vec3f.init(0.5, 0.5, 0.5) } },
    } });
    return world;
}

pub fn initMetalSpheres(allocator: Allocator) !HittableList {
    var world = HittableList.init();

    const center_material = Material{ .lambertian = .{
        .albedo = Vec3f.init(0.1, 0.2, 0.5),
    } };

    const ground_material = Material{ .lambertian = .{
        .albedo = Vec3f.init(0.8, 0.8, 0.0),
    } };

    const left_material = Material{ .dielectric = .{
        .ref_idx = 1.5,
    } };

    const bubble_material = Material{ .dielectric = .{
        .ref_idx = 1.0 / 1.5,
    } };

    const right_material = Material{ .metal = .{
        .albedo = Vec3f.init(0.8, 0.6, 0.2),
        .fuzz = 1.0,
    } };

    const center_sphere = Hittable{ .sphere = Sphere{
        .center = Vec3f.init(0, 0, -1.2),
        .radius = 0.5,
        .material = center_material,
    } };

    const ground_sphere = Hittable{ .sphere = Sphere{
        .center = Vec3f.init(0, -100.5, -1),
        .radius = 100,
        .material = ground_material,
    } };

    const left_sphere = Hittable{ .sphere = Sphere{
        .center = Vec3f.init(-1.0, 0, -1.0),
        .radius = 0.5,
        .material = left_material,
    } };

    const bubble = Hittable{ .sphere = Sphere{
        .center = Vec3f.init(-1.0, 0, -1.0),
        .radius = 0.4,
        .material = bubble_material,
    } };

    const right_sphere = Hittable{ .sphere = Sphere{
        .center = Vec3f.init(1.0, 0, -1.0),
        .radius = 0.5,
        .material = right_material,
    } };

    try world.add(allocator, center_sphere);
    try world.add(allocator, ground_sphere);
    try world.add(allocator, left_sphere);
    try world.add(allocator, bubble);
    try world.add(allocator, right_sphere);

    return world;
}

pub fn twoSpheres(allocator: Allocator) !HittableList {
    var world = HittableList.init();

    const r = std.math.cos(std.math.pi / 4.0);

    const material_left = Material{ .lambertian = .{
        .albedo = Vec3f.init(0, 0, 1),
    } };
    const material_right = Material{ .lambertian = .{
        .albedo = Vec3f.init(1, 0, 0),
    } };

    const left_sphere = Hittable{ .sphere = Sphere{
        .center = Vec3f.init(-r, 0, -1),
        .radius = r,
        .material = material_left,
    } };

    const right_sphere = Hittable{ .sphere = Sphere{
        .center = Vec3f.init(r, 0, -1),
        .radius = r,
        .material = material_right,
    } };

    try world.add(allocator, left_sphere);
    try world.add(allocator, right_sphere);

    return world;
}

pub fn complexSpheres(allocator: Allocator, rng: std.Random) !HittableList {
    var world = HittableList.init();

    const ground_material = Material{ .lambertian = .{ .albedo = Vec3f.init(0.5, 0.5, 0.5) } };
    try world.add(allocator, Hittable{ .sphere = Sphere{
        .center = Vec3f.init(0, -1000, 0),
        .radius = 1000,
        .material = ground_material,
    } });

    var a: i32 = -11;
    while (a < 11) : (a += 1) {
        var b: i32 = -11;
        while (b < 11) : (b += 1) {
            const choose_mat = utils.randomF64(rng);
            const center = Vec3f.init(
                @as(f64, @floatFromInt(a)) + 0.9 * utils.randomF64(rng),
                0.2,
                @as(f64, @floatFromInt(b)) + 0.9 * utils.randomF64(rng),
            );

            if (center.sub(Vec3f.init(4, 0.2, 0)).length() > 0.9) {
                var sphere_material: Material = undefined;

                if (choose_mat < 0.8) {
                    // diffuse
                    const albedo = Vec3f.randomInRange(rng, 0, 1).mul(Vec3f.randomInRange(rng, 0, 1));
                    sphere_material = Material{ .lambertian = .{ .albedo = albedo } };
                    try world.add(allocator, Hittable{ .sphere = Sphere{ .center = center, .radius = 0.2, .material = sphere_material } });
                } else if (choose_mat < 0.95) {
                    // metal
                    const albedo = Vec3f.randomInRange(rng, 0.5, 1);
                    const fuzz = utils.randomF64InRange(rng, 0, 0.5);
                    sphere_material = Material{ .metal = .{ .albedo = albedo, .fuzz = fuzz } };
                    try world.add(allocator, Hittable{ .sphere = Sphere{ .center = center, .radius = 0.2, .material = sphere_material } });
                } else {
                    // glass
                    sphere_material = Material{ .dielectric = .{ .ref_idx = 1.5 } };
                    try world.add(allocator, Hittable{ .sphere = Sphere{ .center = center, .radius = 0.2, .material = sphere_material } });
                }
            }
        }
    }

    const material1 = Material{ .dielectric = .{ .ref_idx = 1.5 } };
    try world.add(allocator, Hittable{ .sphere = Sphere{ .center = Vec3f.init(0, 1, 0), .radius = 1.0, .material = material1 } });

    const material2 = Material{ .lambertian = .{ .albedo = Vec3f.init(0.4, 0.2, 0.1) } };
    try world.add(allocator, Hittable{ .sphere = Sphere{ .center = Vec3f.init(-4, 1, 0), .radius = 1.0, .material = material2 } });

    const material3 = Material{ .metal = .{ .albedo = Vec3f.init(0.7, 0.6, 0.5), .fuzz = 0.0 } };
    try world.add(allocator, Hittable{ .sphere = Sphere{ .center = Vec3f.init(4, 1, 0), .radius = 1.0, .material = material3 } });

    return world;
}
