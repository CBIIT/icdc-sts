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
  $self->validate_sth->execute($self->param('q'),$domain->{id});
  my $valid = $self->validate_sth->fetch;
  if ($valid) {
    $self->render( json => $valid );
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
  my $sth = $self->search_sth;
  $sth->execute($domain->{id}, $self->param('q'));
  while (my $r = $sth->fetch) {
    my %dta;
    @dta{@{$sth->{NAME}}} = @$r;
    push @ret, \%dta;
  }
  if (@ret) {
    $self->render(json => \@ret);
  }
  else {
    $self->render(json => { errmsg => "No hits for '".$self->param('q')."' in domain '".$domain->{name}."'", status => 400 });
  }

}

sub domain {
  my $self = shift;
  my $domain = $self->check_domain;
  if ($domain) {
    $self->render(json => $domain);
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
  $sth->execute($domain->{id});
  while (my $r = $sth->fetch) {
    my %dta;
    @dta{@{$sth->{NAME}}} = @$r;
    push @ret, \%dta;
  }
  $self->render(json => \@ret);
}

sub check_domain {
  my $self = shift;
  my $dom = $self->stash('domain_id');
  return unless $dom;
  my ($r, $sth);
  for ($self->domain_by_id_sth, $self->domain_by_name_sth) {
    $sth=$_;
    $sth->execute($dom);
    $r = $sth->fetch;
    last if ($r);
  }
  if ($r) {
    my %dta;
    @dta{@{$sth->{NAME}}} = @$r;
    return \%dta;
  }
  else {
    return;
  }
}

1;

