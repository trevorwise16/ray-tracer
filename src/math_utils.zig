const std = @import("std");
const Io = std.Io;

pub fn degreesToRadians(degrees: f64) f64 {
    return degrees * std.math.pi / 180.0;
}

pub fn randomF64(random: std.Random) f64 {
    return random.float(f64);
}

pub fn randomF64InRange(random: std.Random, min: f64, max: f64) f64 {
    return min + (max - min) * randomF64(random);
}
