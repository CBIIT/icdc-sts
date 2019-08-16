package sts::Controller::Actions;
use Mojo::Base 'Mojolicious::Controller';

sub ack {
  my $self = shift;
  my $ack = {
    service => 'STS',
    version => $self->config->{sts_version},
  };
  $self->render( json => $ack );
}

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
  $self->validate_sth->execute($self->param('q'),$domain->{domain_id});
  my $valid = $self->validate_sth->fetchrow_hashref;
  if ($valid) {
    $self->term_info_by_id_sth->execute($valid->{term_id});
    my $terminfo = $self->term_info_by_id_sth->fetchrow_hashref;
;
    $self->render( json => { term => term_payload($terminfo),
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
    $self->render(json => { errmsg => "No hits for '".$self->param('q')."' in domain '".$domain->{name}."'", status => 400 });
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
1;

