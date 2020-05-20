package sts::Controller::Actions;
use Mojo::Base 'Mojolicious::Controller';
#use YAML::XS;
use JSON::PP;
use YAML::Tiny;
use Data::Dumper;

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
=item list_nodes()

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
              "id":node.id
              "model":"node.model"
           }
        },
        ...
    ]

=cut
############################################################
sub all_node_summary {
  my $self = shift;

  # get subroutine_ref to exec Neo4j::Bolt's `run_query` (defined in sts.pm)
  # $h is anon hash, used for [$param_hash] in Neo4j::Bolt::Cxn
  # $h is empty (no parameters is being passed)
  my $h = {};
  my $run_query_sref = $self->get_list_of_nodes_sref;
  my $stream = $run_query_sref->($h);

  # now handle the query result
  my $data = [];
  while ( my @row = $stream->fetch_next ) {
    # now format
    my $n = { 'node' => { 'id' => $row[0],
                          'handle' => $row[1],
                          'model'  => $row[2] } };
    push @$data, $n;
  }

  # done - now return
  $self->render( json => $data );
}

####################################### 
sub all_node_details {
  my $self = shift;

  $self->app->log->info("getting details for all nodes");

  # $h is anon hash, used for [$param_hash] in Neo4j::Bolt::Cxn
  # my $h = { param => $node_id };
  my $h = {};

  # get subroutine_ref to exec Neo4j::Bolt's `run_query` (defined in sts.pm)
  # $h is anon hash, used for [$param_hash] in Neo4j::Bolt::Cxn
  my $run_query_sref = $self->get_all_node_details_sref;
  my $stream = $run_query_sref->($h);

  # now handle the query result
  my $data = [];
  while ( my @row = $stream->fetch_next ) {
    # now format
    my $n = { 'node' => { 'node-id' => $row[0],
                          'node-handle' => $row[1],
                          'node-model'  => $row[2],
                          'to_relationship' => $row[3],
						              'to_node_id' => $row[4],
                          'to_node_handle' => $row[5],
                          'to_node_model' => $row[6],
                          'from_relationship' => $row[7],
                          'from_node_id' => $row[8],
                          'from_node_handle' => $row[9],
                          'from_node_model' => $row[10],
                          'property_id' => $row[11],
                          'property_handle' => $row[12],
                          'property_value_domain' => $row[13],
                          'property_model' => $row[14],
                          'concept_id' => $row[15],
                          'concept_term_id' => $row[16],
                          'concept_term_value' => $row[17],
                          'concept_term_origin_id' => $row[18],
                          'concept_term_origin_definition' => $row[19],
                          'concept_term_comments' => $row[20],
                          'concept_term_notes' => $row[21],
                          'concept_term_origin' => $row[22]  } };
    push @$data, $n;
  }

  # done - now return
  $self->render( json => $data );
}


############################################################
=item node_details()

DESCRIPTION:
    get details for a single node

INPUT:  
    id (node.id)

OUTPUT: 
    describes node, relationships, and properties  where (n2)->(n1)->(n3)
    [  
       {
           "node":{
                  n1.id,
						      n1.handle, 
            			n1.model, 
            			r12.handle,
						      n2.id, 
            			n2.handle, 
            			r31.handle,
						      n3.id, 
            			n3.handle, 
            			p1.handle, 
            			ct.value, 
            			ct.origin_id, 
            			ct.origin_definition, 
            			o.name;
           }
        },
        ...
    ]

