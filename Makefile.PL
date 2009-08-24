use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'LinkSeeker',
    AUTHOR              => 'Ktat <ktat@cpan.org>',
    VERSION_FROM        => 'lib/LinkSeeker.pm',
    ABSTRACT_FROM       => 'lib/LinkSeeker.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'		     => 0,
	'CGI::Lite::Request::Cookie' => 0,
	'Any::Moose'		     => 0,
	'File::Slurp'		     => 0,
	'URI::Escape'		     => 0,
	'Clone'			     => 0,
	'Config::Any'		     => 0,
	'Time::HiRes'		     => 0,
	'HTTP::Date'		     => 0,
	'HTML::LinkExtor'	     => 0,
	'URI'			     => 0,
	'Class::Inspector'           => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'LinkSeeker-*' },
);
