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
            @{ Text = 'alice@example.com'; Expected = 'a****@example.com' }
            @{ Text = 'a@b.com'; Expected = '*@b.com' }
            @{ Text = 'ab@example.com'; Expected = 'a*@example.com' }
            @{ Text = 'a.b+c_d@example.co.jp'; Expected = 'a******@example.co.jp' }
            @{ Text = 'Contact: alice@example.com.'; Expected = 'Contact: a****@example.com.' }
            @{ Text = 'alice@example.com and bob@example.org'; Expected = 'a****@example.com and b**@example.org' }
            @{ Text = 'alice@example'; Expected = 'alice@example' }
            @{ Text = 'alice@localhost'; Expected = 'alice@localhost' }
            @{ Text = 'alice@@example.com'; Expected = 'alice@@example.com' }
            @{ Text = 'first.last+tag@sub.domain.com'; Expected = 'f*************@sub.domain.com' }
        )

        It 'masks email: <Text>' -ForEach $cases {
            param($Text, $Expected)
            $masker = (New-Masker).MaskEmails()
            $masker.Process($Text) | Should -Be $Expected
        }
    }

    Context 'Phone masking' {
        $cases = @(
            @{ Text = '090-1234-5678'; Expected = '***-****-5678' }
            @{ Text = 'Call (555) 123-4567'; Expected = 'Call (***) ***-4567' }
            @{ Text = 'Intl: +81 3 1234 5678'; Expected = 'Intl: +** * **** 5678' }
            @{ Text = '+1 (800) 123-4567'; Expected = '+* (***) ***-4567' }
            @{ Text = '1234'; Expected = '1234' }
            @{ Text = '12345'; Expected = '*2345' }
            @{ Text = '12-3456'; Expected = '**-3456' }
            @{ Text = 'Tel: 090-1234-5678 ext. 99'; Expected = 'Tel: ***-****-5678 ext. 99' }
            @{ Text = 'Numbers: 111-2222 and 333-4444'; Expected = 'Numbers: ***-2222 and ***-4444' }
            @{ Text = 'abcdef'; Expected = 'abcdef' }
            @{ Text = '+'; Expected = '+' }
            @{ Text = '(12) 345 678'; Expected = '(**) **5 678' }
        )

        It 'masks phone: <Text>' -ForEach $cases {
            param($Text, $Expected)
            $masker = (New-Masker).MaskPhones()
            $masker.Process($Text) | Should -Be $Expected
        }
    }

    Context 'Combined masking' {
        $cases = @(
            @{ Text = 'Contact: alice@example.com or 090-1234-5678.'; Expected = 'Contact: a****@example.com or ***-****-5678.' }
            @{ Text = 'Email bob@example.org, phone +1 (800) 123-4567'; Expected = 'Email b**@example.org, phone +* (***) ***-4567' }
        )

        It 'masks combined: <Text>' -ForEach $cases {
            param($Text, $Expected)
            $masker = (New-Masker).MaskEmails().MaskPhones()
            $masker.Process($Text) | Should -Be $Expected
        }
    }

    Context 'Custom mask character' {
        $cases = @(
            @{ Text = 'alice@example.com'; Expected = 'a####@example.com' }
            @{ Text = '090-1234-5678'; Expected = '###-####-5678' }
            @{ Text = 'Contact: alice@example.com or 090-1234-5678.'; Expected = 'Contact: a####@example.com or ###-####-5678.' }
        )

        It 'masks with custom char: <Text>' -ForEach $cases {
            param($Text, $Expected)
            $masker = (New-Masker).MaskEmails().MaskPhones().WithMaskChar('#')
            $masker.Process($Text) | Should -Be $Expected
        }
    }
}
