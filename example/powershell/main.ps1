Import-Module ../../powershell/MaskPII/MaskPII.psd1

$masker = (New-Masker).MaskEmails().MaskPhones().WithMaskChar('#')
$inputText = 'Contact: alice@example.com or 090-1234-5678.'
$output = $masker.Process($inputText)

$output
