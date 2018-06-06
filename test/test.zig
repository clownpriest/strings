const strings = @import("../src/strings.zig");
const string = strings.string;
const warn = @import("std").debug.warn;
const mem = @import("std").mem;
const debug = @import("std").debug;
const assert = debug.assert;

test "strings" {
    var s1 = try string.init("this is some data to work with");

    // startswith and endswith
    assert(s1.startswith("this"));
    assert(s1.startswith("this is some data to work with"));

    assert(s1.endswith("with"));
    assert(s1.endswith("this is some data to work with"));

    // size
    assert(s1.size() == 30);

    // find all instances of substrings
    var s2 = try string.init("this is some more data, SoMe some hey hey yo. APPLE DOG jump");
    var results = try s2.find_all("some");

    // check if contains substring
    assert(s2.contains("some"));
    assert(!s2.contains("fountain"));

    // upper and lowercase
    s2.lower();
    assert(mem.eql(u8, s2.buffer, "this is some more data, some some hey hey yo. apple dog jump"));
    s2.upper();
    assert(mem.eql(u8, s2.buffer, "THIS IS SOME MORE DATA, SOME SOME HEY HEY YO. APPLE DOG JUMP"));

    // levenshtein edit distance
    var s3 = try string.init("apple");
    assert((try s3.levenshtein("snapple")) == usize(2));

    var s4 = try string.init("book");
    assert((try s4.levenshtein("burn")) == usize(3));

    var s5 = try string.init("pencil");
    assert((try s5.levenshtein("telephone")) == usize(8));

    var s6 = try string.init("flowers");
    assert((try s6.levenshtein("wolf")) == usize(6));

    // much more to come....
}