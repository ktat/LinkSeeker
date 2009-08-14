package LinkSeeker::Getter;

use Any::Moose;

has store => (is => 'rw', default => '');

sub BUILDARGS {
  my ($self, $class, $getter_info) = @_;
  { class => $class, %$getter_info };
}

1;
