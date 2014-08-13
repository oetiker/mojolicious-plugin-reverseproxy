package Mojolicious::Plugin::ReverseProxy;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Transaction::HTTP;
use Mojo::UserAgent;

# let's have our own private unadulterated useragent
# insttead of using the shared one from app. Who knows
# what all the others are doing to the poor thing.

my $ua = Mojo::UserAgent->new( cookie_jar => 0 );

our $VERSION = '0.1';


my $make_req = sub {
    my $ctrl = shift;
    my $dest_url = shift;
    my $loc_url = shift;

    my $tx = Mojo::Transaction::HTTP->new;
    my $nr = $tx->req;

    # prepare requiest
    $nr->url->parse($dest_url);
    my $req_path = $ctrl->req->url->path;
    my $base_path = Mojo::URL->new($loc_url)->path;
    $req_path =~ s/^\Q${base_path}//;
    $nr->url->path($req_path);
    $nr->url->query($ctrl->req->url->query);
    $nr->method($ctrl->req->method);
    $nr->body($ctrl->req->body);

    # copy headers
    my $headers = $ctrl->req->headers->to_hash(1);
    delete $headers->{Host};
    for (qw(Referer Origin)){
        $headers->{$_}[0] =~ s/^\Q${loc_url}/$dest_url/ 
            if ref $headers->{$_} eq 'ARRAY';
    }
    $nr->headers->from_hash($headers);
    return $tx;
};

sub register {
    my $self = shift;
    my $app = shift;
    my $conf = shift;

    my $helper_name = $conf->{helper_name} || 'reverse_proxy_to';
    my $req_processor = $conf->{req_processor};
    my $res_processor = $conf->{res_processor};
    my $log = $app->log;

    $app->helper(
        $helper_name => sub {
            my $ctrl = shift;
            my $dest_url = shift;
            my $loc_url = shift;
            my $opt = shift;
            $opt->{loc_url} = $loc_url;
            $opt->{dest_url} = $dest_url;
            $ctrl->render_later;
            my $tx = $ctrl->$make_req($dest_url,$loc_url);
            $req_processor->($ctrl,$tx->req,$opt) if ref $req_processor eq 'CODE';
            $ua->start($tx, sub {
                my ($ua,$tx) = @_;
                my $res = $tx->res;
                my $err;
                if ($err = $tx->error and ! exists $err->{code}){
                    $ctrl->render(status => 500, text => 'ERROR '. $err->{code} . ': ' . $err->{message});
                    return;
                }
                $log->debug($res->code);
                if ($loc_url and $res->code =~ /^302$/){
                    my $location = $res->headers->location;
                    if ($location =~ s/^\Q${dest_url}/$loc_url/){
                        $res->headers->location($location);
                    }
                }
                $res_processor->($ctrl,$res,$opt) if ref $res_processor eq 'CODE';
                $ctrl->tx->res($res);
                $ctrl->rendered;
            });
        }
    );
}

1;

__END__

=head1 Mojolicious::Plugin::ReverseProxy
 
 package ProxyFun;
 use Mojo::Base 'Mojolicious';

 sub startup {
    my $app = shift;
    my $pluginOptions = { helper_name => 'proxy_to' };
    $app->plugin('Mojolicious::Plugin::ReverseProxy',$options);

    # Router
    my $r = $app->routes;
    my $callOpt = {};
    # Normal route to controller
    $r->any('/*catchall' => {catchall => ''})->to(
        cb => sub { 
            shift->proxy_to(
                'https://google.com',
                'http://localhost:3000',
                $callOpts
            )
        }
    );
 }

=head1 DESCRIPTION

The Mojolicious::Plugin::ReverseProxy module implements a proxy helper the controller.
By default it forwards all the headers verbatime except Host, Origin and Referer which
get re-written. 

The plugin takes the following options:

=over

=item helper_name

The name of the helper to register. The default name is C<reverse_proxy_to>.

  helper_name => 'cookie_proxy'

=item req_processor

Can be pointed to an anonymous subroutine which is called prior to handing controll over to
the user agent.

In the example we remove the cookie header from the request and populate the
cookies from our private cookie store in the session. The effect of this is that the
user can not alter the cookies.

 req_processor => sub {
    my $ctrl= shift;
    my $req = shift;
    my $opt = shift;
    # get cookies from session
    $req->headers->remove('cookie');
    my $cookies = $ctrl->session->{cookies};
    $req->cookies(map { { name => $_, value  => $cookies->{$_} } } keys %$cookies);
 },

=item res_processor

Can be pointed to an anonymous subroutine which is called prior to rendering the response.

In the example we use this to capture all set-cookie instructions and store them in the session.

 res_processor => sub {
    my $ctrl = shift;
    my $res = shift;
    my $opt = shift;
    
    # for fun, remove all  the cookies
    my $cookies = $res->cookies;
    my $session = $ctrl->session;
    for my $cookie (@{$res->cookies}){
        $session->{cookies}{$cookie->name} = $cookie->value;
    }
    # as the session will get applied later on
    $res->headers->remove('set-cookie');
 }

=head1 AUTHOR

S<Tobias Oetiker, E<lt>tobi@oetiker.chE<gt>>

=head1 COPYRIGHT

Copyright OETIKER+PARTNER AG 2014

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
