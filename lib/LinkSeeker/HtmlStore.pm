package LinkSeeker::HtmlStore;

use Any::Moose;

extends "LinkSeeker::SubClassBase";

has store => (is => 'rw', default => '');

sub fetch_content {
  warn "store_content should be implemented in sub-class";
}

sub store_content {
  warn "fetch_content should be implemented in sub-class";
}

sub has_content {
  warn "has_content should be implemented in sub-class";
}

1;
