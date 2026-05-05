const std = @import("std");
const Vec3f = @import("vec3.zig").Vec3(f64);

pub fn writeColor(writer: *std.Io.Writer, color: Vec3f) !void {
    const r: u8 = @intFromFloat(color.x * 255.999);
    const g: u8 = @intFromFloat(color.y * 255.999);
    const b: u8 = @intFromFloat(color.z * 255.999);

    try writer.print("{} {} {}\n", .{ r, g, b });
}
