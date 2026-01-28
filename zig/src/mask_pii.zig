const std = @import("std");

/// A configurable masker for common PII such as emails and phone numbers.
pub const Masker = struct {
    mask_email: bool,
    mask_phone: bool,
    mask_char: u8,

    /// Create a new masker with all masks disabled by default.
    pub fn init() Masker {
        return .{
            .mask_email = false,
            .mask_phone = false,
            .mask_char = '*',
        };
    }

    /// Enable email address masking.
    pub fn maskEmails(self: *Masker) *Masker {
        self.mask_email = true;
        return self;
    }

    /// Enable phone number masking.
    pub fn maskPhones(self: *Masker) *Masker {
        self.mask_phone = true;
        return self;
    }

    /// Set the character used for masking.
    pub fn withMaskChar(self: *Masker, c: u8) *Masker {
        self.mask_char = if (c == 0) '*' else c;
        return self;
    }

    /// Process input text and mask enabled PII patterns.
    ///
    /// The returned slice is allocated with the provided allocator and must be freed by the caller.
    pub fn process(self: *const Masker, allocator: std.mem.Allocator, input: []const u8) ![]u8 {
        if (!self.mask_email and !self.mask_phone) {
            return allocator.dupe(u8, input);
        }

        var result = try allocator.dupe(u8, input);
        errdefer allocator.free(result);

        if (self.mask_email) {
            const masked = try maskEmailsInText(allocator, result, self.mask_char);
            allocator.free(result);
            result = masked;
        }

        if (self.mask_phone) {
            const masked = try maskPhonesInText(allocator, result, self.mask_char);
            allocator.free(result);
            result = masked;
        }

        return result;
    }
};

fn maskEmailsInText(allocator: std.mem.Allocator, input: []const u8, mask_char: u8) ![]u8 {
    var output = std.ArrayList(u8).init(allocator);
    errdefer output.deinit();

    var last: usize = 0;
    var i: usize = 0;
    while (i < input.len) : (i += 1) {
        if (input[i] == '@') {
            var local_start = i;
            while (local_start > 0 and isLocalByte(input[local_start - 1])) {
                local_start -= 1;
            }
            const local_end = i;

            const domain_start = i + 1;
            var domain_end = domain_start;
            while (domain_end < input.len and isDomainByte(input[domain_end])) {
                domain_end += 1;
            }

            if (local_start < local_end and domain_start < domain_end) {
                var candidate_end = domain_end;
                var matched_end: ?usize = null;
                while (candidate_end > domain_start) {
                    const domain = input[domain_start..candidate_end];
                    if (isValidDomain(domain)) {
                        matched_end = candidate_end;
                        break;
                    }
                    candidate_end -= 1;
                }

                if (matched_end) |valid_end| {
                    const local = input[local_start..local_end];
                    const domain = input[domain_start..valid_end];
                    try output.appendSlice(input[last..local_start]);
                    try appendMaskedLocal(&output, local, mask_char);
                    try output.append('@');
                    try output.appendSlice(domain);
                    last = valid_end;
                    i = valid_end - 1;
                    continue;
                }
            }
        }
    }

    try output.appendSlice(input[last..]);
    return output.toOwnedSlice();
}

fn maskPhonesInText(allocator: std.mem.Allocator, input: []const u8, mask_char: u8) ![]u8 {
    var output = std.ArrayList(u8).init(allocator);
    errdefer output.deinit();

    var last: usize = 0;
    var i: usize = 0;
    while (i < input.len) : (i += 1) {
        if (isPhoneStart(input[i])) {
            var end = i;
            while (end < input.len and isPhoneChar(input[end])) {
                end += 1;
            }

            var digit_count: usize = 0;
            var last_digit_index: ?usize = null;
            var idx: usize = i;
            while (idx < end) : (idx += 1) {
                if (isDigit(input[idx])) {
                    digit_count += 1;
                    last_digit_index = idx;
                }
            }

            if (last_digit_index) |last_digit| {
                const candidate_end = last_digit + 1;
                if (digit_count >= 5) {
                    const candidate = input[i..candidate_end];
                    try output.appendSlice(input[last..i]);
                    try appendMaskedPhoneCandidate(&output, candidate, mask_char);
                    last = candidate_end;
                    i = candidate_end - 1;
                    continue;
                }
            }

            i = end - 1;
            continue;
        }
    }

    try output.appendSlice(input[last..]);
    return output.toOwnedSlice();
}

fn appendMaskedLocal(output: *std.ArrayList(u8), local: []const u8, mask_char: u8) !void {
    if (local.len > 1) {
        try output.append(local[0]);
        if (local.len > 1) {
            var idx: usize = 1;
            while (idx < local.len) : (idx += 1) {
                try output.append(mask_char);
            }
        }
        return;
    }
    try output.append(mask_char);
}

