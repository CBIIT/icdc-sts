package sts;
use version; our $VERSION = '0.1.9';
use Mojo::Base 'Mojolicious';
use DBI;
use Neo4j::Bolt;
use sts::CypherQueries qw( %queries );
use strict;

# This method will run once at server start
sub startup {
    my $self = shift;

    # Load configuration from hash returned by config file
    my $config = $self->plugin('Config');

    # Configure the application
    $self->secrets( $config->{secrets} );

    # Router
    my $r = $self->routes;

    # Normal route to controller
    $r->get('/')->to('actions#ack');
    $r->get('/healthcheck')->to('actions#healthcheck');
    #$r->get('/healthcheck2')->to('actions#healthcheck2');
    $r->get('/nodes')->to('actions#nodes');
    $r->get('/properties')->to('actions#properties');
    $r->get('/value_sets')->to('actions#value_sets');
    $r->get('/value_sets/:value_set_id')->to('actions#value_set');
    $r->get('/terms')->to('actions#terms');
    $r->get('/terms/:term')->to('actions#term');
    $r->get('/dune/:term')->to('actions#dune');

    # setup db interface
    setup_mdb_interface($self);
    $self->log->debug("Ready");
}


sub setup_mdb_interface {
    my ($self) = @_;

    # TODO: better, explicit error if these are empty
    # Grab AWS credentials from environment
    my $neo4j_user = $ENV{NEO4J_MDB_USER};
    my $neo4j_pass = $ENV{NEO4J_MDB_PASS};

    # Construct MDB access url
    # e.g. bolt://user:pass@54.91.213.206:7687'
    my $mdb_url =
        'bolt://'
      . $neo4j_user . ':'
      . $neo4j_pass . '@'
      . $self->config->{mdb_ip};
    my $NEO4J_URL = $ENV{NEO4J_URL} // $mdb_url;

    my $mdbh = Neo4j::Bolt->connect($NEO4J_URL);
    my $conn = $mdbh->connected;
    die "No connection to neo4j: " . $mdbh->errmsg unless $conn;
 
    # construct anonymouns subs for each queries as needed in routes above
    while ((my $queryname, my $cypherquery) = each (%queries)) { 
        eval "\$self->helper( ${queryname}_sref => sub { 
            return sub {
                my (\$param_href) = \@_;
                \$mdbh->run_query( \$cypherquery, \$param_href ) 
            }
        } )";
    }
}

1;
