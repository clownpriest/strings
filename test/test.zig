const string = @import("../src/strings.zig").string;
const warn = @import("std").debug.warn;
const mem = @import("std").mem;
const debug = @import("std").debug;
const assert = debug.assert;

test "strings" {
    var s1 = try string.init("this is some data to work with");

    assert(s1.startswith("this"));
    assert(s1.startswith("this is some data to work with"));

    assert(s1.endswith("with"));
    assert(s1.endswith("this is some data to work with"));

    assert(s1.size() == 30);

    var s2 = try string.init("this is some more data, SoMe some hey hey yo. APPLE DOG jump");
    var results = try s2.find_all("some");

    assert(s2.contains("some"));
    assert(!s2.contains("apple"));
    s2.lower();
    assert(mem.eql(u8, s2.buffer, "this is some more data, some some hey hey yo. apple dog jump"));
    s2.upper();
    assert(mem.eql(u8, s2.buffer, "THIS IS SOME MORE DATA, SOME SOME HEY HEY YO. APPLE DOG JUMP"));
}