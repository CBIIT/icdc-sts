use v5.10;
use GDC::Dict;
use Carp qw/carp/;
use DBI;
use strict;

my $gdcschemas="$ENV{HOME}/Code/NCI-GDC/gdcdictionary/gdcdictionary/schemas";
my $dbfile=shift();
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile");
$dbh->{RaiseError}=1;
my %sth;
my %stmt = (
  term => "INSERT INTO term (term, concept_code, authority) VALUES(?, ?, 2)",
  domain => "INSERT INTO domain (name, domain_code, authority) VALUES(?, ?, 1)",
  term_domain => "INSERT INTO term_domain (domain, term) VALUES(?, ?)",
  prop_domain => "INSERT INTO prop_domain (property, domain) VALUES(?, ?)",
  get_term_id => "SELECT id, term FROM term WHERE term = ?",
  get_domain_id => "SELECT id, name FROM domain WHERE name = ?",
 );

for (keys %stmt) {
  $sth{$_} = $dbh->prepare($stmt{$_});
}


my $dict=GDC::Dict->new($gdcschemas);

for my $n ($dict->nodes) {
  for my $p ($n->properties) {
    next unless (defined $p->term && (ref $p->term eq 'HASH') && defined $p->term->{termDef} && (ref $p->term->{termDef} eq 'HASH'));
    say $p->name;
    my @vals = $p->values;
    if (@vals > 1) {
      my ($r, $d_id, $t_id);
      my $d_name = $p->term->{termDef}{term};
      $sth{domain}->execute($d_name,
                                   join('', $p->term->{termDef}{cde_id},'v',
                                        $p->term->{termDef}{cde_version}));
      $sth{get_domain_id}->execute($d_name);
      $r = $sth{get_domain_id}->fetch;
      unless ($r) {
        carp "failed to get new domain id on '$d_name', skipping...";
        next;
      }
      $d_id = $r->[0];
      $sth{prop_domain}->execute($p->name, $d_id);
      for my $v (@vals) {
        $sth{term}->execute($v, undef);
        $sth{get_term_id}->execute($v);
        $r = $sth{get_term_id}->fetch;
        unless ($r) {
          carp "failed to get new term id on '$v', skipping...";
          next;
        }
        $t_id = $r->[0];
        $sth{term_domain}->execute($d_id,$t_id);
      }
      
      1;
    }
  }
}


1;
