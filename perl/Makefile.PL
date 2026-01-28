use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Mask::PII',
    VERSION_FROM => 'lib/Mask/PII.pm',
    ABSTRACT_FROM => 'lib/Mask/PII.pm',
    AUTHOR       => 'Finite Field, K.K.',
    LICENSE      => 'mit',
    MIN_PERL_VERSION => '5.010',
    META_MERGE   => {
        'meta-spec' => { version => 2 },
        resources   => {
            homepage   => 'https://finitefield.org/en/oss/mask-pii',
            repository => {
                type => 'git',
                url  => 'https://github.com/finitefield-org/mask-pii.git',
                web  => 'https://github.com/finitefield-org/mask-pii',
            },
            bugtracker => {
                web => 'https://github.com/finitefield-org/mask-pii/issues',
            },
        },
        keywords => [qw(pii masking email phone privacy)],
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
);
