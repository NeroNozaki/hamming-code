const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

pub fn Stack(comptime T: type) type {
    return struct {
        const Self = @This();
        allocator:Allocator,
        capacity:usize,
        size:usize,
        elems:[]T,

        pub fn push(self: *Self, element:T) void {
            if (self.size == self.capacity) {
                self.capacity *= 2;
                if (self.capacity < 16) self.capacity = 16;
            }
            if(!self.allocator.resize(self.elems, self.capacity))
                self.elems = self.allocator.realloc(self.elems, self.capacity) catch @panic("out of memory, i think.");
            self.elems[self.size]=element;
            self.size+=1;
        }
        pub fn pop(self: *Self) T {
            assert(self.size > 0);
            self.size-=1;
            return self.elems[self.size];
        }
        pub fn empty(self: *Self) bool {
            return !self.size;
        }

        pub fn init(allocator:Allocator) Self {
            return .{
                .allocator = allocator,
                .capacity = @sizeOf(T),
                .size = 0,
                .elems = &[_]T{},
            };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.elems);
            self.* = undefined;
        }
    };
}

