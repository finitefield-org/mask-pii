const std = @import("std");
const MaskPII = @import("mask-pii");

pub fn main() !void {
    var masker = MaskPII.Masker.init();
    _ = masker.maskEmails().maskPhones().withMaskChar('#');

    const allocator = std.heap.page_allocator;
    const input = "Contact: alice@example.com or 090-1234-5678.";
    const output = try masker.process(allocator, input);
    defer allocator.free(output);

    try std.io.getStdOut().writer().print("{s}\n", .{output});
}
