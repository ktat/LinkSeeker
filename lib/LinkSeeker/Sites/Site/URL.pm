package LinkSeeker::Sites::Site::URL;

use Any::Moose;
use LinkSeeker::Cookies;

has url => (is => 'rw');
has base => (is => 'rw');
has from => (is => 'rw');
has post_data => (is => 'rw');
has unique_name  => (is => 'rw');
has header => (is => 'rw', isa => 'HashRef');
has agent  => (is => 'rw',);
has ls => (is => 'rw', isa => 'LinkSeeker');
has method => (is => 'rw', default => 'get');

override unique_name => sub {
  my ($self) = @_;
  my $url = $self->url;

  my $unique = $self->{unique_name};

  if (ref $unique) {
    if (my $re = $unique->{regexp}) {
      if (my @matches = $url =~ m{$re}) {
        return join "", @matches;
      }
    } elsif ($re = $unique->{variable}) {
      $re =~s/^\$//;
      return $self->ls->$re;
    }
  } elsif($unique) {
    return $unique;
  }
  return $url;
};

1;
=pod

=head1 NAME

LinkSeeker::Sites::Site::URL

=head1 METHODS

=head2 unique_name

 $url->unique_name;

=head2 fetch_cookie

=head2 store_cookie

=head1 COPYRIGHT & LICENSE

Copyright 2009 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
