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

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var stdout_writer = std.Io.File.stdout().writer(io, &.{});
    var stdout = &stdout_writer.interface;
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

    try stdout.print("word_len: {d}\n", .{word_len});
    try stdout.print("word: {s}\n", .{word[0..word_len]});
    const p = calculate_parity_bits(word_len);
    try stdout.print("p = {d}\n", .{p});
    const new_word = make_new_word(word[0..word_len], p);
    try stdout.print("new_word = {s}\n", .{new_word});
    // const syndrome = make_syndrome(word, p);
    // stdout.print("syndrome = {any}\n", .{syndrome}) catch unreachable;
    // const encoded_word = make_encoded_word(syndrome, new_word);
    // stdout.print("encoded_word = {any}\n", .{encoded_word}) catch unreachable;
}

fn calculate_parity_bits(word_len:usize) usize {
    // find the number of parity bits p

    // smart, "mathematical" solution
    var p:usize = 1;
    p = 1 + std.math.log2(word_len + p + 1);

    // imperative solution using a loop
    // var i: usize = 0;
    // while (std.math.pow(usize, 2, i) <= word_len+i+1) : (i+=1) {}
    //
    return p;
}

fn make_new_word(word:[]u8, p:usize) []u8 {
    //put 'p' where the parity bits should be
    //
    var new_word:[]u8 = alloc.alloc(u8, p + word.len) catch unreachable;
    defer alloc.free(new_word);

    var j:usize = 0;
    for (new_word, 0..) |_, i|{
        // evil bit-wise AND trick to avoid a third iterator
        // basically any number 2^n AND 2^n-1 == 0 is going to be a power of 2
        if (((i+1) & i) == 0) {
            new_word[i] = 'p';
        }
        else {
            new_word[i] = word[j];
            j+=1;
        }
    }
    std.debug.print("new_word = {s}\n", .{new_word});
    return new_word;
}

fn make_syndrome(word:[]u8, p:usize) []u1 {
    // calculate the values of parity bits
    var syndrome:[]u1 = alloc.alloc(u1, p) catch unreachable;
    defer alloc.free(syndrome);
    var k:usize = 0;
    // var final_word:[word.len]u1 = undefined;
    while (k < p) : (k+=1){
        const p_pos = std.math.pow(usize, 2, k);
        var l:usize = 0;
        var sum:usize = 0;
        while (l < word.len) : (l+=1) {
            // wicked bit-wise AND trick to check position
            // basically all positions checked by parity bit k will have that bit set to 1
            // so doing k AND position will give us whether the bit should be checked
            if (((l+1) & p_pos) != 0) {
                sum += if (word[l] != 'p') word[l]-'0' else 0;
            }
        }
        std.debug.print("sum = {d}\n", .{sum});
        syndrome[k] = if (sum%2==0) 0 else 1;
    }
    return syndrome;
}


fn make_encoded_word(syndrome:[]u1, word:[]u8) []u1 {
    var encoded_word: []u1 = undefined;
    for (word, 0..) |bit, i| {
        if (bit == 'p') {
            encoded_word[i] = syndrome[std.math.floorPowerOfTwo(usize, i+1)];
        } else {
            encoded_word[i] = @intCast((word[i] - '0'));
        }
    }
    return encoded_word;
}
