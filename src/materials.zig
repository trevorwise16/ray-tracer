const std = @import("std");
const Ray = @import("ray.zig").Ray;
const Vec3f = @import("vec3.zig").Vec3(f64);
const HitRecord = @import("types.zig").HitRecord;
const utils = @import("math_utils.zig");

pub const ScatterResult = struct {
    scattered: Ray,
    attenuation: Vec3f,
};

pub const Lambertian = struct {
    albedo: Vec3f,
};

pub const Metal = struct {
    albedo: Vec3f,
    fuzz: f64,
};

pub const Dielectric = struct {
    ref_idx: f64,
};

pub const Material = union(enum) {
    lambertian: Lambertian,
    metal: Metal,
    dielectric: Dielectric,

    pub fn scatter(self: Material, rng: std.Random, ray_in: *const Ray, hit_record: *const HitRecord) ?ScatterResult {
        return switch (self) {
            .lambertian => lambertianScatter(rng, self.lambertian, hit_record),
            .metal => metalScatter(rng, ray_in, self.metal, hit_record),
            .dielectric => dielectricScatter(rng, ray_in, self.dielectric, hit_record),
        };
    }
};

pub fn dielectricScatter(rng: std.Random, ray_in: *const Ray, mat: Dielectric, hit_record: *const HitRecord) ?ScatterResult {
    const attenuation = Vec3f.init(1.0, 1.0, 1.0);
    const ri = if (hit_record.front_face) 1.0 / mat.ref_idx else mat.ref_idx;

    const unit_direction = ray_in.direction.unit();

    const cos_theta = @min(unit_direction.scale(-1).dot(hit_record.normal), 1.0);
    const sin_theta = std.math.sqrt(1.0 - cos_theta * cos_theta);

    const cannot_refract = ri * sin_theta > 1.0;
    const reflect = reflectance(cos_theta, ri) > utils.randomF64(rng);

    const direction: Vec3f = if (cannot_refract or reflect)
        unit_direction.reflect(hit_record.normal)
    else
        unit_direction.refract(hit_record.normal, ri);

    const scattered = Ray{ .origin = hit_record.point, .direction = direction };
    return ScatterResult{
        .scattered = scattered,
        .attenuation = attenuation,
    };
}

pub fn metalScatter(rng: std.Random, ray_in: *const Ray, mat: Metal, hit_record: *const HitRecord) ?ScatterResult {
    var scatter_direction = ray_in.direction.reflect(hit_record.normal);

    scatter_direction = scatter_direction.unit().add(Vec3f.randomUnitInSphere(rng).scale(mat.fuzz));

    const scattered = Ray{
        .origin = hit_record.point,
        .direction = scatter_direction,
    };

    return ScatterResult{
        .scattered = scattered,
        .attenuation = mat.albedo,
    };
}

pub fn lambertianScatter(rng: std.Random, mat: Lambertian, hit_record: *const HitRecord) ?ScatterResult {
    var scatter_direction = hit_record.normal.add(Vec3f.randomUnitInSphere(rng));

    if (scatter_direction.nearZero()) {
        scatter_direction = hit_record.normal;
    }

    const scattered = Ray{
        .origin = hit_record.point,
        .direction = scatter_direction,
    };

    return ScatterResult{
        .scattered = scattered,
        .attenuation = mat.albedo,
    };
}

fn reflectance(cos: f64, ref_idx: f64) f64 {
    var r0 = (1.0 - ref_idx) / (1.0 + ref_idx);
    r0 = r0 * r0;
    return r0 + (1.0 - r0) * std.math.pow(f64, 1.0 - cos, 5);
}

test "lambertian scatter" {
    var prng = std.Random.DefaultPrng.init(std.testing.random_seed);
    const rng = prng.random();

    const material = Material{ .lambertian = Lambertian{ .albedo = Vec3f.init(0.5, 0.5, 0.5) } };
    const ray_in = Ray{
        .origin = Vec3f.init(0, 0, 0),
        .direction = Vec3f.init(1, 0, 0),
    };
    const hit_record = HitRecord{
        .point = Vec3f.init(1, 0, 0),
        .normal = Vec3f.init(-1, 0, 0),
        .t = 1,
        .front_face = true,
        .material = material,
    };
    const result = material.scatter(rng, &ray_in, &hit_record);

    try std.testing.expectEqual(material.lambertian.albedo, result.?.attenuation);
    try std.testing.expect(result.?.scattered.direction.dot(hit_record.normal) > 0);
    try std.testing.expectEqual(hit_record.point, result.?.scattered.origin);
}
