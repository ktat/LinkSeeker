package LinkSeeker::Log::Stderr;

use Any::Moose;
extends 'LinkSeeker::Log';

sub do_log {
  my ($self, $message) = @_;;
  print STDERR $message, "\n";
}

1;
