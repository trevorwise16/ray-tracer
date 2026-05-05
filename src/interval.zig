const std = @import("std");

pub const Interval = struct {
    min: f64,
    max: f64,

    pub fn default() Interval {
        return Interval{
            .min = std.math.inf(f64),
            .max = -std.math.inf(f64),
        };
    }

    pub fn size(self: Interval) f64 {
        return self.max - self.min;
    }

    pub fn contains(self: Interval, value: f64) bool {
        return self.min <= value and value <= self.max;
    }

    pub fn surrounds(self: Interval, value: f64) bool {
        return self.min < value and value < self.max;
    }

    pub fn clamp(self: Interval, value: f64) f64 {
        return std.math.clamp(value, self.min, self.max);
    }
};
