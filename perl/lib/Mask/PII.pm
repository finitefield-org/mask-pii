package Mask::PII;

use strict;
use warnings;

our $VERSION = '0.2.0';

1;

package Mask::PII::Masker;

use strict;
use warnings;

# Create a new masker with all masks disabled by default.
sub new {
    my ($class) = @_;
    return bless {
        mask_email => 0,
        mask_phone => 0,
        mask_char  => '*',
    }, $class;
}

# Enable email address masking.
sub mask_emails {
    my ($self) = @_;
    $self->{mask_email} = 1;
    return $self;
}

# Enable phone number masking.
sub mask_phones {
    my ($self) = @_;
    $self->{mask_phone} = 1;
    return $self;
}

# Set the character used for masking.
sub with_mask_char {
    my ($self, $char) = @_;
    if (!defined $char || $char eq '') {
        $self->{mask_char} = '*';
    } else {
        $char = "$char";
        $self->{mask_char} = substr($char, 0, 1);
    }
    return $self;
}

# Process input text and mask enabled PII patterns.
sub process {
    my ($self, $input) = @_;
    $input = '' if !defined $input;

    return $input if !$self->{mask_email} && !$self->{mask_phone};

    my $mask_char = $self->{mask_char} || '*';
    my $result = $input;

    $result = _mask_emails_in_text($result, $mask_char) if $self->{mask_email};
    $result = _mask_phones_in_text($result, $mask_char) if $self->{mask_phone};

    return $result;
}

sub _mask_emails_in_text {
    my ($text, $mask_char) = @_;
    my @bytes = unpack('C*', $text);
    my $len = scalar @bytes;
    my $output = '';
    my $last = 0;
    my $i = 0;

    while ($i < $len) {
        if ($bytes[$i] == 64) {
            my $local_start = $i;
            while ($local_start > 0 && _is_local_byte($bytes[$local_start - 1])) {
                $local_start--;
            }
            my $local_end = $i;

            my $domain_start = $i + 1;
            my $domain_end = $domain_start;
            while ($domain_end < $len && _is_domain_byte($bytes[$domain_end])) {
                $domain_end++;
            }

            if ($local_start < $local_end && $domain_start < $domain_end) {
                my $candidate_end = $domain_end;
                my $matched_end = -1;
                while ($candidate_end > $domain_start) {
                    my $domain = _slice_bytes($text, $domain_start, $candidate_end - $domain_start);
                    if (_is_valid_domain($domain)) {
                        $matched_end = $candidate_end;
                        last;
                    }
                    $candidate_end--;
                }

                if ($matched_end != -1) {
                    my $local = _slice_bytes($text, $local_start, $local_end - $local_start);
                    my $domain = _slice_bytes($text, $domain_start, $matched_end - $domain_start);
                    $output .= _slice_bytes($text, $last, $local_start - $last);
                    $output .= _mask_local($local, $mask_char);
                    $output .= '@';
                    $output .= $domain;
                    $last = $matched_end;
                    $i = $matched_end;
                    next;
                }
            }
        }

        $i++;
    }

    $output .= _slice_bytes($text, $last, $len - $last);
    return $output;
}

sub _mask_phones_in_text {
    my ($text, $mask_char) = @_;
    my @bytes = unpack('C*', $text);
    my $len = scalar @bytes;
    my $output = '';
    my $last = 0;
    my $i = 0;

    while ($i < $len) {
        if (_is_phone_start($bytes[$i])) {
            my $end = $i;
            while ($end < $len && _is_phone_byte($bytes[$end])) {
                $end++;
            }

            my $digit_count = 0;
            my $last_digit = -1;
            for (my $idx = $i; $idx < $end; $idx++) {
                if (_is_digit_byte($bytes[$idx])) {
                    $digit_count++;
                    $last_digit = $idx;
                }
            }

            if ($last_digit != -1) {
                my $candidate_end = $last_digit + 1;
                if ($digit_count >= 5) {
                    my $candidate = _slice_bytes($text, $i, $candidate_end - $i);
                    $output .= _slice_bytes($text, $last, $i - $last);
                    $output .= _mask_phone_candidate($candidate, $mask_char);
                    $last = $candidate_end;
                    $i = $candidate_end;
                    next;
                }
            }

            $i = $end;
            next;
        }

        $i++;
    }

    $output .= _slice_bytes($text, $last, $len - $last);
    return $output;
}

