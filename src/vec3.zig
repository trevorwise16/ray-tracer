const std = @import("std");
const Io = std.Io;
const utils = @import("math_utils.zig");

pub fn Vec3(comptime T: type) type {
    return struct {
        x: T,
        y: T,
        z: T,

        const Self = @This();

        pub fn init(x: T, y: T, z: T) Self {
            return Self{
                .x = x,
                .y = y,
                .z = z,
            };
        }

        pub fn zero() Self {
            return Self{
                .x = 0,
                .y = 0,
                .z = 0,
            };
        }

        pub fn lengthSquared(self: Self) T {
            return self.x * self.x + self.y * self.y + self.z * self.z;
        }

        pub fn length(self: Self) T {
            return std.math.sqrt(self.lengthSquared());
        }

        pub fn negate(self: Self) Self {
            return Self{
                .x = -self.x,
                .y = -self.y,
                .z = -self.z,
            };
        }

        pub fn add(self: Self, other: Self) Self {
            return Self{
                .x = self.x + other.x,
                .y = self.y + other.y,
                .z = self.z + other.z,
            };
        }

        pub fn sub(self: Self, other: Self) Self {
            return Self{
                .x = self.x - other.x,
                .y = self.y - other.y,
                .z = self.z - other.z,
            };
        }

        pub fn mul(self: Self, other: Self) Self {
            return Self{
                .x = self.x * other.x,
                .y = self.y * other.y,
                .z = self.z * other.z,
            };
        }

        pub fn scale(self: Self, scalar: T) Self {
            return Self{
                .x = self.x * scalar,
                .y = self.y * scalar,
                .z = self.z * scalar,
            };
        }

        pub fn dot(self: Self, other: Self) T {
            return self.x * other.x + self.y * other.y + self.z * other.z;
        }

        pub fn cross(self: Self, other: Self) Self {
            return Self{
                .x = self.y * other.z - self.z * other.y,
                .y = self.z * other.x - self.x * other.z,
                .z = self.x * other.y - self.y * other.x,
            };
        }

        pub fn unit(self: Self) Self {
            const len = self.length();
            return Self{
                .x = self.x / len,
                .y = self.y / len,
                .z = self.z / len,
            };
        }

        pub fn nearZero(self: Self) bool {
            const s = 1.0e-8;
            return (@abs(self.x) < s) and (@abs(self.y) < s) and (@abs(self.z) < s);
        }

        pub fn randomUnitInSphere(random: std.Random) Self {
            while (true) {
                const v = Self.randomInRange(random, -1.0, 1.0);
                const length_squared = v.lengthSquared();
                if (1.0e-160 < length_squared and length_squared < 1.0) {
                    // i know i already have length() available
                    // i'm avoiding recomputing length_squared
                    // unsure if this is meaningful but felt right
                    return v.scale(1.0 / std.math.sqrt(length_squared));
                }
            }
        }

        pub fn randomUnitInHemisphere(random: std.Random, normal: Self) Self {
            const in_sphere = Self.randomUnitInSphere(random);
            if (in_sphere.dot(normal) > 0.0) {
                return in_sphere;
            } else {
                return in_sphere.negate();
            }
        }

        pub fn randomInUnitDisk(random: std.Random) Self {
            while (true) {
                const v = Self{
                    .x = utils.randomF64InRange(random, -1.0, 1.0),
                    .y = utils.randomF64InRange(random, -1.0, 1.0),
                    .z = 0,
                };
                if (v.lengthSquared() < 1.0) {
                    return v;
                }
            }
        }

        pub fn randomInRange(random: std.Random, min: f64, max: f64) Self {
            return Self{
                .x = utils.randomF64InRange(random, min, max),
                .y = utils.randomF64InRange(random, min, max),
                .z = utils.randomF64InRange(random, min, max),
            };
        }

        pub fn reflect(v: Self, n: Self) Self {
            return v.sub(n.scale(2.0 * v.dot(n)));
        }

        pub fn refract(uv: Self, n: Self, etai_over_etat: f64) Self {
            const cos_theta: f64 = @min(uv.scale(-1).dot(n), 1.0);
            const r_out_perp = uv.add(n.scale(cos_theta)).scale(etai_over_etat);
            const r_out_parallel = n.scale(-std.math.sqrt(@abs(1.0 - r_out_perp.lengthSquared())));
            return r_out_perp.add(r_out_parallel);
        }
    };
}

test "basic Vec3 operations" {
    const u = Vec3(f64).init(1.0, 2.0, 3.0);
    const v = Vec3(f64).init(4.0, 5.0, 6.0);
    const z = Vec3(f64).zero();

    const uv = u.add(v);
    try std.testing.expect(uv.x == 5.0);
    try std.testing.expect(uv.y == 7.0);
    try std.testing.expect(uv.z == 9.0);

    const uz = u.dot(z);
    try std.testing.expect(uz == 0.0);

    const a = Vec3(f64).init(2.0, 2.0, -1.0);
    std.debug.assert(a.length() == 3.0);
}

test "near zero" {
    const v1 = Vec3(f64).init(1.0e-9, 0.0, 0.0);
    const v2 = Vec3(f64).init(0.0, 1.0e-9, 0.0);
    const v3 = Vec3(f64).init(0.0, 0.0, 1.0e-9);
    const v4 = Vec3(f64).init(1.0e-7, 0.0, 0.0);
    const v5 = Vec3(f64).init(-1.0e-9, -1.0e-9, -1.0e-9);
    const z = Vec3(f64).zero();

    try std.testing.expect(v1.nearZero());
    try std.testing.expect(v2.nearZero());
    try std.testing.expect(v3.nearZero());
    try std.testing.expect(!v4.nearZero());
    try std.testing.expect(v5.nearZero());
    try std.testing.expect(z.nearZero());
}