=cut
############################################################
sub node_details {
  my $self = shift;

  my $node_id = $self->stash('node_id');
  my $format = $self->param('format');

  my $sanitizer = $self->sanitize_input_sref;
  $node_id = $sanitizer->($node_id); # simple sanitization

  $self->app->log->info("getting details for node >$node_id<");

  # just make sure we have term to proceed, else return error 400
  unless ($node_id) {
     $self->render(json => { errmsg => "Missing or non-existent node id"},
                   status => 400);
     return;
  }

  # $h is anon hash, used for [$param_hash] in Neo4j::Bolt::Cxn
  # my $h = { param => $node_id };
  my $h = { param => $node_id };

  # get subroutine_ref to exec Neo4j::Bolt's `run_query` (defined in sts.pm)
  # $h is anon hash, used for [$param_hash] in Neo4j::Bolt::Cxn
  my $run_query_sref = $self->get_node_details_sref;
  my $stream = $run_query_sref->($h);

  # now handle the query result
  my $data = {};
  while ( my @row = $stream->fetch_next ) {
    # now format

        # see if we want from and to nodes handled
        # need to see if the exist before we can test
        my $from_node_exists = 0;
        if ( defined ($row[8])) {
                $from_node_exists = $row[7];
        }
        my $to_node_exists = 0;
        if ( defined ($row[4])) {
                $to_node_exists = $row[3];
        }
        my $property_exists = 0;
        if ( defined ($row[11])) {
                $property_exists = 1;
        }

        unless (exists $data->{'node'}) {
            $data = { 'node' => { 'node-id'  => $row[0],
                                  'node-handle' => $row[1],
                                  'node-model' => $row[2] ,
                                  'has-concept' => {
                                          'concept-id' => $row[15] ,
                                          'represented-by' => {
                                              'term-id' => $row[16],
                                              'term-value' => $row[17],
                                              'term-origin_id' => $row[18],
                                              'term-origin_definition' => $row[19],
                                              'term-comments' => $row[20],
                                              'term-notes' => $row[21],
                                              'term-origin' => $row[22]
                                          }
                                    }
                                }
                    }
        };
            
        #  # only add if the X were found
          if ($from_node_exists) {
                unless ( exists $data->{'node'}->{$from_node_exists} ) {
                    $data->{'node'}->{$from_node_exists} = {
                                    'node-id'  => $row[8],
                                    'node-handle' => $row[9],
                                    'node-model' => $row[10] };
                }         
            }
            
            if ($to_node_exists){ 
                unless (exists $data->{'node'}->{$to_node_exists} ) {
                  $data->{'node'}->{$to_node_exists} = {
                                    'node-id'  => $row[4],
                                    'node-handle' => $row[5],
                                    'node-model' => $row[6]};
                }
            }

            
            # property
            if ($property_exists) { 
                unless (exists $data->{'node'}->{'has-property'}) {
                        $data->{'node'}->{'has-property'} = [];
                        $data->{'node'}->{'_seen-property'} = [];
                }
              # only add unique props
              my %seen = map { $_ => 1 } @{$data->{'node'}->{'_seen-property'}};
              unless (exists $seen{$row[11]} ) {
                  push @{$data->{'node'}->{'_seen-property'}}, $row[11];
                  my $prop = {'property-id' => $row[11],
                              'property-handle' => $row[12],
                              'property-value_domain' => $row[13],
                              'property-model' => $row[14] };
                  push @{$data->{'node'}->{'has-property'}}, $prop;
              }
            }

      } # end while

      ## clean up
      if (  exists ( $data->{'node'}) && exists $data->{'node'}->{'_seen-property'} ) {
          delete($data->{'node'}->{'_seen-property'});
      }

  if (!keys %{$data} ) {
     $self->render(json => { errmsg => "Missing or non-existent node id"}, status => 400); 
  }

  if ( defined ($format) && ($format eq 'yaml')) {
      my $yaml = Dump( $data);  ## YAML::XS
      $self->render (text => $yaml);
  } else {
      # done - now return
      $self->render( json => $data );
  }
}


############################################################
sub list_ctdc_nodes {
  my $self = shift;


  $self->app->log->info("getting details for all nodes for model ctdc");

  # $h is anon hash, used for [$param_hash] in Neo4j::Bolt::Cxn
  # my $h = { param => $node_id }
    my $h = { param => "CTDC" };

  # get subroutine_ref to exec Neo4j::Bolt's `run_query` (defined in sts.pm)
  # $h is anon hash, used for [$param_hash] in Neo4j::Bolt::Cxn
  my $run_query_sref = $self->get_model_nodes_sref;
  my $stream = $run_query_sref->($h);

  # now handle the query result
  my $data = '';
  my $headers = "node-handle, node-id</br>";
  $data .=  $headers;
  while ( my @row = $stream->fetch_next ) {
    # now format
      
      $data .=  $row[1] . ", " . $row[0] . "</br>";
  }

  $self->render( text => $data);
}

