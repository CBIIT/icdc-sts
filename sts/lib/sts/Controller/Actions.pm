package sts::Controller::Actions;
use Mojo::Base 'Mojolicious::Controller';


############################################################
=head1 NAME
    sts::Controller::Actions

=head1 SYNOPSIS
    functions used/called from Mojo routes in sts.pm

=head2 subroutines/actions

=over 12

=item ack()

DESCRIPTION:
    ack() is the placeholder for the front homepage, tells sts version

INPUT:  
    nothing

OUTPUT: 
    { service => "STS", version => <sts_version> }

=cut
############################################################
sub ack {
  my $self = shift;
  my $ack = {
    service => 'STS',
    version => $self->config->{sts_version},
  };
  $self->render( json => $ack );
}


############################################################
=item healthcheck()

DESCRIPTION:
    The healthcheck() function is used to verify that the microservice is 
    alive and functional. It does not check data, other than to see if
    _something_ is there.

INPUT:  
    nothing

OUTPUT: 
    { MDB_CONNECTION => <ok|fail>, MDB_NODE_COUNT => <string> }

    Reference to an anonymous hash with these keys
            MDB_CONNECTION => 'ok' or 'fail'    # describes if the MDB db
                                                # can be accessed and can be
                                                # queried with version info
                                                
            MDB_NODE_COUNT => string            # counts all nodes in MDB 
                                                # and while the actual result 
                                                # doesn't really matter, just
                                                # check that _some_ data
                                                # exists

=cut
############################################################
sub healthcheck {
  my $self = shift;

  # ----------------------------------------------
  # Part 1:
  # See if the Meta database is up by querying the neo4j version
  # we don't need to look at actual data, just check
  # if expected headers were returned
  
  # get subroutine_ref to exec Neo4j::Bolt's `run_query` (defined in sts.pm)
  # $h is anon hash, used for [$param_hash] in Neo4j::Bolt::Cxn
  # $h is empty (no parameters is being passed)
  my $h = {};
  my $run_query_sref = $self->get_database_version_sref;
  my $stream = $run_query_sref->($h);
 
  # check returned version (in headers)
  my $mdb_connection = 'fail';
  my @names = $stream->field_names;
  if (
    $names[0] eq 'name'
    && $names[1] eq 'version'
    && $names[2] eq 'edition'
  ) {
      $mdb_connection = 'ok';
  };

  # ----------------------------------------------
  # Part 2:
  # see if some data exists in MDB by simply counting nodes

  # get subroutine_ref to exec Neo4j::Bolt's `run_query` (defined in sts.pm)
  $run_query_sref = $self->get_database_node_count_sref;
  $stream = $run_query_sref->($h);

  # count nodes
  my $mdb_node_count;
  while ( my @row = $stream->fetch_next ) {
      $mdb_node_count = $row[0];
  }

  # ----------------------------------------------
  # done - now return
  my $healthcheck_response = {'MDB_CONNECTION' => $mdb_connection,
                              'MDB_NODE_COUNT' => $mdb_node_count };
  $self->render( json => $healthcheck_response );

}


############################################################
=item nodes()

DESCRIPTION:
    gets a list of nodes in MDB

INPUT:  
    nothing

OUTPUT: 
    json array of nodes, describing node.handle and node.model 
    [  
       {
           "node":{
              "handle":<node.handle>,
              "model":"node.model"
           }
        },
        ...
    ]

=cut
############################################################
sub nodes {
  my $self = shift;

  # get subroutine_ref to exec Neo4j::Bolt's `run_query` (defined in sts.pm)
  # $h is anon hash, used for [$param_hash] in Neo4j::Bolt::Cxn
  # $h is empty (no parameters is being passed)
  my $h = {};
  my $run_query_sref = $self->get_nodes_list_sref;
  my $stream = $run_query_sref->($h);

  # now handle the query result
  my $data = [];
  while ( my @row = $stream->fetch_next ) {
    # now format
    my $n = { 'node' => { 'handle' => $row[0],
                          'model'  => $row[1] } };
    push @$data, $n;
  }

  # done - now return
  $self->render( json => $data );
}



