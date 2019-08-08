package sts;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
  my $self = shift;

  # Load configuration from hash returned by config file
  my $config = $self->plugin('Config');

  # Configure the application
  $self->secrets($config->{secrets});

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('example#welcome');
  $r->get('/domain/:prop_name')->to('actions#domain');
  $r->get('/:domain_id')->to('actions#domain');
  $r->get('/domain/:prop_name/list')->to('actions#list');
  $r->get('/:domain_id/list')->to('actions#list');
  $r->get('/domain/:prop_name/validate')->to('actions#validate');
  $r->get('/:domain_id/validate')->to('actions#validate');
  $r->get('/domain/:prop_name/:term/search')->to('actions#search');
  $r->get('/:domain_id/search')->to('actions#search');

}

1;