####################################### 
sub list_icdc_nodes {
  my $self = shift;

  $self->app->log->info("getting details for all nodes for model icdc");

  # $h is anon hash, used for [$param_hash] in Neo4j::Bolt::Cxn
  # my $h = { param => $node_id };
  my $h = { param => 'ICDC' };

  # get subroutine_ref to exec Neo4j::Bolt's `run_query` (defined in sts.pm)
  # $h is anon hash, used for [$param_hash] in Neo4j::Bolt::Cxn
  my $run_query_sref = $self->get_model_nodes_sref;
  my $stream = $run_query_sref->($h);

  # now handle the query result
  my $data = '';
  my $headers = "node-handle, node-id</br>";
  $data .=  $headers;
  while ( my @row = $stream->fetch_next ) {
    # now format
      
      $data .=  $row[1] . ", " . $row[0] . "</br>";
  }

  $self->render( text => $data);
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
  my %list_of_seen_vs = ();
  while ( my @row = $stream->fetch_next ) {

    # see if we want terms handled
    # need to see if the exist before we can test
    my $terms_exist = -1;
    if ( defined ($row[4]) || defined ($row[5]) ) {
            $terms_exist = 1;
    }else{
        $terms_exist = 0;
    }

    # capture basic value_set data
    my $vs = { 'value_set' => { 'id'  => $row[2],
                                'url' => $row[3] },
               'property-handle' => $row[0],
               'property-model'  => $row[1] };
    # only add the 'terms' if terms were found
    if ($terms_exist){ 
        $vs->{'terms'} = [];
    }
   
    # check to see if this is a new value set or not
    unless ( exists ($list_of_seen_vs{$row[2]})) {
        push @$data, $vs;
        $list_of_seen_vs{$row[2]} = 1;
    }

    # now only if there are terms, add them under the 'terms' array
    # for the appropriate vs
    if ($terms_exist) {
        my $term_ = { 'term' => {'id' => $row[4], 'value' => $row[5]} };
      
        ## find which element in big data array has value set 
        ## and add the term to it
        my $id_ = $row[2];          # this is the current rows id
        my $size = scalar (@$data); # how many rows in data it iterate over    
        my $i = 0;
        for (0..$size-1) {
            if ( $data->[$i]->{'value_set'}->{'id'} eq $id_) {
                # ah-ha, now I know which one to add to...
                push @{$data->[$i]->{'terms'}}, $term_;
                last; # all done, stop loop
            }
            $i++;
        }
    }

    
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
    {
        "property-handle": "sex",
        "property-model": "ICDC",
        "terms": [
            {
                "term": {
                    "id": "cea0ebd8-a874-4cf5-b456-1f4aff66b4a4",
                    "value": "F"
                }
            },
            {
                "term": {
                    "id": "bab625e6-b1c3-41b9-b949-de37cfaa2973",
                    "value": "M"
                }
            }
        ],
        "value_set": {
            "id": "ad5cf6fd-914e-4c31-abbb-79f9373d4066",
            "url": null
        }
    }
=cut
############################################################
sub value_set {
  my $self = shift;

  my $vs_id = $self->stash('value_set_id');
  my $sanitizer = $self->sanitize_input_sref;
  $vs_id = $sanitizer->($vs_id); # simple sanitization
  $self->app->log->info("using value_set >$vs_id<");

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
        if ($terms_exist){ 
            $data->{'terms'} = [];
        }

    } # end unless first iteration

    # now only if there are terms, add them under the 'terms' array
    if ($terms_exist) {
        my $term_ = { 'term' => {'id' => $row[4], 'value' => $row[5]} };
        push @{$data->{'terms'}}, $term_;
    }

  } # end while

  # done - now return
  $self->render( json => $data );
}


####################################### 
sub list_ctdc_value_sets {
  my $self = shift;

  $self->app->log->info("getting details for all value_sets for model ctdc");

  # $h is anon hash, used for [$param_hash] in Neo4j::Bolt::Cxn
  # my $h = { param => $node_id };
  my $h = { param => 'CTDC' };

  # get subroutine_ref to exec Neo4j::Bolt's `run_query` (defined in sts.pm)
  # $h is anon hash, used for [$param_hash] in Neo4j::Bolt::Cxn
  my $run_query_sref = $self->get_model_value_sets_sref;
  my $stream = $run_query_sref->($h);

 # now handle the query result
  my $data = '';
  my $headers = "value_set, term , url </br>";
  $data .=  $headers;
  while ( my @row = $stream->fetch_next ) {
    # now format
     my $vs = $row[2] || '';
     my $t = $row[5] || '';
     my $u = $row[3] || '';
      $data .=  "$vs, $t, $u </br>";
  }

  $self->render( text => $data);
}

####################################### 
sub list_icdc_value_sets {
  my $self = shift;

  $self->app->log->info("getting details for all value_sets for model icdc");

  # $h is anon hash, used for [$param_hash] in Neo4j::Bolt::Cxn
  # my $h = { param => $node_id };
  my $h = { param => 'ICDC' };

  # get subroutine_ref to exec Neo4j::Bolt's `run_query` (defined in sts.pm)
  # $h is anon hash, used for [$param_hash] in Neo4j::Bolt::Cxn
  my $run_query_sref = $self->get_model_value_sets_sref;
  my $stream = $run_query_sref->($h);

  ## now handle the query result
  #my $data = '';
  #my $headers = "value_set_handle-handle, value_set_handle.url, term-value, term-id, value_set-id</br>";
  #$data .=  $headers;
  #while ( my @row = $stream->fetch_next ) {
  #  # now format
  #    #$data .=  $row[1] . ", " . $row[2] . ", " . $row[3] . ", " . $row[4] . ", " . $row[5] . "</br>";
  #}

 # now handle the query result
  my $data = '';
  my $headers = "value_set, term , url </br>";
  $data .=  $headers;
  while ( my @row = $stream->fetch_next ) {
    # now format
     my $vs = $row[2] || '';
     my $t = $row[5] || '';
     my $u = $row[3] || '';
      $data .=  "$vs, $t, $u </br>";
  }

  $self->render( text => $data);
}


############################################################
=item terms()

DESCRIPTION:
    gets a list of value sets in MDB

INPUT:  
    nothing

OUTPUT: 
    [
        {
            "term": {
                "id": "cea0ebd8-a874-4cf5-b456-1f4aff66b4a4",
                "value": "F"
            },
            "term-origin": "ICDC"
        },
        {
            "term": {
                "id": "bab625e6-b1c3-41b9-b949-de37cfaa2973",
                "value": "M"
            },
            "term-origin": "ICDC"
        },
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
    [
        {
            "term": {
                "id": "0393d7e6-8126-44f5-a884-06d6e0836f8e",
                "value": "blood"
            },
            "term-origin": "ICDC"
        }
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