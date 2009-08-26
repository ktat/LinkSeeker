package LinkSeeker::Log::File;

use Any::Moose;
extends 'LinkSeeker::Log';

has 'path' => (is => 'rw');
has 'fh'   => (is => 'rw');

sub BUILD {
  super();
  my ($self) = @_;
  open my $fh, '>>', $self->path or die "cannot open file: " . $self->path;
  $self->fh($fh);
  return $self;
}

sub _do_log {
  my ($self, $message) = @_;;
  my $fh = $self->fh;
  print $fh $message, "\n";
}

sub DESTROY {
  my ($self) = @_;
  if (my $fh = $self->fh) {
    close $fh or die "cannot close file: " . $self->path;
  }
}

1;

=pod

=head1 NAME

LinkSeeker::Log::File

=head1 SYNOPSYS

 log:
   class: File
   level: debug
   path: path/to/log_file

=head1 COPYRIGHT & LICENSE

Copyright 2009 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
