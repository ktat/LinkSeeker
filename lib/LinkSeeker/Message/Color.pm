package LinkSeeker::Message::Color;

use Any::Moose;
use Term::ANSIColor qw(:constants);
extends 'LinkSeeker::Message';

sub _do_message {
  my ($self, $status, $message) = @_;;
  if ($message =~ m{https?://(.+?):(.+?)@}) {
     $message  =~ s{(https?://)(?:.+?):(?:.+?)@}{$1};
  }
  my $indent = '  ' x $self->ls->site_depth;
  if ($status eq 'ok') {
    print STDERR GREEN;
    print STDERR "$indent" . uc($status) . RESET . " ", $message, "\n"
  } else {
    print STDERR RED;
    print STDERR "$indent" . uc($status) . RESET . " ", $message, "\n"
  }
}

1;

=pod

=head1 NAME

LinkSeeker::Message::Color -- output colored message

=head1 SYNOPSYS

 message:
   class: Color

=head1 COPYRIGHT & LICENSE

Copyright 2011 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
