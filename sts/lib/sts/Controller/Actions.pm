package sts::Controller::Actions;
use Mojo::Base 'Mojolicious::Controller';

sub validate {
  my $self = shift;
  $self->render('actions/test', msg => 'validate');
}

sub search {
  my $self = shift;
  $self->render('actions/test', msg => 'search');
}

sub domain {
  my $self = shift;
  $self->render('actions/test', msg => 'domain')
}

sub list {
  my $self = shift;
  $self->render('actions/test', msg => 'list');
}

1;
