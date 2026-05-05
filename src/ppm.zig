const std = @import("std");
const Io = std.Io;

pub fn write(io: Io) !void {
    var buf: [4096]u8 = undefined;
    var stdout = Io.File.stdout().writer(io, &buf);
    const writer = &stdout.interface;

    const img_height = 256;
    const img_width = 256;

    try writer.print("P3\n{} {}\n255\n", .{ img_width, img_height });

    for (0..img_height) |j| {
        std.debug.print("lines remaining: {}\n", .{img_height - j});
        for (0..img_width) |i| {
            const r: f64 = @as(f64, @floatFromInt(i)) / (img_width - 1);
            const g: f64 = @as(f64, @floatFromInt(j)) / (img_height - 1);
            const b = 0.0;

            const ir: u8 = @trunc(255.999 * r);
            const ig: u8 = @trunc(255.999 * g);
            const ib: u8 = @trunc(255.999 * b);

            try writer.print("{} {} {}\n", .{ ir, ig, ib });
        }
    }

    try writer.flush();
}
