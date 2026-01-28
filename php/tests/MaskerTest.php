<?php

declare(strict_types=1);

namespace MaskPII\Tests;

use MaskPII\Masker;
use PHPUnit\Framework\TestCase;

final class MaskerTest extends TestCase
{
    /**
     * @param array<int, array{0: string, 1: string}> $cases
     */
    private function assertCases(Masker $masker, array $cases): void
    {
        foreach ($cases as [$input, $expected]) {
            $this->assertSame($expected, $masker->process($input));
        }
    }

    public function testEmailBasicCases(): void
    {
        $masker = (new Masker())->maskEmails();
        $this->assertCases($masker, [
            ["alice@example.com", "a****@example.com"],
            ["a@b.com", "*@b.com"],
            ["ab@example.com", "a*@example.com"],
            ["a.b+c_d@example.co.jp", "a******@example.co.jp"],
        ]);
    }

    public function testEmailMixedText(): void
    {
        $masker = (new Masker())->maskEmails();
        $this->assertCases($masker, [
            ["Contact: alice@example.com.", "Contact: a****@example.com."],
            ["alice@example.com and bob@example.org", "a****@example.com and b**@example.org"],
        ]);
    }

    public function testEmailEdgeCases(): void
    {
        $masker = (new Masker())->maskEmails();
        $this->assertCases($masker, [
            ["alice@example", "alice@example"],
            ["alice@localhost", "alice@localhost"],
            ["alice@@example.com", "alice@@example.com"],
            ["first.last+tag@sub.domain.com", "f*************@sub.domain.com"],
        ]);
    }

    public function testPhoneBasicFormats(): void
    {
        $masker = (new Masker())->maskPhones();
        $this->assertCases($masker, [
            ["090-1234-5678", "***-****-5678"],
            ["Call (555) 123-4567", "Call (***) ***-4567"],
            ["Intl: +81 3 1234 5678", "Intl: +** * **** 5678"],
            ["+1 (800) 123-4567", "+* (***) ***-4567"],
        ]);
    }

    public function testPhoneShortAndBoundaryLengths(): void
    {
        $masker = (new Masker())->maskPhones();
        $this->assertCases($masker, [
            ["1234", "1234"],
            ["12345", "*2345"],
            ["12-3456", "**-3456"],
        ]);
    }

    public function testPhoneMixedText(): void
    {
        $masker = (new Masker())->maskPhones();
        $this->assertCases($masker, [
            ["Tel: 090-1234-5678 ext. 99", "Tel: ***-****-5678 ext. 99"],
            ["Numbers: 111-2222 and 333-4444", "Numbers: ***-2222 and ***-4444"],
        ]);
    }

    public function testPhoneEdgeCases(): void
    {
        $masker = (new Masker())->maskPhones();
        $this->assertCases($masker, [
            ["abcdef", "abcdef"],
            ["+", "+"],
            ["(12) 345 678", "(**) **5 678"],
        ]);
    }

    public function testCombinedMasking(): void
    {
        $masker = (new Masker())->maskEmails()->maskPhones();
        $this->assertCases($masker, [
            ["Contact: alice@example.com or 090-1234-5678.", "Contact: a****@example.com or ***-****-5678."],
            ["Email bob@example.org, phone +1 (800) 123-4567", "Email b**@example.org, phone +* (***) ***-4567"],
        ]);
    }

    public function testCustomMaskCharacter(): void
    {
        $emailMasker = (new Masker())->maskEmails()->withMaskChar("#");
        $phoneMasker = (new Masker())->maskPhones()->withMaskChar("#");
        $combined = (new Masker())->maskEmails()->maskPhones()->withMaskChar("#");

        $this->assertCases($emailMasker, [["alice@example.com", "a####@example.com"]]);
        $this->assertCases($phoneMasker, [["090-1234-5678", "###-####-5678"]]);

        $this->assertSame(
            "Contact: a####@example.com or ###-####-5678.",
            $combined->process("Contact: alice@example.com or 090-1234-5678.")
        );
    }

    public function testMaskerConfiguration(): void
    {
        $input = "alice@example.com 090-1234-5678";

        $passthrough = new Masker();
        $this->assertSame($input, $passthrough->process($input));

        $emailOnly = (new Masker())->maskEmails();
        $this->assertSame("a****@example.com 090-1234-5678", $emailOnly->process($input));

        $phoneOnly = (new Masker())->maskPhones();
        $this->assertSame("alice@example.com ***-****-5678", $phoneOnly->process($input));

        $both = (new Masker())->maskEmails()->maskPhones();
        $this->assertSame("a****@example.com ***-****-5678", $both->process($input));
    }

    public function testNonAsciiTextIsPreserved(): void
    {
        $masker = (new Masker())->maskEmails()->maskPhones();
        $input = "連絡先: alice@example.com と 090-1234-5678";
        $expected = "連絡先: a****@example.com と ***-****-5678";
        $this->assertSame($expected, $masker->process($input));
    }
}
