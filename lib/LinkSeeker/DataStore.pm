package LinkSeeker::DataStore;

use Any::Moose;

extends "LinkSeeker::SubClassBase";

has store => (is => 'rw', default => '');

sub fetch_data {
  warn "store_data should be implemented in sub-class";
}

sub store_data {
  warn "fetch_data should be implemented in sub-class";
}

sub has_data {
  warn "has_data should be implemented in sub-class";
}

1;
