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
	'Any::Moose'		     => 0,
	'CGI::Lite::Request::Cookie' => 0,
	'Class::Inspector'           => 0,
	'Clone'			     => 0,
	'Config::Any'		     => 0,
	'File::Slurp'		     => 0,
	'HTML::LinkExtor'	     => 0,
	'HTTP::Date'		     => 0,
	'HTTP::Cookies'		     => 0,
	'LWP::UserAgent'	     => 0,
	'String::CamelCase'          => 0,
	'Tie::IxHash'                => 0,
	'Time::HiRes'		     => 0,
	'URI'			     => 0,
	'URI::Escape'		     => 0,
	'Web::Scraper'               => 0,
        'Term::ANSIColor'	     => 0,
        'Test::More'		     => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'LinkSeeker-*' },
);