fn appendMaskedPhoneCandidate(output: *std.ArrayList(u8), candidate: []const u8, mask_char: u8) !void {
    var digit_count: usize = 0;
    for (candidate) |b| {
        if (isDigit(b)) {
            digit_count += 1;
        }
    }

    var current_index: usize = 0;
    for (candidate) |b| {
        if (isDigit(b)) {
            current_index += 1;
            if (digit_count > 4 and current_index <= digit_count - 4) {
                try output.append(mask_char);
            } else {
                try output.append(b);
            }
        } else {
            try output.append(b);
        }
    }
}

fn isLocalByte(b: u8) bool {
    return (b >= 'a' and b <= 'z') or
        (b >= 'A' and b <= 'Z') or
        (b >= '0' and b <= '9') or
        b == '.' or b == '_' or b == '%' or b == '+' or b == '-';
}

fn isDomainByte(b: u8) bool {
    return (b >= 'a' and b <= 'z') or
        (b >= 'A' and b <= 'Z') or
        (b >= '0' and b <= '9') or
        b == '-' or b == '.';
}

fn isValidDomain(domain: []const u8) bool {
    if (domain.len == 0 or domain[0] == '.' or domain[domain.len - 1] == '.') {
        return false;
    }

    var part_count: usize = 0;
    var part_start: usize = 0;
    var last_dot: ?usize = null;

    var idx: usize = 0;
    while (idx <= domain.len) : (idx += 1) {
        if (idx == domain.len or domain[idx] == '.') {
            const part = domain[part_start..idx];
            if (part.len == 0) {
                return false;
            }
            if (part[0] == '-' or part[part.len - 1] == '-') {
                return false;
            }
            for (part) |b| {
                if (!(isAlphaNumeric(b) or b == '-')) {
                    return false;
                }
            }
            part_count += 1;
            if (idx < domain.len and domain[idx] == '.') {
                last_dot = idx;
            }
            part_start = idx + 1;
        }
    }

    if (part_count < 2) {
        return false;
    }

    const tld_start = if (last_dot) |dot| dot + 1 else 0;
    const tld = domain[tld_start..];
    if (tld.len < 2) {
        return false;
    }
    for (tld) |b| {
        if (!isAlpha(b)) {
            return false;
        }
    }

    return true;
}

fn isPhoneStart(b: u8) bool {
    return isDigit(b) or b == '+' or b == '(';
}

fn isPhoneChar(b: u8) bool {
    return isDigit(b) or b == ' ' or b == '-' or b == '(' or b == ')' or b == '+';
}

fn isDigit(b: u8) bool {
    return b >= '0' and b <= '9';
}

fn isAlpha(b: u8) bool {
    return (b >= 'a' and b <= 'z') or (b >= 'A' and b <= 'Z');
}

fn isAlphaNumeric(b: u8) bool {
    return isAlpha(b) or isDigit(b);
}

fn processForTest(masker: *const Masker, allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    return masker.process(allocator, input);
}

test "masker configuration behavior" {
    const allocator = std.testing.allocator;

    var masker = Masker.init();
    const result = try processForTest(&masker, allocator, "alice@example.com");
    defer allocator.free(result);
    try std.testing.expectEqualStrings("alice@example.com", result);
}

test "email masking basic cases" {
    const allocator = std.testing.allocator;

    const cases = [_]struct {
        input: []const u8,
        expected: []const u8,
    }{
        .{ .input = "alice@example.com", .expected = "a****@example.com" },
        .{ .input = "a@b.com", .expected = "*@b.com" },
        .{ .input = "ab@example.com", .expected = "a*@example.com" },
        .{ .input = "a.b+c_d@example.co.jp", .expected = "a******@example.co.jp" },
    };

    for (cases) |case| {
        var masker = Masker.init();
        _ = masker.maskEmails();
        const result = try processForTest(&masker, allocator, case.input);
        defer allocator.free(result);
        try std.testing.expectEqualStrings(case.expected, result);
    }
}

test "email masking mixed text" {
    const allocator = std.testing.allocator;

    const cases = [_]struct {
        input: []const u8,
        expected: []const u8,
    }{
        .{ .input = "Contact: alice@example.com.", .expected = "Contact: a****@example.com." },
        .{ .input = "alice@example.com and bob@example.org", .expected = "a****@example.com and b**@example.org" },
    };

    for (cases) |case| {
        var masker = Masker.init();
        _ = masker.maskEmails();
        const result = try processForTest(&masker, allocator, case.input);
        defer allocator.free(result);
        try std.testing.expectEqualStrings(case.expected, result);
    }
}

