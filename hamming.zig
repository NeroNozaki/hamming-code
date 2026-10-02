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
    var word:[]u8 = alloc.alloc(u8, capacity) catch unreachable;
    defer alloc.free(word);

    while (getchar()) |c| {
        if (c == '\n') {
            break;
        }
        if (word_len == capacity) {
            capacity *= 2;
            if(!alloc.resize(word, capacity))
                word = alloc.realloc(word, capacity) catch unreachable;
        }

        word[word_len] = c;
        word_len+=1;
    }

    _ = printf("word_len: {d}\n", .{word_len});
    _ = printf("word: {s}\n", .{word[0..word_len]});
    calculate_parity_bits(word, word_len);
}

fn calculate_parity_bits(word:[]u8, word_len:usize) void {
    // var n: usize = 0;
    // while (std.math.pow(usize, 2, n) <= word_len+n+1) : (n+=1) {}
    var p:usize = 1;
    p = 1 + std.math.log2(word_len + p + 1);
    _ = printf("p = {d}\n", .{p});
    var new_word:[]u8 = alloc.alloc(u8, p + word_len) catch unreachable;
    defer alloc.free(new_word);

    var j:usize = 0;
    var k:usize = 0;
    for (new_word, 0..) |_, i|{
        if (i == std.math.pow(usize, 2, k)-1) {
            new_word[i] = 'p';
            k+=1;
        }
        else {
            new_word[i] = word[j];
            j+=1;
        }
    }
    _ = printf("new_word = {s}\n", .{new_word});
}


