package LinkSeeker::Sites::Site::URL;

use Any::Moose;

has url => (is => 'rw');
has test => (is => 'rw');
has base => (is => 'rw');
has from_base => (is => 'rw');
has from => (is => 'rw');
# has match => (is => 'rw');
has post_data => (is => 'rw');
has _unique_name  => (is => 'rw');
has header => (is => 'rw', isa => 'HashRef');
has agent  => (is => 'rw',);
has ls => (is => 'rw', isa => 'LinkSeeker');
has method => (is => 'rw', default => 'get');
has no_redirect => (is => 'rw', default => 0);

sub BUILDARGS {
  my ($class, %opt) = @_;
  $opt{_unique_name} = $opt{unique_name};
  $opt{test} ||= {};
  Carp::confess("url/from is empty") if not $opt{url} and not $opt{from};
  return \%opt;
}

sub unique_name {
  my ($self, $data) = @_;
  my $url = $self->url or Carp::confess "URL is empty!";
  my $unique = $self->_unique_name;

  if (ref $unique) {
    if (my $re = $unique->{regexp}) {
      if (my @matches = $url =~ m{$re}) {
        return join "", @matches;
      }
    } elsif ($re = $unique->{variable}) {
      $re =~s/^\$//;
      return $self->ls->$re;
    } else {
      # if having data and method is md5 return md5sum?
    }
  } elsif($unique) {
    return $unique;
  } else {
    # use URL as is
    $url =~ s{^(https?://)\w+:\w+\@}{$1};
  }
  return $url;
};

sub clone {
  my ($self) = @_;
  my $ls = delete $self->{ls};
  my $clone = Clone::clone($self);
  $self->ls($ls);
  $clone->ls($ls);
  return $clone;
}

1;

=pod

=head1 NAME

LinkSeeker::Sites::Site::URL

=head1 METHODS

=head2 unique_name

 $url->unique_name;

=head2 clone

 my $cloned_url = $url->clone;

clone URL object.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
