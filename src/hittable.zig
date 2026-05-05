const std = @import("std");
const Vec3f = @import("vec3.zig").Vec3(f64);
const Sphere = @import("sphere.zig").Sphere;
const Ray = @import("ray.zig").Ray;
const HitRecord = @import("types.zig").HitRecord;
const Allocator = std.mem.Allocator;
const Interval = @import("interval.zig").Interval;

// fuck abstract classes
// all my homies like exhaustive unions
pub const Hittable = union(enum) {
    sphere: Sphere,

    pub fn hit(self: Hittable, ray: Ray, interval: Interval) ?HitRecord {
        return switch (self) {
            .sphere => self.sphere.hit(ray, interval),
        };
    }
};

pub const HittableList = struct {
    objects: std.ArrayList(Hittable),

    pub fn init() HittableList {
        return HittableList{
            .objects = .empty,
        };
    }

    pub fn add(self: *HittableList, allocator: Allocator, object: Hittable) !void {
        try self.objects.append(allocator, object);
    }

    pub fn clear(self: *HittableList, allocator: Allocator) void {
        self.objects.clearAndFree(allocator);
    }

    pub fn hit(self: *const HittableList, ray: Ray, interval: Interval) ?HitRecord {
        var closest: ?HitRecord = null;
        var closest_t = interval.max;
        for (self.objects.items) |object| {
            const maybe_hit = object.hit(ray, interval);
            if (maybe_hit) |record| {
                if (record.t < closest_t) {
                    closest = record;
                    closest_t = record.t;
                }
            }
        }
        return closest;
    }
};

test "hittable list returns closest hit" {
    const allocator = std.testing.allocator;
    var list = HittableList.init();
    defer list.clear(allocator);

    try list.add(allocator, Hittable{ .sphere = Sphere{ .center = Vec3f.init(0, 0, -1), .radius = 0.5 } });
    try list.add(allocator, Hittable{ .sphere = Sphere{ .center = Vec3f.init(0, 0, -3), .radius = 0.5 } });

    const ray = Ray{ .origin = Vec3f.init(0, 0, 0), .direction = Vec3f.init(0, 0, -1) };
    const result = list.hit(ray, Interval{ .min = 0.001, .max = std.math.inf(f64) });

    try std.testing.expect(result != null);
    try std.testing.expectEqual(@as(f64, 0.5), result.?.t);
}

test "hitting a hittable" {
    const hittable = Hittable{
        .sphere = Sphere{
            .center = Vec3f.init(0, 0, -1),
            .radius = 0.5,
        },
    };

    const ray = Ray{
        .origin = Vec3f.init(0, 0, 0),
        .direction = Vec3f.init(0, 0, -1),
    };

    const hit = hittable.hit(ray, Interval{ .min = 0.001, .max = std.math.inf(f64) });

    const expected = HitRecord{
        .point = Vec3f.init(0, 0, -0.5),
        .normal = Vec3f.init(0, 0, 1),
        .t = 0.5,
        .front_face = true,
    };

    const actual = hit.?;

    try std.testing.expectEqual(expected.point, actual.point);
    try std.testing.expectEqual(expected.normal, actual.normal);
    try std.testing.expectEqual(expected.t, actual.t);
}