test "email masking edge cases" {
    const allocator = std.testing.allocator;

    const cases = [_]struct {
        input: []const u8,
        expected: []const u8,
    }{
        .{ .input = "alice@example", .expected = "alice@example" },
        .{ .input = "alice@localhost", .expected = "alice@localhost" },
        .{ .input = "alice@@example.com", .expected = "alice@@example.com" },
        .{ .input = "first.last+tag@sub.domain.com", .expected = "f*************@sub.domain.com" },
    };

    for (cases) |case| {
        var masker = Masker.init();
        _ = masker.maskEmails();
        const result = try processForTest(&masker, allocator, case.input);
        defer allocator.free(result);
        try std.testing.expectEqualStrings(case.expected, result);
    }
}

test "phone masking basic cases" {
    const allocator = std.testing.allocator;

    const cases = [_]struct {
        input: []const u8,
        expected: []const u8,
    }{
        .{ .input = "090-1234-5678", .expected = "***-****-5678" },
        .{ .input = "Call (555) 123-4567", .expected = "Call (***) ***-4567" },
        .{ .input = "Intl: +81 3 1234 5678", .expected = "Intl: +** * **** 5678" },
        .{ .input = "+1 (800) 123-4567", .expected = "+* (***) ***-4567" },
    };

    for (cases) |case| {
        var masker = Masker.init();
        _ = masker.maskPhones();
        const result = try processForTest(&masker, allocator, case.input);
        defer allocator.free(result);
        try std.testing.expectEqualStrings(case.expected, result);
    }
}

test "phone masking short numbers and boundaries" {
    const allocator = std.testing.allocator;

    const cases = [_]struct {
        input: []const u8,
        expected: []const u8,
    }{
        .{ .input = "1234", .expected = "1234" },
        .{ .input = "12345", .expected = "*2345" },
        .{ .input = "12-3456", .expected = "**-3456" },
    };

    for (cases) |case| {
        var masker = Masker.init();
        _ = masker.maskPhones();
        const result = try processForTest(&masker, allocator, case.input);
        defer allocator.free(result);
        try std.testing.expectEqualStrings(case.expected, result);
    }
}

test "phone masking mixed text" {
    const allocator = std.testing.allocator;

    const cases = [_]struct {
        input: []const u8,
        expected: []const u8,
    }{
        .{ .input = "Tel: 090-1234-5678 ext. 99", .expected = "Tel: ***-****-5678 ext. 99" },
        .{ .input = "Numbers: 111-2222 and 333-4444", .expected = "Numbers: ***-2222 and ***-4444" },
    };

    for (cases) |case| {
        var masker = Masker.init();
        _ = masker.maskPhones();
        const result = try processForTest(&masker, allocator, case.input);
        defer allocator.free(result);
        try std.testing.expectEqualStrings(case.expected, result);
    }
}

test "phone masking edge cases" {
    const allocator = std.testing.allocator;

    const cases = [_]struct {
        input: []const u8,
        expected: []const u8,
    }{
        .{ .input = "abcdef", .expected = "abcdef" },
        .{ .input = "+", .expected = "+" },
        .{ .input = "(12) 345 678", .expected = "(**) **5 678" },
    };

    for (cases) |case| {
        var masker = Masker.init();
        _ = masker.maskPhones();
        const result = try processForTest(&masker, allocator, case.input);
        defer allocator.free(result);
        try std.testing.expectEqualStrings(case.expected, result);
    }
}

test "combined masking" {
    const allocator = std.testing.allocator;

    const cases = [_]struct {
        input: []const u8,
        expected: []const u8,
    }{
        .{ .input = "Contact: alice@example.com or 090-1234-5678.", .expected = "Contact: a****@example.com or ***-****-5678." },
        .{ .input = "Email bob@example.org, phone +1 (800) 123-4567", .expected = "Email b**@example.org, phone +* (***) ***-4567" },
    };

    for (cases) |case| {
        var masker = Masker.init();
        _ = masker.maskEmails();
        _ = masker.maskPhones();
        const result = try processForTest(&masker, allocator, case.input);
        defer allocator.free(result);
        try std.testing.expectEqualStrings(case.expected, result);
    }
}

test "custom mask character" {
    const allocator = std.testing.allocator;

    const cases = [_]struct {
        input: []const u8,
        expected: []const u8,
    }{
        .{ .input = "alice@example.com", .expected = "a####@example.com" },
        .{ .input = "090-1234-5678", .expected = "###-####-5678" },
        .{ .input = "Contact: alice@example.com or 090-1234-5678.", .expected = "Contact: a####@example.com or ###-####-5678." },
    };

    for (cases, 0..) |case, idx| {
        var masker = Masker.init();
        if (idx == 0) {
            _ = masker.maskEmails();
        } else if (idx == 1) {
            _ = masker.maskPhones();
        } else {
            _ = masker.maskEmails();
            _ = masker.maskPhones();
        }
        _ = masker.withMaskChar('#');
        const result = try processForTest(&masker, allocator, case.input);
        defer allocator.free(result);
        try std.testing.expectEqualStrings(case.expected, result);
    }
}
