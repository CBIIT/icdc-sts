package sts;
use version; our $VERSION = '0.1.1';
use Mojo::Base 'Mojolicious';
use DBI;
use Neo4j::Bolt;
use sts::queries;
use strict;

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
  $r->get('/')->to('actions#ack');
  $r->get('/healthcheck')->to('actions#healthcheck');
  $r->get('/connectcheck')->to('actions#connectcheck');
  $r->get('/connect')->to('actions#connect');
  $r->get('/alpha')->to('actions#alpha');
  #$r->get('/domains')->to('actions#domain_list');
  #$r->get('/properties')->to('actions#domain_list');
  #$r->get('/:domain_id')->to('actions#domain');
  #$r->get('/:domain_id/list')->to('actions#list');
  #$r->get('/:domain_id/validate')->to('actions#validate');
  #$r->get('/:domain_id/search')->to('actions#search');
  #$r->get('/property/:prop_name')->to('actions#domain');
  #$r->get('/property/:prop_name/list')->to('actions#list');
  #$r->get('/property/:prop_name/validate')->to('actions#validate');
  #$r->get('/property/:prop_name/search')->to('actions#search');
  #$r->get('/domain/:dom_name')->to('actions#domain');
  #$r->get('/domain/:dom_name/list')->to('actions#list');
  #$r->get('/domain/:dom_name/validate')->to('actions#validate');
  #$r->get('/domain/:dom_name/:term/search')->to('actions#search');

  # setup db interface
  setup_db_intf($self);
  $self->log->debug("Ready");
}

sub setup_db_intf {
  my ($self) = @_;
  
  #my $dbh = DBI->connect("dbi:SQLite:dbname=".$self->config->{sts_db});
  #die "AGGGH database is unavailable" unless $dbh->ping;
  #$dbh->{RaiseError} = 1;
  
  #my %sth;
  ## auto create helper functions for statement handles for each
  ## query in sts::queries
  #for my $stmt (keys %stmts) {
  #  $sth{$stmt} = $dbh->prepare($stmts{$stmt});
  #  eval "\$self->helper( ${stmt}_sth => sub { \$sth{$stmt} } );";
  #}
  
  # Grab AWS credentials from environment
  my $neo4j_user = $ENV{NEO4J_MDB_USER};
  my $neo4j_pass = $ENV{NEO4J_MDB_PASS};

  # Construct MDB access url
  ## TODO remove hard-coded values to config file
  my $default_url = 'bolt://'.$neo4j_user.':'.$neo4j_pass.'@54.91.213.206:7687';
  my $NEO4J_URL = $ENV{NEO4J_URL} // $default_url;

  my $mdbh = Neo4j::Bolt->connect($NEO4J_URL);
  my $conn = $mdbh->connected;
  die "No connection to neo4j: ".$mdbh->errmsg unless $conn;
  
  eval "\$self->helper( 
  	connectcheck_sth => sub { \$mdbh->run_query( 'MATCH (n:property) RETURN count(n)' , {} ) } )"; 

  eval "\$self->helper( connect_sth      => sub { return 'Shoot Me!' })"; 

  eval "\$self->helper( 
  	alpha_sth => sub { \$mdbh->run_query( 'MATCH (n:property) RETURN count(n)' , {} ) } )"; 

}
1;
