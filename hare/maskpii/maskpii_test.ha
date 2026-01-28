fn expect_case(m: *masker, input: str, expected: str) void = {
	let out = process(m, input)!;
	defer free(out);
	assert(out == expected, "masked output mismatch");
};

@test fn email_basic_cases() void = {
	let m = new();
	mask_emails(&m);

	expect_case(&m, "alice@example.com", "a****@example.com");
	expect_case(&m, "a@b.com", "*@b.com");
	expect_case(&m, "ab@example.com", "a*@example.com");
	expect_case(&m, "a.b+c_d@example.co.jp", "a******@example.co.jp");
};

@test fn email_mixed_text() void = {
	let m = new();
	mask_emails(&m);

	expect_case(&m, "Contact: alice@example.com.", "Contact: a****@example.com.");
	expect_case(&m, "alice@example.com and bob@example.org", "a****@example.com and b**@example.org");
};

@test fn email_edge_cases() void = {
	let m = new();
	mask_emails(&m);

	expect_case(&m, "alice@example", "alice@example");
	expect_case(&m, "alice@localhost", "alice@localhost");
	expect_case(&m, "alice@@example.com", "alice@@example.com");
	expect_case(&m, "first.last+tag@sub.domain.com", "f*************@sub.domain.com");
};

@test fn phone_basic_cases() void = {
	let m = new();
	mask_phones(&m);

	expect_case(&m, "090-1234-5678", "***-****-5678");
	expect_case(&m, "Call (555) 123-4567", "Call (***) ***-4567");
	expect_case(&m, "Intl: +81 3 1234 5678", "Intl: +** * **** 5678");
	expect_case(&m, "+1 (800) 123-4567", "+* (***) ***-4567");
};

@test fn phone_short_and_boundary_cases() void = {
	let m = new();
	mask_phones(&m);

	expect_case(&m, "1234", "1234");
	expect_case(&m, "12345", "*2345");
	expect_case(&m, "12-3456", "**-3456");
};

@test fn phone_mixed_text() void = {
	let m = new();
	mask_phones(&m);

	expect_case(&m, "Tel: 090-1234-5678 ext. 99", "Tel: ***-****-5678 ext. 99");
	expect_case(&m, "Numbers: 111-2222 and 333-4444", "Numbers: ***-2222 and ***-4444");
};

@test fn phone_edge_cases() void = {
	let m = new();
	mask_phones(&m);

	expect_case(&m, "abcdef", "abcdef");
	expect_case(&m, "+", "+");
	expect_case(&m, "(12) 345 678", "(**) **5 678");
};

@test fn combined_masking_cases() void = {
	let m = new();
	mask_emails(&m);
	mask_phones(&m);

	expect_case(&m, "Contact: alice@example.com or 090-1234-5678.",
		"Contact: a****@example.com or ***-****-5678.");
	expect_case(&m, "Email bob@example.org, phone +1 (800) 123-4567",
		"Email b**@example.org, phone +* (***) ***-4567");
};

@test fn custom_mask_char_cases() void = {
	let m = new();
	mask_emails(&m);
	mask_phones(&m);
	with_mask_char(&m, '#');

	expect_case(&m, "alice@example.com", "a####@example.com");
	expect_case(&m, "090-1234-5678", "###-####-5678");
	expect_case(&m, "Contact: alice@example.com or 090-1234-5678.",
		"Contact: a####@example.com or ###-####-5678.");
};

@test fn configuration_behavior() void = {
	let m = new();
	expect_case(&m, "alice@example.com", "alice@example.com");

	mask_emails(&m);
	expect_case(&m, "alice@example.com", "a****@example.com");
	expect_case(&m, "090-1234-5678", "090-1234-5678");

	let m2 = new();
	mask_phones(&m2);
	expect_case(&m2, "alice@example.com", "alice@example.com");
	expect_case(&m2, "090-1234-5678", "***-****-5678");
};

@test fn stability_checks() void = {
	let m = new();
	mask_emails(&m);
	mask_phones(&m);

	expect_case(&m, "Hello alice@example.com 090-1234-5678", "Hello a****@example.com ***-****-5678");
	expect_case(&m, "Repeat: alice@example.com, alice@example.com", "Repeat: a****@example.com, a****@example.com");
};
