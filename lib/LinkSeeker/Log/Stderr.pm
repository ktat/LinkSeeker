package LinkSeeker::Log::Stderr;

use Any::Moose;
extends 'LinkSeeker::Log';

sub _do_log {
  my ($self, $message) = @_;;
  print STDERR $message, "\n";
}

1;

=pod

=head1 NAME

LinkSeeker::Log::Stderr

=head1 SYNOPSYS

 log:
   class: Stderr
   level: debug

=head1 COPYRIGHT & LICENSE

Copyright 2009 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