############################################################
=item properties()

DESCRIPTION:
    gets a list of properties in MDB, and their attributes

INPUT:  
    nothing

OUTPUT: 
    json array of properties, describing its attributes 
    [
       {
          "property":{
             "handle":<property.handle>,
             "value_domain":<property.value_domain>,
             "model":<property.model>,
            "is_required":<property.is_required>
          }
      },
      ...
    ]

=cut
############################################################
sub properties {
  my $self = shift;

  # get subroutine_ref to exec Neo4j::Bolt's `run_query` (defined in sts.pm)
  # $h is anon hash, used for [$param_hash] in Neo4j::Bolt::Cxn
  # $h is empty (no parameters is being passed)
  my $h = {};
  my $run_query_sref = $self->get_properties_list_sref;
  my $stream = $run_query_sref->($h);

  # handle query result data
  my $data = [];
  while ( my @row = $stream->fetch_next ) {
    
    # now format
    my $p = { 'property' => { 'handle'       => $row[0],
                              'value_domain' => $row[1],
                              'model'        => $row[2],
                              'is_required'  => $row[3] } };
    
    push @$data, $p;
  }

  # done - now return
  $self->render( json => $data );
}



############################################################
=item value_sets()

DESCRIPTION:
    gets a list of value sets in MDB

INPUT:  
    nothing

OUTPUT: 
    json array of value sets, describing value set attributes
    and the property to which the value set belongs
    [  
       {
           "value_set":{
              "id":<value_set.id>,
              "url":<value_set.url>
           },
           "property-handle":<property.handle>
        },
        ...
    ]

=cut
############################################################
sub value_sets {
  my $self = shift;

  # get subroutine_ref to exec Neo4j::Bolt's `run_query` (defined in sts.pm)
  # $h is anon hash, used for [$param_hash] in Neo4j::Bolt::Cxn
  # $h is empty (no parameters is being passed)
  my $h = {};
  my $run_query_sref = $self->get_value_sets_list_sref;
  my $stream = $run_query_sref->($h);

  # handle returned data
  my $data = [];
  while ( my @row = $stream->fetch_next ) {
    # now format
    my $vs = { 'value_set' => { 'id'  => $row[1],
                                'url' => $row[2] },
               'property-handle' => $row[0] };
    
    push @$data, $vs;
  }

  # done - now return
  $self->render( json => $data );
}


############################################################
=item value_set()

DESCRIPTION:
    gets details about a single value set in MDB

INPUT:  
    value_set_id

OUTPUT: 
    json of a single value set, describing value set attributes
    and the property to which the value set belongs
    [  
       {
           "value_set":{
              "id":<value_set.id>,
              "url":<value_set.url>
           },
           "property-handle":<property.handle>
        },
        ...
    ]

=cut
############################################################
sub value_set {
  my $self = shift;

  my $vs_id = $self->stash('value_set_id');
  $self->app->log->info("using value_set $vs_id");

  # just make sure we have term to proceed, else return error 400
  unless ($vs_id) {
     $self->render(json => { errmsg => "Missing or non-existent value_set id"},
                   status => 400);
     return;
  }

  # $h is anon hash, used for [$param_hash] in Neo4j::Bolt::Cxn
  my $h = { param => $vs_id };
  
  # get subroutine_ref to exec Neo4j::Bolt's `run_query` (defined in sts.pm)
  my $run_query_sref = $self->get_value_set_detail_sref;
  my $stream = $run_query_sref->($h);

  # handle returned data -- single hash here
  my $data = {};
  while ( my @row = $stream->fetch_next ) {
    # now format
 
    # see if we want terms handled
    # need to see if the exist before we can test
    my $terms_exist = -1;
    if ( defined ($row[4]) || defined ($row[5]) ) {
            $terms_exist = 1;
    }else{
        $terms_exist = 0;
    }
        
    unless (exists $data->{'value_set'}) {
        $data = { 'value_set' => { 'id'  => $row[2],
                                    'url' => $row[3] },
                   'property-handle' => $row[0],
                   'property-model'  => $row[1]
        };
        # only add the 'terms' if terms were found
        if ($terms_exist){ $data->{'terms'} = [];}

    } # end unless first iteration

    # now only if there are terms, add them under the 'terms' array
    if ($terms_exist) {
        my $term_ = { 'term' => {'id' => $row[4], 'value' => $row[5]} };
        push @{$data->{'terms'}}, $term_;
    }

  } # end while

  $self->app->log->info(" done iterating");
    

  # done - now return
  $self->render( json => $data );
}



