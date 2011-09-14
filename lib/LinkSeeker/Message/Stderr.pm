package LinkSeeker::Message::Stderr;

use Any::Moose;
extends 'LinkSeeker::Message';

sub _do_message {
  my ($self, $status, $message) = @_;;
  if ($message =~ m{https?://(.+?):(.+?)@}) {
     $message  =~ s{(https?://)(?:.+?):(?:.+?)@}{$1};
  }
  if ($status eq 'ok') {
    print STDERR "\e[36m" . uc($status) . "\e[m ", $message, "\n"
  } else {
    print STDERR "\e[31m" . uc($status) . "\e[m ", $message, "\n"
  }
}

1;

=pod

=head1 NAME

LinkSeeker::Message::Stderr

=head1 SYNOPSYS

 message:
   class: Stderr

=head1 COPYRIGHT & LICENSE

Copyright 2011 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
