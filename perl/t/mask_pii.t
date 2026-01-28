use strict;
use warnings;
use Test::More;

use lib 'lib';
use Mask::PII;

sub assert_cases {
    my ($masker, $cases) = @_;
    for my $case (@$cases) {
        my ($input, $expected) = @$case;
        is($masker->process($input), $expected, "input: $input");
    }
}

subtest 'email basic cases' => sub {
    my $masker = Mask::PII::Masker->new->mask_emails;
    assert_cases(
        $masker,
        [
            ['alice@example.com', 'a****@example.com'],
            ['a@b.com', '*@b.com'],
            ['ab@example.com', 'a*@example.com'],
            ['a.b+c_d@example.co.jp', 'a******@example.co.jp'],
        ],
    );
};

subtest 'email mixed text' => sub {
    my $masker = Mask::PII::Masker->new->mask_emails;
    assert_cases(
        $masker,
        [
            ['Contact: alice@example.com.', 'Contact: a****@example.com.'],
            [
                'alice@example.com and bob@example.org',
                'a****@example.com and b**@example.org',
            ],
        ],
    );
};

subtest 'email edge cases' => sub {
    my $masker = Mask::PII::Masker->new->mask_emails;
    assert_cases(
        $masker,
        [
            ['alice@example', 'alice@example'],
            ['alice@localhost', 'alice@localhost'],
            ['alice@@example.com', 'alice@@example.com'],
            [
                'first.last+tag@sub.domain.com',
                'f*************@sub.domain.com',
            ],
        ],
    );
};

subtest 'phone basic formats' => sub {
    my $masker = Mask::PII::Masker->new->mask_phones;
    assert_cases(
        $masker,
        [
            ['090-1234-5678', '***-****-5678'],
            ['Call (555) 123-4567', 'Call (***) ***-4567'],
            ['Intl: +81 3 1234 5678', 'Intl: +** * **** 5678'],
            ['+1 (800) 123-4567', '+* (***) ***-4567'],
        ],
    );
};

subtest 'phone short and boundary lengths' => sub {
    my $masker = Mask::PII::Masker->new->mask_phones;
    assert_cases(
        $masker,
        [
            ['1234', '1234'],
            ['12345', '*2345'],
            ['12-3456', '**-3456'],
        ],
    );
};

subtest 'phone mixed text' => sub {
    my $masker = Mask::PII::Masker->new->mask_phones;
    assert_cases(
        $masker,
        [
            ['Tel: 090-1234-5678 ext. 99', 'Tel: ***-****-5678 ext. 99'],
            ['Numbers: 111-2222 and 333-4444', 'Numbers: ***-2222 and ***-4444'],
        ],
    );
};

subtest 'phone edge cases' => sub {
    my $masker = Mask::PII::Masker->new->mask_phones;
    assert_cases(
        $masker,
        [
            ['abcdef', 'abcdef'],
            ['+', '+'],
            ['(12) 345 678', '(**) **5 678'],
        ],
    );
};

subtest 'combined masking' => sub {
    my $masker = Mask::PII::Masker->new->mask_emails->mask_phones;
    assert_cases(
        $masker,
        [
            [
                'Contact: alice@example.com or 090-1234-5678.',
                'Contact: a****@example.com or ***-****-5678.',
            ],
            [
                'Email bob@example.org, phone +1 (800) 123-4567',
                'Email b**@example.org, phone +* (***) ***-4567',
            ],
        ],
    );
};

subtest 'custom mask character' => sub {
    my $email_masker = Mask::PII::Masker->new->mask_emails->with_mask_char('#');
    my $phone_masker = Mask::PII::Masker->new->mask_phones->with_mask_char('#');
    my $combined = Mask::PII::Masker->new->mask_emails->mask_phones->with_mask_char('#');

    assert_cases($email_masker, [['alice@example.com', 'a####@example.com']]);
    assert_cases($phone_masker, [['090-1234-5678', '###-####-5678']]);

    is(
        $combined->process('Contact: alice@example.com or 090-1234-5678.'),
        'Contact: a####@example.com or ###-####-5678.',
        'combined custom mask',
    );
};

subtest 'masker configuration' => sub {
    my $input = 'alice@example.com 090-1234-5678';

    my $passthrough = Mask::PII::Masker->new;
    is($passthrough->process($input), $input, 'no masks enabled');

    my $email_only = Mask::PII::Masker->new->mask_emails;
    is($email_only->process($input), 'a****@example.com 090-1234-5678', 'email only');

    my $phone_only = Mask::PII::Masker->new->mask_phones;
    is($phone_only->process($input), 'alice@example.com ***-****-5678', 'phone only');

    my $both = Mask::PII::Masker->new->mask_emails->mask_phones;
    is($both->process($input), 'a****@example.com ***-****-5678', 'email and phone');
};

subtest 'non-ascii text is preserved' => sub {
    my $masker = Mask::PII::Masker->new->mask_emails->mask_phones;
    my $input = '連絡先: alice@example.com と 090-1234-5678';
    my $expected = '連絡先: a****@example.com と ***-****-5678';
    is($masker->process($input), $expected, 'non-ascii preserved');
};

done_testing();
