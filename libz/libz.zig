const std = @import("std");
const linux = std.os.linux;
pub const Stack = @import("stack.zig").Stack;

pub fn getchar() ?u8 {
    var byte: [1]u8 = undefined;

    const result = linux.read(0, &byte, 1);

    if (result == 1) return byte[0];
    return null;
}

pub fn putchar(char:usize) usize {
    // make this function accept anytype of integer and convert to u8 if compatible.
    if (char > 255) {
        @panic("char must be a u8 compatible integer");
    }
    var c:u8 = @intCast(char);
    return linux.write(1, @ptrCast(&c), 1);
}

pub fn printf(comptime fmt: []const u8, args: anytype) usize {
    var result: usize = 0;
    comptime var arg_index: usize = 0;
    comptime var i: usize = 0;

    inline while (i < fmt.len) : (i += 1) {
        if (fmt[i] == '{') {
            i += 1;
            if (i >= fmt.len) @compileError("unclosed '{'");
            const specifier = fmt[i];
            i += 1;
            if (i >= fmt.len or fmt[i] != '}') @compileError("expected '}' after format specifier");

            // arg_index is comptime, so this selects the exact field type
            const arg = args[arg_index];
            switch (specifier) {
                'd' => result = print_int(arg),
                'c' => result = putchar(arg),
                'f' => {
                    // print argument as a float
                },
                's' => {
                    result = print_str(arg);
                },
                else => @compileError("unsupported format specifier"),
            }
            arg_index += 1;
            continue;
        }
        result = putchar(fmt[i]);
    }

    // optional but useful
    if (arg_index != args.len) {
        @compileError("wrong number of arguments for format string");
    }
    return result;
}

fn print_int(int:anytype) usize {
    var buf:[32]u8 = undefined;
    var i = buf.len;
    switch(@typeInfo(@TypeOf(int))) {
        .int => |info| {
            if (int == 0) {
                return linux.write(1, "0", 1);
            }
            if (info.signedness == .signed) {
                var x:u64 = if (int < 0) @abs(int) else @intCast(int);
                    
                while (x > 0) {
                    i -= 1;
                    buf[i] = '0' + @as(u8, @intCast(x % 10));
                    x /= 10;
                }
                if (int < 0) {
                    i-=1;
                    buf[i] = '-';
                }
                return linux.write(1, @ptrCast(&buf[i]), buf.len - i);
            } else {
                var x = int;
                while (x > 0) {
                    i -= 1;
                    buf[i] = '0' + @as(u8, @intCast(x % 10));
                    x /= 10;
                }
                return linux.write(1, @ptrCast(&buf[i]), buf.len - i);
            }
        },
        .comptime_int => {
            if (int < 0) {
                return print_int(@as(i64, int));
            } else {
                return print_int(@as(u64, int));
            }
        },
        .bool => {
            if (int) {
                return putchar('1');
            } else {
                return putchar('0');
            }
        },
        else => unreachable
    }
}
fn print_str(str:[]const u8) usize {
    var result:usize = 0;
    for(str) |char| {
        result = putchar(char);
        if (@as(isize, @bitCast(result)) < 0) return 1;
    }
    return 0;
}
