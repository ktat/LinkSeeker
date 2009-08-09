package LinkSeeker::DataStore;

use Any::Moose;

has store => (is => 'rw', default => '');

sub BUILDARGS {
  my ($self, $class, $store_info) = @_;
  { class => $class, %$store_info };
}

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
