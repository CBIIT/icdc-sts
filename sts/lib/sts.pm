package sts;
use Mojo::Base 'Mojolicious';
use DBI;
use Cwd;

our %stmt = (
  validate => <<Q,
    select d.name as domain, t.*
    from term t inner join term_domain td
    on t.id=td.term
    inner join domain d
    on td.domain=d.id
    where t.term = ?
    and d.id = ?
Q
  list => <<Q,
  select t.*
    from term t inner join term_domain td
    on t.id=td.term
    inner join domain d
    on td.domain=d.id
    where d.id = ?
Q
  search => <<Q,
  select d.name as domain, t.*
  from term t inner join term_domain td
  on t.id=td.term
  inner join domain d
  on td.domain=d.id
  where d.id = ? and
        t.term like ?
Q
  domain_by_id => <<Q,
  select d.* 
  from domain as d 
  where d.id = ?
Q
  domain_by_name => <<Q,
  select d.* 
  from domain as d 
  where d.name = ?
Q
  
 );
# This method will run once at server start
sub startup {
  my $self = shift;

  say getcwd();

  # Load configuration from hash returned by config file
  my $config = $self->plugin('Config');

  # Configure the application
  $self->secrets($config->{secrets});

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('actions#ack');
  $r->get('/domain/:prop_name')->to('actions#domain');
  $r->get('/:domain_id')->to('actions#domain');
  $r->get('/domain/:prop_name/list')->to('actions#list');
  $r->get('/:domain_id/list')->to('actions#list');
  $r->get('/domain/:prop_name/validate')->to('actions#validate');
  $r->get('/:domain_id/validate')->to('actions#validate');
  $r->get('/domain/:prop_name/:term/search')->to('actions#search');
  $r->get('/:domain_id/search')->to('actions#search');

  # setup db interface
  setup_db_intf($self);
}

sub setup_db_intf {
  my ($self) = @_;
  my $dbh = DBI->connect("dbi:SQLite:dbname=".$self->config->{sts_db});
  die "AGGGH database is unavailable" unless $dbh->ping;
  $dbh->{RaiseError} = 1;
  my %sth;
  for (keys %stmt) {
    $sth{$_} = $dbh->prepare($stmt{$_});
  }
  $self->helper( validate_sth => sub { $sth{validate} } );
  $self->helper( list_sth => sub { $sth{list} } );
  $self->helper( search_sth => sub { $sth{search} } );
  $self->helper( domain_by_id_sth => sub { $sth{domain_by_id} } );
  $self->helper( domain_by_name_sth => sub { $sth{domain_by_name} } );
  


  1;
}
1;
