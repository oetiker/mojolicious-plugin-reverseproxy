package MountPoint;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
    my $app = shift;

    $app->plugin('Mojolicious::Plugin::ReverseProxy', {
        destination_url => 'http://remotehost/',
        mount_point     => '/foo',
        req_processor   => sub {
            my $ctrl = shift;
            my $req  = shift;
            my $opt  = shift;
            $ctrl->render(text => $req->url->to_string);
        },
    });
}

1;
