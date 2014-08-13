package CookieWrapper;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
    my $app = shift;

    $app->secrets(['some secure secret']);

    $app->plugin('Mojolicious::Plugin::ReverseProxy',{
        helper_name => 'cookie_proxy',
        req_processor => sub {
            my $ctrl= shift;
            my $req = shift;
            my $opt = shift;
            # get cookies from session
            $req->headers->remove('cookie');
            my $cookies = $ctrl->session->{cookies};
            $req->cookies(map { { name => $_, value  => $cookies->{$_} } } keys %$cookies);
        },
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
    });

    # Router
    my $r = $app->routes;
    # Normal route to controller
    $r->any('/*catchall' => {catchall => ''})->to(
        cb => sub { 
            shift->cookie_proxy('http://google.com/','http://localhost:3000/')
        }
    );
}

1;
