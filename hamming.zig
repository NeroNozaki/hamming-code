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
    defer _ = dba.deinit();
    const io = init.io;
    var stdout_writer = std.Io.File.stdout().writer(io, &.{});
    var stdin_reader = std.Io.File.stdin().reader(io, &.{});
    const stdout = &stdout_writer.interface;
    const stdin = &stdin_reader.interface;

    var input_word = std.ArrayList(u8).empty;
    var input_word2 = std.ArrayList(u8).empty;
    defer input_word.deinit(alloc);
    defer input_word2.deinit(alloc);

    try stdout.print("Insert the correct word (without the parity bits): ", .{});
    const word1:[]u8 = take_input(&input_word, stdin) catch unreachable;

    try stdout.print("Correct word data: \n", .{});
    try stdout.print("[\n", .{});
    try stdout.print("    word_len: {d}\n", .{word1.len});
    try stdout.print("    word: {s}\n", .{word1});

    const p:usize = calculate_parity_bits(word1.len);
    try stdout.print("    p = {d}\n", .{p});

    var new_word:[]u8 = alloc.alloc(u8, p + word1.len) catch unreachable;
    defer alloc.free(new_word);

    new_word = make_new_word(new_word, word1);
    try stdout.print("    new_word = {s}\n", .{new_word});

    var p_bits:[]u8 = alloc.alloc(u8, p) catch unreachable;
    defer alloc.free(p_bits);

    p_bits = check_parity(p_bits, new_word, p);
    try stdout.print("    p_bits = {s}\n", .{p_bits});

    var codeword1:[]u8 = alloc.alloc(u8, new_word.len) catch unreachable;
    var codeword2:[]u8 = alloc.alloc(u8, new_word.len) catch unreachable;
    defer {
        alloc.free(codeword1);
        alloc.free(codeword2);
    }

    codeword1 = make_codeword(codeword1, p_bits, new_word);
    try stdout.print("    codeword = {s}\n", .{codeword1});
    try stdout.print("[\n", .{});

    try stdout.print("\nInsert the incorrect word (without the parity bits): ", .{});
    const word2:[]u8 = take_input(&input_word2, stdin) catch unreachable;

    var new_word2:[]u8 = alloc.alloc(u8, p + word2.len) catch unreachable;
    defer alloc.free(new_word2);
    new_word2 = make_new_word(new_word2, word2);
    codeword2 = make_codeword(codeword2, p_bits, new_word2);

    const number_of_errors = check_for_errors(word1, word2) catch |err| {
        std.debug.print("Error: {}\n", .{err});
        std.debug.print("Words must be the same length\n", .{});
        return err;
    };

    if (number_of_errors == 1) {
        const fixed_word:[]u8, const syndrome:usize = fix_errors(codeword2, p);
        try stdout.print("\nError detected at position {d}\n", .{syndrome});
        try stdout.print("Fixed word: {s}\n", .{fixed_word});
    }
    else {
        try stdout.print("Word has more than one bit flipped.\n", .{});
    }
}

fn fix_errors(codeword:[]u8, p:usize) struct {[]u8, usize} {
    var syndrome = alloc.alloc(u8, p) catch unreachable;
    defer alloc.free(syndrome);
    syndrome = check_parity(syndrome, codeword, p);

    var value:usize = 0;
    for (syndrome, 0..) |bit, i| {
        value += @as(usize, bit-'0') << @intCast(i);
    }

    var fixed_word = codeword;
    fixed_word[value-1] = if (fixed_word[value-1] == '1') '0' else '1';

    return .{fixed_word, value};
}

fn check_for_errors(word1:[]u8, word2:[]u8) !u8 {
    if (word1.len != word2.len) {
        return error.mismatchedLengths;
    }

    var i:usize = 0;
    var number_of_errors:u8 = 0;
    while (i < word1.len or i < word2.len) : (i+=1) {
        if (word1[i] == 'p' or word2[i] == 'p') {
            continue;
        }
        if (word1[i] != word2[i]) {
            number_of_errors+=1;
        }
    }
    return number_of_errors;
}

fn take_input(input_word:*std.array_list.Aligned(u8, null), stdin:anytype) ![]u8 {
    var input_byte:[1]u8 = undefined;

    while (true) {
        stdin.readSliceAll(&input_byte) catch break;

        const c = input_byte[0];
        if (c == '\n') break;

        try input_word.append(alloc, c);
    }
    return @constCast(std.mem.trimEnd(u8, input_word.items, "\r"));
}

fn calculate_parity_bits(word_len:usize) usize {
    // find the number of parity bits p

    // smart, "mathematical" solution
    // this doesn't work sometimes
    var p:usize = 1;
    p = 1 + std.math.log2(word_len + p + 1);

    // imperative solution using a loop
    // var p: usize = 0;
    while (std.math.pow(usize, 2, p) < word_len+p+1) : (p+=1) {}

    return p;
}

fn make_new_word(new_word:[]u8, word:[]u8) []u8 {
    //put 'p' where the parity bits should be
    //
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
    return new_word;
}

fn check_parity(p_bits:[]u8, new_word:[]u8, p:usize) []u8 {
    // calculate the values of parity bits
    // k is to iterate through the parity bits
    var k:usize = 0;
    while (k < p) : (k+=1){
        const p_pos = std.math.pow(usize, 2, k);
        // l is to iterate through the word
        var l:usize = 0;
        var sum:usize = 0;
        while (l < new_word.len) : (l+=1) {
            // wicked bit-wise AND trick to check position
            // basically all positions checked by parity bit k will have that bit set to 1
            // so doing k AND position will give us whether the bit should be checked
            if (((l+1) & p_pos) != 0) {
                sum += if (new_word[l] != 'p') new_word[l] else '0';
            }
        }
        // std.debug.print("sum = {d}\n", .{sum});
        p_bits[k] = if (sum%2==0) '0' else '1';
    }
    return p_bits;
}

fn make_codeword(codeword:[]u8, p_bits:[]u8, new_word:[]u8) []u8 {

    var j:usize = 0;
    for (new_word, 0..) |bit, i| {
        if (bit == 'p') {
            codeword[i] = p_bits[j];
            j+=1;
        } else {
            codeword[i] = @intCast((new_word[i]));
        }
    }
    return codeword;
}
