const std = @import("std");
const Vec3f = @import("vec3.zig").Vec3(f64);
const HittableList = @import("hittable.zig").HittableList;
const Io = std.Io;
const Ray = @import("ray.zig").Ray;
const Interval = @import("interval.zig").Interval;
const utils = @import("math_utils.zig");

pub const Camera = struct {
    img_height: u32,
    img_width: u32,
    samples_per_pixel: u32,
    pixels_sample_scale: f64,
    center: Vec3f,
    px00: Vec3f,
    pdu: Vec3f,
    pdv: Vec3f,
    rng: std.Random,

    pub fn initialize(img_width: u32, aspect_ratio: f64, samples_per_pixel: u32, random: std.Random) Camera {
        // img stuff -- integer space
        var img_height: u32 = @intFromFloat(img_width / aspect_ratio);
        img_height = if (img_height > 1) img_height else 1;

        // viewport consts -- float space
        const focal_length = 1.0;
        const viewport_height = 2.0;
        const viewport_width: f64 = @as(f64, @floatFromInt(img_width)) / img_height * viewport_height;
        const camera_center = Vec3f.zero();

        // viewport vectors
        const viewport_u = Vec3f.init(viewport_width, 0, 0);
        const viewport_v = Vec3f.init(0, -viewport_height, 0);
        const pdu = viewport_u.scale(1.0 / @as(f64, @floatFromInt(img_width)));
        const pdv = viewport_v.scale(1.0 / @as(f64, @floatFromInt(img_height)));

        const focal_v = Vec3f.init(0, 0, focal_length);
        const upper_left = camera_center
            .sub(focal_v)
            .sub(viewport_u.scale(0.5))
            .sub(viewport_v.scale(0.5));
        const px00 = upper_left.add(pdu.scale(0.5)).add(pdv.scale(0.5));
        return Camera{
            .img_height = img_height,
            .img_width = img_width,
            .samples_per_pixel = samples_per_pixel,
            .pixels_sample_scale = 1.0 / @as(f64, @floatFromInt(samples_per_pixel)),
            .center = camera_center,
            .px00 = px00,
            .pdu = pdu,
            .pdv = pdv,
            .rng = random,
        };
    }

    pub fn render(self: *const Camera, io: Io, world: *const HittableList) !void {
        var buf: [4096]u8 = undefined;
        var stdout = Io.File.stdout().writer(io, &buf);
        const writer = &stdout.interface;

        try writer.print("P3\n{} {}\n255\n", .{ self.img_width, self.img_height });

        for (0..self.img_height) |j| {
            // std.debug.print("lines remaining: {}\n", .{img_height - j});
            for (0..self.img_width) |i| {
                var color = Vec3f.zero();
                for (0..self.samples_per_pixel) |_| {
                    const ray = self.getRay(@intCast(i), @intCast(j));
                    color = color.add(rayColor(ray, world));
                }
                try writeColor(writer, color.scale(self.pixels_sample_scale));
            }
        }

        try writer.flush();
    }

    fn getRay(self: *const Camera, i: u32, j: u32) Ray {
        const offset = self.sampleSquare();
        const px_sample = self.px00.add(self.pdu.scale(i + offset.x)).add(self.pdv.scale(j + offset.y));
        return Ray{
            .origin = self.center,
            .direction = px_sample.sub(self.center),
        };
    }

    fn sampleSquare(self: *const Camera) Vec3f {
        return Vec3f.init(
            utils.randomF64(self.rng),
            utils.randomF64(self.rng),
            0,
        );
    }
};

fn rayColor(ray: Ray, world: *const HittableList) Vec3f {
    const interval = Interval{
        .min = 0.001,
        .max = std.math.inf(f64),
    };
    const hit = world.hit(ray, interval);
    if (hit) |record| {
        return record.normal.add(Vec3f.init(1, 1, 1)).scale(0.5);
    }
    const unit_dir = ray.direction.scale(1.0 / ray.direction.length());
    const a = 0.5 * (unit_dir.y + 1.0);
    return Vec3f.init(1.0, 1.0, 1.0).scale(1.0 - a).add(Vec3f.init(0.5, 0.7, 1.0).scale(a));
}

pub fn writeColor(writer: *std.Io.Writer, color: Vec3f) !void {
    const interval = Interval{
        .min = 0.0,
        .max = 0.999,
    };

    const r: u8 = @intFromFloat(256 * interval.clamp(color.x));
    const g: u8 = @intFromFloat(256 * interval.clamp(color.y));
    const b: u8 = @intFromFloat(256 * interval.clamp(color.z));

    try writer.print("{} {} {}\n", .{ r, g, b });
}