############################################################
=item terms()

DESCRIPTION:
    gets a list of value sets in MDB

INPUT:  
    nothing

OUTPUT: 
    json array of value sets, describing value set attributes
    and the property to which the value set belongs
    [  
       {
           "value_set":{
              "id":<value_set.id>,
              "url":<value_set.url>
           },
           "property-handle":<property.handle>
        },
        ...
    ]

=cut
############################################################
sub terms {
  my $self = shift;

  $self->app->log->info("getting list of terms"); 

  # get subroutine_ref to exec Neo4j::Bolt's `run_query` (defined in sts.pm)
  # $h is anon hash, used for [$param_hash] in Neo4j::Bolt::Cxn
  # $h is empty (no parameters is being passed)
  my $h = {};
  my $run_query_sref = $self->get_terms_list_sref;
  my $stream = $run_query_sref->($h);

  # handle query result data
  my $data = [];
  while ( my @row = $stream->fetch_next ) {
    # now format
    my $t = { 'term' => { 'value'  => $row[0],
                          'id'   => $row[1] },
              'term-origin' => $row[2] };
    
    push @$data, $t;
  }

  # done, now return
  $self->render( json => $data );
}



############################################################
=item term()

DESCRIPTION:
    gets a details for a single term in MDB

INPUT:  
    :term

OUTPUT: 
    json array of value sets, describing value set attributes
    and the property to which the value set belongs
    [  
       {
           "value_set":{
              "id":<value_set.id>,
              "url":<value_set.url>
           },
           "property-handle":<property.handle>
        },
        ...
    ]

=cut
############################################################
sub term {
  my $self = shift;

  my $term = $self->stash('term');
  $self->app->log->info("using term $term");

  # just make sure we have term to proceed, else return error 400
  unless ($term) {
     $self->render(json => { errmsg => "Missing or non-existent term"},
                   status => 400);
     return;
  }

  # $h is anon hash, used for [$param_hash] in Neo4j::Bolt::Cxn
  my $h = { param => $term };

  # get subroutine_ref to exec Neo4j::Bolt's `run_query` (defined in sts.pm)
  my $run_query_sref = $self->get_term_detail_sref;
  my $stream = $run_query_sref->($h);

  # capture data back from Neo4j::Bolt::ResultStream
  my $data = [];
  while ( my @row = $stream->fetch_next ) {
    # now format
    my $t = { 'term' => { 'value'  => $row[0],
                          'id'   => $row[1] },
              'term-origin' => $row[2] };
    
    push @$data, $t;
  }

  unless (scalar @$data) {
     $self->render(json => { errmsg => "Missing or non-existent term"},
                   status => 400);
     return;
  }

  # now return result
  $self->render( json => $data );
}


# ----------------------------------- #


sub validate {
  my $self = shift;
  unless ($self->param('q')) {
    $self->render( json => { errmsg => "Query parameter 'q' required" },
                   status => 400);
    return;
  }
  my $domain = $self->check_domain;
  unless ($domain) {
    $self->render(json => { errmsg => "Missing or non-existent domain"},
                  status => 400);
    return;
  }
  $self->validate_sth->execute($domain->{domain_id},$self->param('q'));
  my $valid = $self->validate_sth->fetchrow_hashref;

  if ($valid) {
    $self->render( json => { term => term_payload($valid),
                            domain => domain_payload($domain) });
  }
  else {
    $self->render( json => { errmsg => "term not valid for the domain" },
                   status => 400 );
  }
}

