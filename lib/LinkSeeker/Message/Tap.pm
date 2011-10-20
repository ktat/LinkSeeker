package LinkSeeker::Message::Tap;

use Any::Moose;
use Test::More ();

extends 'LinkSeeker::Message';

sub _do_message {
  my ($self, $status, $message) = @_;;
  if ($message =~ m{https?://(.+?):(.+?)@}) {
     $message  =~ s{(https?://)(?:.+?):(?:.+?)@}{$1};
  }
  if ($status eq 'ok') {
    Test::More::ok 1, "$status $message";
  } else {
    Test::More::ok 0, "not ok $message";
  }
}

1;

=pod

=head1 NAME

LinkSeeker::Message::Tap -- TAP output

=head1 SYNOPSYS

 message:
   class: Tap

=head1 COPYRIGHT & LICENSE

Copyright 2011 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
