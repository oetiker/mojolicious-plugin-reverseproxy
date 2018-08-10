use FindBin;
use lib $FindBin::Bin.'/../3rd/lib/perl5';
use lib $FindBin::Bin.'/../lib';
use lib $FindBin::Bin.'/../example';

use Test::More tests => 5;
use Test::Mojo;

use_ok 'Mojolicious::Plugin::ReverseProxy';
use_ok 'RemotePath';

my $t = Test::Mojo->new('RemotePath');

$t = $t->get_ok('/foo/baz')
       ->status_is(200)
       ->content_is('http://remotehost/bar/baz');

exit 0;