sub _mask_local {
    my ($local, $mask_char) = @_;
    use bytes;

    if (length($local) > 1) {
        return substr($local, 0, 1) . ($mask_char x (length($local) - 1));
    }
    return $mask_char;
}

sub _mask_phone_candidate {
    my ($candidate, $mask_char) = @_;
    my @bytes = unpack('C*', $candidate);
    my $digit_count = 0;
    for my $byte (@bytes) {
        $digit_count++ if _is_digit_byte($byte);
    }

    my $current_index = 0;
    my $output = '';
    for my $byte (@bytes) {
        if (_is_digit_byte($byte)) {
            $current_index++;
            if ($digit_count > 4 && $current_index <= $digit_count - 4) {
                $output .= $mask_char;
            } else {
                $output .= chr($byte);
            }
        } else {
            $output .= chr($byte);
        }
    }

    return $output;
}

sub _slice_bytes {
    my ($text, $start, $length) = @_;
    use bytes;
    return substr($text, $start, $length);
}

sub _is_local_byte {
    my ($byte) = @_;
    return _is_alpha_byte($byte)
        || _is_digit_byte($byte)
        || $byte == 46
        || $byte == 95
        || $byte == 37
        || $byte == 43
        || $byte == 45;
}

sub _is_domain_byte {
    my ($byte) = @_;
    return _is_alpha_byte($byte)
        || _is_digit_byte($byte)
        || $byte == 45
        || $byte == 46;
}

sub _is_valid_domain {
    my ($domain) = @_;
    return 0 if $domain eq '';
    return 0 if substr($domain, 0, 1) eq '.' || substr($domain, -1, 1) eq '.';

    my @parts = split /\./, $domain, -1;
    return 0 if scalar(@parts) < 2;

    for my $part (@parts) {
        return 0 if $part eq '';
        return 0 if substr($part, 0, 1) eq '-' || substr($part, -1, 1) eq '-';
        for my $byte (unpack('C*', $part)) {
            return 0 unless _is_alpha_byte($byte) || _is_digit_byte($byte) || $byte == 45;
        }
    }

    my $tld = $parts[-1];
    return 0 if length($tld) < 2;
    for my $byte (unpack('C*', $tld)) {
        return 0 unless _is_alpha_byte($byte);
    }

    return 1;
}

sub _is_phone_start {
    my ($byte) = @_;
    return _is_digit_byte($byte) || $byte == 43 || $byte == 40;
}

sub _is_phone_byte {
    my ($byte) = @_;
    return _is_digit_byte($byte)
        || $byte == 32
        || $byte == 45
        || $byte == 40
        || $byte == 41
        || $byte == 43;
}

sub _is_digit_byte {
    my ($byte) = @_;
    return $byte >= 48 && $byte <= 57;
}

sub _is_alpha_byte {
    my ($byte) = @_;
    return ($byte >= 65 && $byte <= 90) || ($byte >= 97 && $byte <= 122);
}

1;

__END__

=head1 NAME

Mask::PII - Mask email addresses and phone numbers in text.

=head1 VERSION

0.2.0

=head1 SYNOPSIS

  use Mask::PII;

  my $masker = Mask::PII::Masker->new
      ->mask_emails
      ->mask_phones
      ->with_mask_char('#');

  my $input = 'Contact: alice@example.com or 090-1234-5678.';
  my $output = $masker->process($input);

=head1 DESCRIPTION

Mask::PII provides a configurable masker for common PII patterns such as
email addresses and phone numbers. The masker uses deterministic, regex-free
scans to preserve surrounding text while masking sensitive content.

=head1 METHODS

=head2 Mask::PII::Masker->new

Create a new masker with all masks disabled by default.

=head2 mask_emails

Enable email address masking.

=head2 mask_phones

Enable phone number masking.

=head2 with_mask_char($char)

Set the character used for masking. If C<$char> is undefined or empty,
C<*> is used.

=head2 process($input)

Process input text and mask enabled PII patterns.

=head1 LICENSE

MIT

=head1 HOMEPAGE

https://finitefield.org/en/oss/mask-pii

=head1 REPOSITORY

https://github.com/finitefield-org/mask-pii

=head1 ISSUES

https://github.com/finitefield-org/mask-pii/issues

=cut
