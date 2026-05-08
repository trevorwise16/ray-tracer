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
    vfov: f64,
    lookfrom: Vec3f,
    lookat: Vec3f,
    vup: Vec3f,
    u: Vec3f,
    v: Vec3f,
    w: Vec3f,
    defocus_angle: f64,
    focus_dist: f64,
    defocus_u: Vec3f,
    defocus_v: Vec3f,
    samples_per_pixel: u32,
    pixels_sample_scale: f64,
    max_depth: u32,
    center: Vec3f,
    px00: Vec3f,
    pdu: Vec3f,
    pdv: Vec3f,

    pub fn initialize(
        img_width: u32,
        aspect_ratio: f64,
        samples_per_pixel: u32,
        max_depth: u32,
        vfov: f64,
        lookfrom: Vec3f,
        lookat: Vec3f,
        vup: Vec3f,
        defocus_angle: f64,
        focus_dist: f64,
    ) Camera {
        // img stuff -- integer space
        var img_height: u32 = @intFromFloat(img_width / aspect_ratio);
        img_height = if (img_height > 1) img_height else 1;

        // viewport consts -- float space
        const theta = utils.degreesToRadians(vfov);
        const h = std.math.tan(theta / 2.0);
        const viewport_height = 2.0 * h * focus_dist;
        const viewport_width: f64 = @as(f64, @floatFromInt(img_width)) / img_height * viewport_height;
        const camera_center = lookfrom;

        const w = lookfrom.sub(lookat).unit();
        const u = vup.cross(w).unit();
        const v = w.cross(u);

        const viewport_u = u.scale(viewport_width);
        const viewport_v = v.scale(-viewport_height);
        const pdu = viewport_u.scale(1.0 / @as(f64, @floatFromInt(img_width)));
        const pdv = viewport_v.scale(1.0 / @as(f64, @floatFromInt(img_height)));

        const upper_left = camera_center
            .sub(w.scale(focus_dist))
            .sub(viewport_u.scale(0.5))
            .sub(viewport_v.scale(0.5));

        const defocus_radius = focus_dist * std.math.tan(utils.degreesToRadians(defocus_angle / 2.0));
        const defocus_u = u.scale(defocus_radius);
        const defocus_v = v.scale(defocus_radius);

        const px00 = upper_left.add(pdu.scale(0.5)).add(pdv.scale(0.5));
        return Camera{
            .img_height = img_height,
            .img_width = img_width,
            .vfov = vfov,
            .lookfrom = lookfrom,
            .lookat = lookat,
            .vup = vup,
            .u = u,
            .v = v,
            .w = w,
            .defocus_angle = defocus_angle,
            .focus_dist = focus_dist,
            .defocus_u = defocus_u,
            .defocus_v = defocus_v,
            .samples_per_pixel = samples_per_pixel,
            .pixels_sample_scale = 1.0 / @as(f64, @floatFromInt(samples_per_pixel)),
            .max_depth = max_depth,
            .center = camera_center,
            .px00 = px00,
            .pdu = pdu,
            .pdv = pdv,
        };
    }

    pub fn renderRowToBuffer(
        self: *const Camera,
        rng: std.Random,
        world: *const HittableList,
        row: u32,
        buffer: []Vec3f,
    ) void {
        std.debug.assert(buffer.len == self.img_width);
        std.debug.assert(row < self.img_height);

        for (0..self.img_width) |i| {
            var color = Vec3f.zero();
            for (0..self.samples_per_pixel) |_| {
                const ray = self.getRay(rng, @intCast(i), row);
                color = color.add(self.rayColor(rng, ray, world, self.max_depth));
            }
            buffer[i] = color.scale(self.pixels_sample_scale);
        }
    }

    fn getRay(
        self: *const Camera,
        rng: std.Random,
        i: u32,
        j: u32,
    ) Ray {
        const offset = Vec3f.sampleSquare(rng);
        const px_sample = self.px00.add(self.pdu.scale(i + offset.x)).add(self.pdv.scale(j + offset.y));

        const ray_origin = if (self.defocus_angle > 0.0) self.defocusDiskSample(rng) else self.center;

        return Ray{
            .origin = ray_origin,
            .direction = px_sample.sub(ray_origin),
        };
    }

    fn defocusDiskSample(self: *const Camera, rng: std.Random) Vec3f {
        const p = Vec3f.randomInUnitDisk(rng);
        return self.center.add(self.defocus_u.scale(p.x)).add(self.defocus_v.scale(p.y));
    }

    fn rayColor(
        self: Camera,
        rng: std.Random,
        ray: Ray,
        world: *const HittableList,
        depth: u32,
    ) Vec3f {
        if (depth == 0) {
            return Vec3f.zero();
        }
        const interval = Interval{
            .min = 0.001,
            .max = std.math.inf(f64),
        };
        const hit = world.hit(ray, interval);
        if (hit) |record| {
            const scatter = record.material.scatter(rng, &ray, &record);

            if (scatter) |scatter_result| {
                return scatter_result.attenuation.mul(self.rayColor(rng, scatter_result.scattered, world, depth - 1));
            }
            return Vec3f.zero();
        }
        const unit_dir = ray.direction.scale(1.0 / ray.direction.length());
        const a = 0.5 * (unit_dir.y + 1.0);
        return Vec3f.init(1.0, 1.0, 1.0).scale(1.0 - a).add(Vec3f.init(0.5, 0.7, 1.0).scale(a));
    }
};
