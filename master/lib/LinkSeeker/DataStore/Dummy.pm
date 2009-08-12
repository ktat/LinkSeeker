package LinkSeeker::DataStore::Dummy;

use Any::Moose;

extends 'LinkSeeker::DataStore';

has url => (is => 'rw');
has path => (is => 'rw');

sub store_data {
  warn "dummy store";
  return;
}

sub fetch_data {
  warn "dummy fetch";
  return;
}

sub has_data {
  warn "dummy has";
  return;
}

1;
