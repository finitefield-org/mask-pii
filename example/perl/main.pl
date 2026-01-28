use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../../perl/lib";
use Mask::PII;

my $masker = Mask::PII::Masker->new
    ->mask_emails
    ->mask_phones
    ->with_mask_char('#');

my $input = 'Contact: alice@example.com or 090-1234-5678.';
my $output = $masker->process($input);

print "$output\n";
