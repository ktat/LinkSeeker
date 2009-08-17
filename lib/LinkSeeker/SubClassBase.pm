package LinkSeeker::SubClassBase;

use Any::Moose;

has ls => (is => 'rw');

sub BUILDARGS {
  my ($self, $ls, $opt) = @_;
  { ls => $ls, %$opt };
}


1;
