package LinkSeeker::Log;

use Any::Moose;
extends "LinkSeeker::SubClassBase";

has level => (is => 'rw');

my %LOG_LEVEL = (
                 FATAL => 0,
                 ERROR => 1,
                 WARN  => 2,
                 INFO  => 3,
                 DEBUG => 4,
);

foreach my $level (keys %LOG_LEVEL) {
  no strict "refs";
  my $lc_level = lc $level;
  *{__PACKAGE__ . '::' . $lc_level} = sub {
    my ($self, $message) = @_;
    if ($self->level >= $LOG_LEVEL{$level}) {
      $message = "[$lc_level] " . $message;
      if ($self->can("_do_log")) {
        return $self->_do_log($message);
      } else {
        return $message;
      }
    }
  };
}

sub BUILDARGS {
  my ($class, $ls, $opt) = @_;
  $opt->{level} = $LOG_LEVEL{uc($opt->{level})} || 0;
  { ls => $ls, %$opt };
}

1;

=pod

=head1 NAME

LinkSeeker::Log

=head1 METHOD

=head2 fatal

fatal message

=head2 error

error message

=head2 warn

warn message

=head2 info

info message

=head2 debug

debug message

=head1 SYNOPSYS

 log:
   class: LogSubClass
   level: debug

=head1 COPYRIGHT & LICENSE

Copyright 2009 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

