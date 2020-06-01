const strings = @import("strings");
const string = strings.string;
const warn = @import("std").debug.warn;
const mem = @import("std").mem;
const debug = @import("std").debug;
const assert = debug.assert;
const io = @import("std").io;
const std = @import("std");


test "strings.equals" {
    var s = try string.init("this is a string");
    assert(s.equals("this is a string"));

    var s2 = try string.init("");
    assert(s2.equals(""));
}

test "strings.starts_endswith" {
    var s = try string.init("this is some data to work with");

    // startswith and endswith
    assert(s.startswith("this"));
    assert(s.startswith("this is some data to work with"));

    assert(s.endswith("with"));
    assert(s.endswith("this is some data to work with"));

}

test "strings.size" {
    var s = try string.init("this is some data to work with");
    assert(s.size() == 30);
}


test "strings.find_substring" {
    // find all instances of substrings
    var s = try string.init("this is some more data, SoMe some hey hey yo. APPLE DOG jump");
    var results = try s.find_all("some");

    assert(results.len == 2);
    assert(results[0] == 8);
    assert(results[1] == 29);

    // check if contains substring
    assert(s.contains("some"));
    assert(!s.contains("fountain"));
}

test "strings.upper_lower" {
    var s = try string.init("this is some more data, SoMe some hey hey yo. APPLE DOG jump");

    // upper and lowercase
    s.lower();
    assert(mem.eql(u8, s.buffer, "this is some more data, some some hey hey yo. apple dog jump"));
    s.upper();
    assert(mem.eql(u8, s.buffer, "THIS IS SOME MORE DATA, SOME SOME HEY HEY YO. APPLE DOG JUMP"));

    // swap upper to lower and vice versa
    var s2 = try string.init("this is some more data, SoMe some hey hey yo. APPLE DOG jump");
    s2.swapcase();
    assert(mem.eql(u8, s2.buffer, "THIS IS SOME MORE DATA, sOmE SOME HEY HEY YO. apple dog JUMP"));
}


test "strings.edit_distance" {
    // levenshtein edit distance
    var s3 = try string.init("apple");
    assert((try s3.levenshtein("snapple")) == @intCast(usize, 2));

    var s4 = try string.init("book");
    assert((try s4.levenshtein("burn")) == @intCast(usize, 3));

    var s5 = try string.init("pencil");
    assert((try s5.levenshtein("telephone")) == @intCast(usize, 8));

    var s6 = try string.init("flowers");
    assert((try s6.levenshtein("wolf")) == @intCast(usize, 6));
}

test "strings.replace" {
    var s = try string.init("this is some more data, SoMe some hey hey yo. APPLE DOG jump");

    // replace all instances of substring with another substring 
    try s.replace("some", "apple juice");
    assert(mem.eql(u8, s.buffer, "this is apple juice more data, SoMe apple juice hey hey yo. APPLE DOG jump"));
    
    try s.replace("apple juice", "mouse");
    assert(mem.eql(u8, s.buffer, "this is mouse more data, SoMe mouse hey hey yo. APPLE DOG jump"));

    try s.replace("jump", "cranberries");
    assert(mem.eql(u8, s.buffer, "this is mouse more data, SoMe mouse hey hey yo. APPLE DOG cranberries"));
}

test "strings.reverse" {
    // reverse a string
    var s = try string.init("this is a string");
    s.reverse();
    assert(mem.eql(u8, s.buffer, "gnirts a si siht"));
}

test "strings.concat" {
    var s = try string.init("hello there ");
    try s.concat("friendo");
    assert(mem.eql(u8, s.buffer, "hello there friendo"));
}

test "strings.strip" {
    // strip from the left
    var s = try string.init("  \tthis is a string  \n\r");
    try s.lstrip();
    assert(mem.eql(u8, s.buffer, "this is a string  \n\r"));

    // strip from the right
    var s2 = try string.init("  \tthis is a string  \n\r");
    try s2.rstrip();
    assert(mem.eql(u8, s2.buffer, "  \tthis is a string"));

    // strip both
    var s3 = try string.init("  \tthis is a string  \n\r");
    try s3.strip();
    assert(mem.eql(u8, s3.buffer, "this is a string"));
}

test "strings.count" {
    // count the number of occurances of a substring
    var s = try string.init("hello there, this is a string. strings are fun to play with.....string!!!!!");
    assert((try s.count("string")) == 3);
}


test "strings.split" {
    // split a string into a slice of strings, with single space as separator
    var s = try string.init("this is the string that I am going to split");
    var result = try s.split_to_u8(" ");

    assert(result.len == 10);

    assert(mem.eql(u8, result[0], "this"));
    assert(mem.eql(u8, result[3], "string"));
    assert(mem.eql(u8, result[6], "am"));
    assert(mem.eql(u8, result[9], "split"));

    var result2 = try s.split(" ");

    assert(result2[0].equals("this"));
    assert(result2[3].equals("string"));
    assert(result2[6].equals("am"));
    assert(result2[9].equals("split"));

    var s2 = try string.init(moby);
    var moby_split = try s2.split(" ");
    assert(moby_split.len == 198);

    var all_moby_dick = try read_file("test/moby_dick.txt");
    var moby_full = try string.init(all_moby_dick);
    var moby_full_split = try moby_full.split(" ");

    assert(moby_full_split.len == 192865);
}

var moby = 
\\Call me Ishmael. Some years ago—never mind how long precisely—having little or 
\\no money in my purse, and nothing particular to interest me on shore, I thought 
\\I would sail about a little and see the watery part of the world. It is a way I 
\\have of driving off the spleen and regulating the circulation. Whenever I find myself 
\\growing grim about the mouth; whenever it is a damp, drizzly November in my soul; 
\\whenever I find myself involuntarily pausing before coffin warehouses, and bringing 
\\up the rear of every funeral I meet; and especially whenever my hypos get such an 
\\upper hand of me, that it requires a strong moral principle to prevent me from 
\\deliberately stepping into the street, and methodically knocking people's hats off—then, 
\\I account it high time to get to sea as soon as I can. This is my substitute for 
\\pistol and ball. With a philosophical flourish Cato throws himself upon his sword; 
\\I quietly take to the ship. There is nothing surprising in this. If they but knew it, 
\\almost all men in their degree, some time or other, cherish very nearly the same feelings 
\\towards the ocean with me.
;

fn read_file(path: []const u8) ![]u8 {
    var allocator = std.heap.c_allocator;
    return try std.fs.Dir.readFileAlloc(std.fs.cwd(), allocator, path, 10 * 1000 * 1000);
}
