package LinkSeeker::SubClassBase;

use Any::Moose;

has ls => (is => 'rw', isa => 'LinkSeeker');

sub BUILDARGS {
  my ($self, $ls, $opt) = @_;
  { ls => $ls, %$opt };
}

1;

=pod

=head1 NAME

LinkSeeker::SubClassBase - base class for LinkSeeker sub class

=head1 COPYRIGHT & LICENSE

Copyright 2009 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
