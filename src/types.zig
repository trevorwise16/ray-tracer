const std = @import("std");
const Vec3f = @import("vec3.zig").Vec3(f64);
const Ray = @import("ray.zig").Ray;
const Material = @import("materials.zig").Material;

pub const HitRecord = struct {
    point: Vec3f,
    normal: Vec3f,
    t: f64,
    front_face: bool,
    material: Material,
};
