use FindBin;
use lib $FindBin::Bin.'/../3rd/lib/perl5';
use lib $FindBin::Bin.'/../lib';
use lib $FindBin::Bin.'/../example';

use Test::More tests => 5;
use Test::Mojo;

use_ok 'Mojolicious::Plugin::ReverseProxy';
use_ok 'MountPoint';

my $t = Test::Mojo->new('MountPoint');

$t = $t->get_ok('/foo/bar/baz')
       ->status_is(200)
       ->content_is('http://remotehost/bar/baz');

exit 0;
