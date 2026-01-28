$modulePath = Join-Path $PSScriptRoot '..' 'MaskPII' 'MaskPII.psd1'
Import-Module $modulePath -Force

Describe 'MaskPII' {
    Context 'Configuration behavior' {
        It 'returns input unchanged when no masks are enabled' {
            $masker = New-Masker
            $masker.Process('Contact: alice@example.com or 090-1234-5678.') | Should -Be 'Contact: alice@example.com or 090-1234-5678.'
        }
    }

    Context 'Email masking' {
        $cases = @(
            @{ Input = 'alice@example.com'; Expected = 'a****@example.com' }
            @{ Input = 'a@b.com'; Expected = '*@b.com' }
            @{ Input = 'ab@example.com'; Expected = 'a*@example.com' }
            @{ Input = 'a.b+c_d@example.co.jp'; Expected = 'a******@example.co.jp' }
            @{ Input = 'Contact: alice@example.com.'; Expected = 'Contact: a****@example.com.' }
            @{ Input = 'alice@example.com and bob@example.org'; Expected = 'a****@example.com and b**@example.org' }
            @{ Input = 'alice@example'; Expected = 'alice@example' }
            @{ Input = 'alice@localhost'; Expected = 'alice@localhost' }
            @{ Input = 'alice@@example.com'; Expected = 'alice@@example.com' }
            @{ Input = 'first.last+tag@sub.domain.com'; Expected = 'f*************@sub.domain.com' }
        )

        foreach ($case in $cases) {
            It "masks email: $($case.Input)" {
                $masker = (New-Masker).MaskEmails()
                $masker.Process($case.Input) | Should -Be $case.Expected
            }
        }
    }

    Context 'Phone masking' {
        $cases = @(
            @{ Input = '090-1234-5678'; Expected = '***-****-5678' }
            @{ Input = 'Call (555) 123-4567'; Expected = 'Call (***) ***-4567' }
            @{ Input = 'Intl: +81 3 1234 5678'; Expected = 'Intl: +** * **** 5678' }
            @{ Input = '+1 (800) 123-4567'; Expected = '+* (***) ***-4567' }
            @{ Input = '1234'; Expected = '1234' }
            @{ Input = '12345'; Expected = '*2345' }
            @{ Input = '12-3456'; Expected = '**-3456' }
            @{ Input = 'Tel: 090-1234-5678 ext. 99'; Expected = 'Tel: ***-****-5678 ext. 99' }
            @{ Input = 'Numbers: 111-2222 and 333-4444'; Expected = 'Numbers: ***-2222 and ***-4444' }
            @{ Input = 'abcdef'; Expected = 'abcdef' }
            @{ Input = '+'; Expected = '+' }
            @{ Input = '(12) 345 678'; Expected = '(**) **5 678' }
        )

        foreach ($case in $cases) {
            It "masks phone: $($case.Input)" {
                $masker = (New-Masker).MaskPhones()
                $masker.Process($case.Input) | Should -Be $case.Expected
            }
        }
    }

    Context 'Combined masking' {
        $cases = @(
            @{ Input = 'Contact: alice@example.com or 090-1234-5678.'; Expected = 'Contact: a****@example.com or ***-****-5678.' }
            @{ Input = 'Email bob@example.org, phone +1 (800) 123-4567'; Expected = 'Email b**@example.org, phone +* (***) ***-4567' }
        )

        foreach ($case in $cases) {
            It "masks combined: $($case.Input)" {
                $masker = (New-Masker).MaskEmails().MaskPhones()
                $masker.Process($case.Input) | Should -Be $case.Expected
            }
        }
    }

    Context 'Custom mask character' {
        $cases = @(
            @{ Input = 'alice@example.com'; Expected = 'a####@example.com' }
            @{ Input = '090-1234-5678'; Expected = '###-####-5678' }
            @{ Input = 'Contact: alice@example.com or 090-1234-5678.'; Expected = 'Contact: a####@example.com or ###-####-5678.' }
        )

        foreach ($case in $cases) {
            It "masks with custom char: $($case.Input)" {
                $masker = (New-Masker).MaskEmails().MaskPhones().WithMaskChar('#')
                $masker.Process($case.Input) | Should -Be $case.Expected
            }
        }
    }
}
