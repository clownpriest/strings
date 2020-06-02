const string = @import("strings").string;
const time = @import("std").time;
const Timer = time.Timer;
const io = @import("std").io;
const std = @import("std");
const warn = @import("std").debug.warn;

fn read_file(path: []const u8) ![]u8 {
    var allocator = std.heap.c_allocator;
    return try std.fs.Dir.readFileAlloc(std.fs.cwd(), allocator, path, 2 * 1000 * 1000);
}

pub fn main() !void {

    var all_moby_dick = try read_file("test/moby_dick.txt");

    var timer = try Timer.start();
    var i: usize = 0;
    var moby_full = try string.init(all_moby_dick);

    var results: [1000]usize = undefined;

    const start = timer.lap();
    while (i < 1000): (i += 1) {
        // var x = try moby_full.single_space_indices();
        var x = try moby_full.split_to_u8(" ");
        results[i] = x.len;
    }
    const end = timer.read();

    warn("\nlen: {}\n", .{results[0]});
    const elapsed_s = @intToFloat(f64, end - start) / time.ns_per_s;
    warn("\nelapsed seconds: {:.3}\n\n", .{elapsed_s});
}
