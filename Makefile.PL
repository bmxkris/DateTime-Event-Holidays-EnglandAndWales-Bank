use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DateTime::Event::Holidays::EnglandAndWales::Bank',
    AUTHOR              => 'Kristian Flint <kristian@cpan.org>',
    VERSION_FROM        => 'lib/DateTime/Event/Holidays/EnglandAndWales/Bank.pm',
    ABSTRACT_FROM       => 'lib/DateTime/Event/Holidays/EnglandAndWales/Bank.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DateTime-Event-Holidays-EnglandAndWales-Bank-*' },
);
