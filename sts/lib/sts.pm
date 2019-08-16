package sts;
use Mojo::Base 'Mojolicious';
use DBI;
use Cwd;

our %stmt = (
  validate => <<Q,
    select domain,domain_id,term, term_id, concept_code, au.name as term_authority,
      au.uri as term_authority_uri
    from (select d.name as domain, d.id as domain_id, t.id as term_id, t.term as term, td.concept_code as concept_code, td.authority as authority
      from term t inner join term_domain td
      on t.id=td.term
      inner join domain d
      on td.domain=d.id
      where t.term = ?
      and d.id = ?) s left join authority au
      on s.authority = au.id
Q
  list => <<Q,
  select t.term as term, t.id as term_id, td.concept_code as concept_code,
      au.name as term_authority, au.uri as term_authority_uri
      from term t 
      inner join domain d
      on t.id=td.term
      inner join term_domain td
      on td.domain=d.id
      left join authority au
      on td.authority = au.id
      where d.id = ?
Q
  search_terms => <<Q,
  select t.term as term, t.id as term_id, td.concept_code as concept_code,
      au.name as term_authority, au.uri as term_authority_uri
      from term t 
      inner join domain d
      on t.id=td.term
      inner join term_domain td
      on td.domain=d.id
      left join authority au
      on td.authority = au.id
      where d.id = ? and
            t.term like ?
Q
  term_info_by_id => <<Q,
  select term, term_id, concept_code,
    domain_name, domain_id, domain_code,
    term_authority, term_authority_uri,
    a.name as domain_authority, a.uri as domain_authority_uri from 
    (select t.term as term, t.id as term_id, td.concept_code as concept_code,
      au.name as term_authority, au.uri as term_authority_uri,
      d.name as domain_name,
      d.id as domain_id,
      d.authority as d_auth_id, d.domain_code as domain_code
      from term t 
      inner join domain d
      on t.id=td.term
      inner join term_domain td
      on td.domain=d.id
      left join authority au
      on td.authority = au.id
      where t.id = ?) ti
    left join authority a
      on ti.d_auth_id = a.id
Q
  domain_info_by_id => <<Q,
  select d.name as domain_name,d.id as domain_id, domain_code,
    au.name as domain_authority, au.uri as domain_authority_uri
    from domain d 
    left join authority au
    on d.authority = au.id
    where d.id = ?
Q
  domain_info_by_name => <<Q,
  select d.name as domain_name,d.id as domain_id, domain_code,
    au.name as domain_authority, au.uri as domain_authority_uri
    from domain d 
    left join authority au
    on d.authority = au.id
    where d.name = ?
Q
  domain_id_by_prop => <<Q,
  select domain, property
  from prop_domain
  where property = ?
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
  $self->helper( search_terms_sth => sub { $sth{search_terms} } );
  $self->helper( domain_info_by_id_sth => sub { $sth{domain_info_by_id} } );
  $self->helper( domain_info_by_name_sth => sub { $sth{domain_info_by_name} } );
  $self->helper( term_info_by_id_sth => sub { $sth{term_info_by_id} } );
  $self->helper( domain_id_by_prop_sth => sub { $sth{domain_id_by_prop} } );
}
1;
