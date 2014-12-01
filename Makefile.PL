use 5.010001;

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::ReverseProxy',
  VERSION_FROM => 'lib/Mojolicious/Plugin/ReverseProxy.pm',
  ABSTRACT     => 'ReverseProxy plugin for the Mojolicious Perl framework',
  AUTHOR       => 'Tobias Oetiker <tobi@oetiker.ch>',
  LICENSE      => 'artistic_2',
  PREREQ_PM    => {
    'Mojolicious' => '5.63'
  },
  META_MERGE   => {
    requires  => {perl => '5.010001'},
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => 'https://github.com/oetiker/Mojolicious-Plugin-ReverseProxy',
      bugtracker  => 'https://github.com/oetiker/Mojolicious-Plugin-ReverseProxy/issues'
    },
    no_index => {directory => ['t','example','setup']}
  },
  test => {TESTS => 't/*.t'}
);
