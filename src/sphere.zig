const std = @import("std");
const Vec3f = @import("vec3.zig").Vec3(f64);
const Ray = @import("ray.zig").Ray;
const HitRecord = @import("types.zig").HitRecord;
const Interval = @import("interval.zig").Interval;

pub const Sphere = struct {
    center: Vec3f,
    radius: f64,

    pub fn hit(self: Sphere, ray: Ray, interval: Interval) ?HitRecord {
        const oc = self.center.sub(ray.origin);
        const a = ray.direction.dot(ray.direction);
        const h = oc.dot(ray.direction);
        const c = oc.dot(oc) - self.radius * self.radius;
        const discriminant = h * h - a * c;

        if (discriminant < 0) {
            return null;
        }

        const sqrt_d = std.math.sqrt(discriminant);

        // Find the nearest root that lies in the acceptable range.
        const near = (h - sqrt_d) / a;
        const far = (h + sqrt_d) / a;

        const root = if (interval.surrounds(near)) near else if (interval.surrounds(far)) far else return null;

        const point = ray.at(root);
        const normal = point.sub(self.center).scale(1.0 / self.radius);
        const front_face = ray.direction.dot(normal) < 0;

        return HitRecord{
            .point = point,
            .normal = if (front_face) normal else normal.scale(-1),
            .t = root,
            .front_face = front_face,
        };
    }
};

test "hitting a sphere" {
    const sphere = Sphere{
        .center = Vec3f.init(0, 0, -1),
        .radius = 0.5,
    };

    const ray = Ray{
        .origin = Vec3f.init(0, 0, 0),
        .direction = Vec3f.init(0, 0, -1),
    };

    const hit = sphere.hit(ray, Interval{ .min = 0.001, .max = std.math.inf(f64) });

    const expected = HitRecord{
        .point = Vec3f.init(0, 0, -0.5),
        .normal = Vec3f.init(0, 0, 1),
        .t = 0.5,
        .front_face = true,
    };

    const actual = hit.?;
    try std.testing.expectEqual(expected.point, actual.point);
}

test "miss" {
    const sphere = Sphere{
        .center = Vec3f.init(0, 0, 10),
        .radius = 1,
    };

    const ray = Ray{
        .origin = Vec3f.zero(),
        .direction = Vec3f.init(0, 0, -1),
    };

    const hit = sphere.hit(ray, Interval{ .min = 0.001, .max = std.math.inf(f64) });
    try std.testing.expect(hit == null);
}

test "inward and outward normals" {
    const ray = Ray{
        .origin = Vec3f.zero(),
        .direction = Vec3f.init(0, 0, -1),
    };

    const sphere_outward = Sphere{
        .center = Vec3f.init(0, 0, -1),
        .radius = 0.5,
    };

    const hit_outward = sphere_outward.hit(ray, Interval{ .min = 0.001, .max = std.math.inf(f64) }).?;
    try std.testing.expectEqual(Vec3f.init(0, 0, 1), hit_outward.normal);
    try std.testing.expect(hit_outward.front_face);

    const sphere_inward = Sphere{
        .center = Vec3f.init(0, 0, -1),
        .radius = 2,
    };

    const hit_inward = sphere_inward.hit(ray, Interval{ .min = 0.001, .max = std.math.inf(f64) }).?;
    try std.testing.expectEqual(Vec3f.init(0, 0, 1), hit_inward.normal);
    try std.testing.expect(!hit_inward.front_face);
}
