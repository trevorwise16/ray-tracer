const std = @import("std");
const Vec3f = @import("vec3.zig").Vec3(f64);

pub const Ray = struct {
    origin: Vec3f,
    direction: Vec3f,

    pub fn at(self: Ray, t: f64) Vec3f {
        return self.origin.add(self.direction.scale(t));
    }
};

test "basic ray" {
    const ray = Ray{
        .origin = Vec3f.init(1, 2, 3),
        .direction = Vec3f.init(4, 5, 6),
    };

    const point = ray.at(0.5);
    std.debug.print("point: {}, {}, {}\n", .{ point.x, point.y, point.z });
}
