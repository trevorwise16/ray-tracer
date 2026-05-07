const std = @import("std");
const Io = std.Io;
const Vec3f = @import("vec3.zig").Vec3(f64);
const Interval = @import("interval.zig").Interval;

pub fn writeBuffer(io: Io, buffer: []Vec3f, img_height: u32, img_width: u32) !void {
    var buf: [4096]u8 = undefined;
    var stdout = Io.File.stdout().writer(io, &buf);
    const writer = &stdout.interface;

    try writer.print("P3\n{} {}\n255\n", .{ img_width, img_height });

    for (0..img_height) |j| {
        for (0..img_width) |i| {
            const color = buffer[j * img_width + i];
            try writeColor(writer, color);
        }
    }

    try writer.flush();
}

pub fn linearToGamma(linear_component: f64) f64 {
    if (linear_component > 0.0) {
        return std.math.sqrt(linear_component);
    }
    return 0.0;
}

pub fn writeColor(writer: *std.Io.Writer, color: Vec3f) !void {
    const interval = Interval{
        .min = 0.0,
        .max = 0.999,
    };

    const gamma_r = linearToGamma(color.x);
    const gamma_g = linearToGamma(color.y);
    const gamma_b = linearToGamma(color.z);

    const r: u8 = @intFromFloat(256 * interval.clamp(gamma_r));
    const g: u8 = @intFromFloat(256 * interval.clamp(gamma_g));
    const b: u8 = @intFromFloat(256 * interval.clamp(gamma_b));

    try writer.print("{} {} {}\n", .{ r, g, b });
}
