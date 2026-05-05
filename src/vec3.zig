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

        pub fn unit(self: Self) Self {
            const len = self.length();
            return Self{
                .x = self.x / len,
                .y = self.y / len,
                .z = self.z / len,
            };
        }

        pub fn randomUnit(random: std.Random) Self {
            return Self{
                .x = utils.randomF64(random),
                .y = utils.randomF64(random),
                .z = utils.randomF64(random),
            };
        }

        pub fn randomInRange(random: std.Random, min: f64, max: f64) Self {
            return Self{
                .x = utils.randomF64InRange(random, min, max),
                .y = utils.randomF64InRange(random, min, max),
                .z = utils.randomF64InRange(random, min, max),
            };
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
