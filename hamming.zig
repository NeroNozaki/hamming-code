const std = @import("std");
const libz = @import("libz/libz.zig");
var dba = std.heap.DebugAllocator(.{}){};
const alloc = dba.allocator();
const getchar = libz.getchar;
const putchar = libz.putchar;
const printf = libz.printf;

// take in a binary sequence
// calculate how number of parity bits and generate them
// detect errors and correct them if possible
// then, print the whole process:
// original data, parity bits, codified word,
// detected error and corrected word

pub fn main() !void {
    defer _ = dba.deinit();
    var capacity: usize = 16;
    var word_len: usize = 0;
    var word:[]u8 = alloc.alloc(u8, capacity) catch @panic("out of memory, i think");
    defer alloc.free(word);

    while (getchar()) |c| {
        if (c == '\n') {
            word[word_len] = '\n';
            word_len+=1;
            break;
        }
        if (word_len == capacity) {
            capacity *= 2;
            if(!alloc.resize(word, capacity))
                word = alloc.realloc(word, capacity) catch @panic("out of memory, i think.");
        }

        word[word_len] = c;
        word_len+=1;
    }

    _ = printf("word_len: {d}\n", .{word_len});
    _ = printf("word: {s}", .{word[0..word_len]});
}

fn calculate_parity_bits(word:[]usize, word_len:usize) void {
    var n: usize = 0;
    while (std.math.pow(usize, 2, n) <= word_len+n+1) : (n+=1) {
        _ = printf("n = {d}\n", .{n});
    }
    _ = word;
}