sub search {
  my $self = shift;
  unless ($self->param('q')) {
    $self->render( json => { errmsg => "Query parameter 'q' required" },
                   status => 400);
    return;
  }
  my $domain = $self->check_domain;
  unless ($domain) {
    $self->render(json => { errmsg => "Missing or non-existent domain"},
                  status => 400);
    return;
  }
  my @ret;
  my $sth = $self->search_terms_sth;
  $sth->execute($domain->{domain_id}, $self->param('q'));
  while (my $r = $sth->fetchrow_hashref) {
    push @ret, term_payload($r);
  }
  if (@ret) {
    $self->render(json => { terms => \@ret, domain => domain_payload($domain) } );
  }
  else {
    $self->render(json => { errmsg => "No hits for '".$self->param('q')."' in domain '".$domain->{domain_name}."'", status => 400 });
  }

}

sub domain {
  my $self = shift;
  my $domain = $self->check_domain;
  if ($domain) {
    $self->render(json => domain_payload($domain));
  }
  else {
    $self->render(json => { errmsg => "Missing or non-existent domain"},
                  status => 400);
  }
}

sub list {
  my $self = shift;
  my $domain = $self->check_domain;
  unless ($domain) {
    $self->render(json => { errmsg => "Missing or non-existent domain"},
                  status => 400);
    return;
  }
  my @ret;
  my $sth = $self->list_sth;
  $sth->execute($domain->{domain_id});
  while (my $r = $sth->fetchrow_hashref) {
    push @ret, term_payload($r);
  }
  $self->render(json => { terms => \@ret, domain => domain_payload($domain) });
}

sub domain_list {
  my $self = shift;
  my @ret;
  $self->domain_list_sth->execute();
  while (my $r = $self->domain_list_sth->fetchrow_hashref) {
    push @ret, { property => $r->{property}, domain_name => $r->{domain_name},
                 domain_id => $r->{domain_id} };
  }
  unless (@ret) {
    $self->render( json => {errmsg => "No domains in server!"}, status => 500 );
  }
  $self->render( json => \@ret );
}

#-----------------
# get a list of all property nodes and all of their 'properties'
sub property_list {
  my $self = shift;
  my @ret;
  $self->property_list_sth->execute();
  while (my $r = $self->property_list_sth->fetchrow_hashref) {
    push @ret, { handle => $r->{handle},
                 value_domain => $r->{value_domain},
                 model => $r->{model},
                 is_required => $r->{is_required} };
  }
  unless (@ret) {
    $self->render( json => {errmsg => "No domains in server!"}, status => 500 );
  }
  $self->render( json => \@ret );
}

# ----------------

sub check_domain {
  my $self = shift;
  my $dom;
  if ($self->stash('prop_name')) {
    my $prop = $self->stash('prop_name');
    $self->app->log->debug("$prop is the property domain");
    $self->domain_id_by_prop_sth->execute($prop);
    my $r = $self->domain_id_by_prop_sth->fetchrow_hashref;
    $dom = $r->{domain} if $r;
  }
  $dom //= $self->stash('domain_id') // $self->stash('dom_name');
  return unless $dom;
  my ($r, $sth);
  for ($self->domain_info_by_id_sth, $self->domain_info_by_name_sth) {
    $sth=$_;
    $sth->execute($dom);
    $r = $sth->fetchrow_hashref;
    last if ($r);
  }
  return $r if $r;
  return;
}

sub term_payload {
  my ($terminfo) = @_;
  return {
    term => $terminfo->{term}, term_id => $terminfo->{term_id},
    concept_code => $terminfo->{concept_code},
    code_authority => {
      authority_name => $terminfo->{term_authority},
      authority_uri => $terminfo->{term_authority_uri},
      code_uri => $terminfo->{term_code_uri}
     }
   }; 
}

sub domain_payload {
  my ($dominfo) = @_;
  return {
    domain_name => $dominfo->{domain_name},
    domain_id => $dominfo->{domain_id},
    domain_code => $dominfo->{domain_code},
    domain_authority => {
      authority_name => $dominfo->{domain_authority},
      authority_uri => $dominfo->{domain_authority_uri},
      domain_uri => $dominfo->{domain_uri}
     }
   };
}

#######
=back

=cut
#######


1;


