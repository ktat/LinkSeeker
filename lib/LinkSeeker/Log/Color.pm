package LinkSeeker::Log::Color;

use strict;
use warnings;
use Any::Moose;
use Term::ANSIColor qw(:constants);

extends 'LinkSeeker::Log';

sub _do_log {
  my ($self, $message) = @_;;
  if ($message =~ m{https?://(.+?):(.+?)@\w+}) {
     $message =~ s{(https?://)(?:.+?):(?:.+?)@}{$1};
  }
  $message .= "\n";
  my $level = $self->level;
  if ($level == 0) { # fatal
    print STDERR RED;
  } elsif ($level == 1) { # error
    print STDERR RED;
  } elsif ($level == 2) { # warn
    print STDERR YELLOW;
  } elsif ($level == 3) { # info
    print STDERR BLUE;
  } elsif ($level == 4) { # debug
    print STDERR GREEN;
  }
  print STDERR $message;
  print STDERR RESET;
}

1;

=pod

=head1 NAME

LinkSeeker::Log::Color

=head1 SYNOPSYS

 log:
   class: Color
   level: debug

=head1 COPYRIGHT & LICENSE

Copyright 2011 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
