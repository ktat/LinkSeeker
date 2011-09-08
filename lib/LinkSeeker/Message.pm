package LinkSeeker::Message;

use Any::Moose;
extends "LinkSeeker::SubClassBase";

has level => (is => 'rw');

sub BUILDARGS {
  my ($class, $ls, $opt) = @_;
  { ls => $ls, %$opt };
}

sub ok {
  my ($self, $message) = @_;
  $self->_do_message(ok => $message);
}

sub ng {
  my ($self, $message) = @_;
  $self->_do_message(ng => $message);
}

1;

=pod

=head1 NAME

LinkSeeker::Message

=head1 METHOD

=head2 ok

ok message

=head2 ng

ng message

=head1 SYNOPSYS

 message:
   class: Stderr

=head1 COPYRIGHT & LICENSE

Copyright 2011 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

