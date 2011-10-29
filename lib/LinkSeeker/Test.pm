package LinkSeeker::Test;

use Any::Moose;
extends "LinkSeeker::SubClassBase";

has level => (is => 'rw');

sub BUILDARGS {
  my ($class, $ls) = @_;
  { ls => $ls};
}

sub ok {
  my ($self, $test, $message) = @_;
  $self->ls->message->_do_message(($test ? 'ok' : 'ng') => $message);
}

sub is {
  my ($self, $test, $answer, $message) = @_;
  $self->ls->message->_do_message(($test eq $answer ? 'ok' : 'ng') => $message);
}

sub like {
  my ($self, $test, $answer, $message) = @_;
  $self->ls->message->_do_message(($test =~m{$answer} ? 'ok' : 'ng') => $message || '');
}

1;

=pod

=head1 NAME

LinkSeeker::Test

=head1 SYNOPSYS

 $ls->t->ok($test, $message);
 $ls->t->is($test, $answer, $message);
 $ls->t->like($test, $match, $message);

=head1 METHOD

=head2 ok

 $ls->t->ok($test, $message)

if $test is true, it is ok.

=head2 is

 $ls->t->is($test, $answer, $message)

if $test is equal to $answer, it is ok.

=head2 like

 $ls->t->like($test, $match, $message)

if $test is match $match(regexp), it is ok.

=head1 COPYRIGHT & LICENSE

Copyright 2011 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

