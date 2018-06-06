const strings = @import("../src/strings.zig");
const string = strings.string;
const warn = @import("std").debug.warn;
const mem = @import("std").mem;
const debug = @import("std").debug;
const assert = debug.assert;

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
    assert((try s3.levenshtein("snapple")) == usize(2));

    var s4 = try string.init("book");
    assert((try s4.levenshtein("burn")) == usize(3));

    var s5 = try string.init("pencil");
    assert((try s5.levenshtein("telephone")) == usize(8));

    var s6 = try string.init("flowers");
    assert((try s6.levenshtein("wolf")) == usize(6));
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