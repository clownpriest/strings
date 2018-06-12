const std = @import("std");
const mem = std.mem;
const debug = std.debug;
const assert = debug.assert;
const Allocator = mem.Allocator;

const ascii_upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
const ascii_lower = "abcdefghijklmnopqrstuvwxyz";

const ascii_upper_start: usize = 65;
const ascii_upper_end: usize = 90;
const ascii_lower_start: usize = 97;
const ascii_lower_end: usize = 122;

pub const string = struct {
    buffer: []u8,
    allocator: *Allocator,

    pub fn init(str: []const u8) !string {
        var buf = try std.heap.c_allocator.alloc(u8, str.len);
        for (str) |c, i| {
            buf[i] = c;
        }
        return string {
            .buffer = buf,
            .allocator = std.heap.c_allocator
        };
    }

    pub fn deinit(self: *const string) void {
        self.allocator.free(self.buffer);
    }

    // return the size of the string
    pub fn size(self: *const string) usize {
        return self.buffer.len;
    }

    // check if the string constains a substring
    pub fn contains(self: *const string, subs: []const u8) bool {
        var result = kmp(self, subs) catch unreachable;
        return result.len > 0;
    }

    // check if the string starts with the prefix
    // passed in as argument
    pub fn startswith(self: *const string, pfx: []const u8) bool {
        return mem.startsWith(u8, self.buffer, pfx);
    }

    // check if the string ends with the suffix
    // passed in as argument
    pub fn endswith(self: *const string, sfx: []const u8) bool {
        return mem.endsWith(u8, self.buffer, sfx);
    }

    // find all occurrences of a substring. returns a slice of indices
    // which indicate the beginning of a substring match.
    pub fn find_all(self: *const string, needle: []const u8) ![]usize {
        var indices: []usize = undefined;
        if (needle.len == 1 and needle[0] == ' ') {
            indices = try self.single_space_indices();
        } else {
           indices = try self.kmp(needle);
        }
        return indices;
    }

    // Knuth-Morris-Pratt substring search
    pub fn kmp(self: *const string, needle: []const u8) ![]usize {
        const m = needle.len;

        var border = try self.allocator.alloc(i64, m+1);
        defer self.allocator.free(border);
        border[0] = -1;

        var i: usize = 0;
        while (i < m): (i += 1) {
            border[i+1] = border[i];
            while (border[i+1] > -1 and needle[usize(border[i+1])] != needle[i]) {
                border[i+1] = border[usize(border[i+1])];
            }
            border[i+1]+=1;
        }

        // max possible needles you can find
        const max_found = self.buffer.len / needle.len; 
        
        var results = try self.allocator.alloc(usize, max_found);
        var n = self.buffer.len;
        var seen: i64 = 0;
        var j: usize = 0;
        var found: usize = 0;

        while (j < n): (j += 1) {
            while (seen > -1 and needle[usize(seen)] != self.buffer[j])  {
                seen = border[usize(seen)];
            }
            seen+=1;
            if (seen == i64(m)) {
                found += 1;
                results[found-1] = j-m+1;
                seen = border[m];
            }
        }
        results = try self.allocator.realloc(usize, results, found);
        return results;
    }


    // compute the levenshtein edit distance to another string
    pub fn levenshtein(self: *const string, other: []const u8) !usize {
        var prevrow = try self.allocator.alloc(usize, other.len+1);
        var currrow = try self.allocator.alloc(usize, other.len+1);
        defer self.allocator.free(prevrow);
        defer self.allocator.free(currrow);

        return self.buffered_levenshtein(other, prevrow, currrow);
    }

    // compute the levenshtein distance to another string
    // this function expects pre-allocated buffers as input
    // the calling code is responsible for freeing this memory
    pub fn buffered_levenshtein(self: *const string, other: []const u8, 
                                prevrow: []usize, currrow: []usize) usize {
        assert(prevrow.len >= other.len+1);
        assert(currrow.len >= other.len+1);

        var i: usize = 0;
        while (i <= other.len): (i += 1) {
            prevrow[i] = i;
        }

        i = 1;
        while (i <= self.buffer.len): (i += 1) {
            currrow[0] = i;
            var j: usize = 1;
            while (j <= other.len): (j += 1) {
                if (self.buffer[i-1] == other[j-1]) {
                    currrow[j] = prevrow[j-1];
                } else {
                    currrow[j] = @inlineCall(min, prevrow[j]+1,
                    currrow[j-1]+1,
                    prevrow[j-1]+1);
                }
            }
            mem.copy(usize, prevrow, currrow);
        }
        return currrow[other.len];
    }

    // replace all instances of "before" with "after"
    pub fn replace(self: *string, before: []const u8, after: []const u8) !void {
        var indices = try self.kmp(before);
        if (indices.len == 0) return;
        var diff = i128(before.len) - i128(after.len);
        // var it = indices.iterator();
        var new_size: usize = 0;
        if (diff == 0) { // no need to resize buffer
            for (indices) |n| { 
                mem.copy(u8, self.buffer[n..n+after.len], after);
            }
            return;
        } else if (diff < 0) { // grow buffer
            diff = diff * -1;
            new_size = self.buffer.len + (indices.len*usize(diff));
        } else { // shrink buffer
            new_size = self.buffer.len - (indices.len*usize(diff));
        }
        var new_buff = try self.allocator.alloc(u8, new_size);
        var i: usize = 0;
        var j: usize = 0;
        for (indices) |n| {
            while (i < self.buffer.len) {
                if (i < n) {
                    new_buff[j] = self.buffer[i];
                    i += 1;
                    j += 1;
                } else  {
                    mem.copy(u8, new_buff[j..j+after.len], after);
                    i += before.len;
                    j += after.len;
                    break;
                }
            }
        }
        if (j < new_buff.len) {
            mem.copy(u8, new_buff[j..], self.buffer[i..]);
        }
        self.allocator.free(self.buffer);
        self.buffer = new_buff;
    }

    // reverse the string
    pub fn reverse(self: *const string) void {
        mem.reverse(u8, self.buffer);
    }

    // convert all characters to lowercase
    pub fn lower(self: *const string) void {
        for (self.buffer) |c, i| {
            if (ascii_upper_start <= c and c <= ascii_upper_end) {
                self.buffer[i] = ascii_lower[@inlineCall(upper_map, c)];
            }
        }
    }

    // convert all characters to uppercase
    pub fn upper(self: *const string) void {
        for (self.buffer) |c, i| {
            if (ascii_lower_start <= c and c <= ascii_lower_end) {
                self.buffer[i] = ascii_upper[@inlineCall(lower_map, c)];
            }
        }
    }

    // convert all characters to their opposite case.
    pub fn swapcase(self: *const string) void {
        for (self.buffer) |c, i| {
            if (ascii_lower_start <= c and c <= ascii_lower_end) {
                self.buffer[i] = ascii_upper[@inlineCall(lower_map, c)];
            } else if (ascii_upper_start <= c and c <= ascii_upper_end) {
                self.buffer[i] = ascii_lower[@inlineCall(upper_map, c)];
            }
        }
    }

    pub fn concat(self: *string, other: []const u8) !void {
        if (other.len == 0) return;
        const orig_len = self.buffer.len;
        self.buffer = try self.allocator.realloc(u8, self.buffer, 
                                                 self.size() + other.len);
        mem.copy(u8, self.buffer[orig_len..], other);
    }

    // strip whitespace from both beginning and end of string
    pub fn strip(self: *string) !void {
        var start: usize = 0;
        var end: usize = self.buffer.len;

        // find first occurence of non-whitespace char
        for (self.buffer) |c, i| {
            switch (c) {
                ' ', '\t', '\n', 11, '\r'  => continue,
                else =>   {
                    start = i;
                    break;
                },
            }
        }

        // find last occurance of non-whitespace char
        var i: usize = self.buffer.len-1;
        while (i >= 0): (i -= 1) {
            const c = self.buffer[i];
            switch (c) {
                ' ', '\t', '\n', 11, '\r'  => continue,
                else =>   {
                    end = i+1;
                    break;
                },
            }
        }

        var new_buff = try self.allocator.alloc(u8, end - start);
        mem.copy(u8, new_buff, self.buffer[start..end]);

        self.allocator.free(self.buffer);
        self.buffer = new_buff;
    }

    // strip whitespace from the left of the string
    pub fn lstrip(self: *string) !void {
        var start: usize = 0;
        // find first occurence of non-whitespace char
        for (self.buffer) |c, i| {
            switch (c) {
                ' ', '\t', '\n', 11, '\r'  => continue,
                else =>   {
                    start = i;
                    break;
                },
            }
        }

        var new_buff = try self.allocator.alloc(u8, self.buffer.len - start);
        mem.copy(u8, new_buff, self.buffer[start..self.buffer.len]);

        self.allocator.free(self.buffer);
        self.buffer = new_buff;
    }

    // strip whitespace from the right of the string
    pub fn rstrip(self: *string) !void {
        var end: usize = self.buffer.len;

        // find last occurance of non-whitespace char
        var i: usize = self.buffer.len-1;
        while (i >= 0): (i -= 1) {
            var c = self.buffer[i];
            switch (c) {
                ' ', '\t', '\n', 11, '\r'  => continue,
                else =>   {
                    end = i+1;
                    break;
                },
            }
        }

        var new_buff = try self.allocator.alloc(u8, end);
        mem.copy(u8, new_buff, self.buffer[0..end]);

        self.allocator.free(self.buffer);
        self.buffer = new_buff;
    }

    // split the string by a specified separator, returning
    // an ArrayList of []u8. 
    pub fn split_to_u8(self: *const string, sep: []const u8) ![][]const u8 {
        var indices = try @inlineCall(self.find_all, sep);

        var results = try self.allocator.alloc([]const u8, indices.len+1);
        var i: usize = 0;
        for (indices) |n, j|  {
            results[j] = self.buffer[i..n];
            i = n+sep.len;
        }
        if (i < self.buffer.len) {
            results[indices.len] = self.buffer[i..];
        }
        return results;
    }

    // split the string by a specified separator, returning
    // an slice of string pointers.
    pub fn split(self: *const string, sep: []const u8) ![]string {
        var indices = try self.find_all(sep);

        var results = try self.allocator.alloc(string, indices.len+1);
        var i: usize = 0;
        for (indices) |n, j| {
            results[j] = try string.init(self.buffer[i..n]);
            i = n+sep.len;
        }

        if (i < self.buffer.len) {
            results[indices.len] = try string.init(self.buffer[i..]);
        }
        return results;
    }

    // count the number of occurances of a substring
    pub fn count(self: *const string, substr: []const u8) !usize {
        var subs = try self.find_all(substr);
        return subs.len;
    }

    // check if another string is equal to this one
    pub fn equals(self: *const string, other: []const u8) bool {
        return mem.eql(u8, self.buffer, other);
    }

    pub fn single_space_indices(self: *const string) ![]usize {
        var results = try self.allocator.alloc(usize, self.buffer.len);
        var i: usize = 0;
        for (self.buffer) |c, j| {
            if (c == ' ') {
                results[i] = j;
                i += 1;
            }
        }
        results = try self.allocator.realloc(usize, results, i);
        return results[0..];
    }

    pub fn all_space_indices(self: *const string) ![]usize {
        var results = try self.allocator.alloc(usize, self.buffer.len);
        var i: usize = 0;
        for (self.buffer) |c, j| {
            switch (c) {
                ' ', '\t', '\n', 11, '\r'  =>
                {
                    results[i] = j;
                    i += 1;
                }, 
                else => continue,
            }
        }
        results = try self.allocator.realloc(usize, results, i);
        return results;
    }
};

fn upper_map(c: u8) usize {
    return c - ascii_upper_start;
}

fn lower_map(c: u8) usize {
    return c - ascii_lower_start;
}

fn min(x: usize, y: usize, z: usize) usize {
    var result = x;
    if (y < result) {
        result = y;
    } else if (z < result) {
        result = z;
    }
    return result;
}
