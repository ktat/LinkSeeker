package LinkSeeker::Cookies;

use LinkSeeker::Cookies::Cookie;
use Any::Moose;

has cookies => (is => 'rw');

sub parse {
  my ($self, $url, @cookies_string) = @_;
  my @cookies;

  foreach my $cookie (@cookies_string) {
    push @cookies, LinkSeeker::Cookies::Cookie->parse($url, $cookie);
  }
  $self->new(cookies => \@cookies);
}

override cookies => sub {
  my ($self, $cookies) = @_;
  if (@_ == 2) {
    $self->{cookies} = $cookies;
  }
  return wantarray ? @{$self->{cookies}} : $self->{cookies};
};

sub as_request_string {
  my ($self, $url) = @_;
  my @data;
  foreach my $c (grep $_->is_apply($url), $self->cookies) {
    push @data, $c->as_request_string($url);
  }
  return join '; ', @data;
}

sub as_response_string {
  my ($self) = @_;
  my @data;
  foreach my $c ($self->cookies) {
    push @data, $c->as_response_string;
  }
  return \@data;
}

sub merge_cookie {
  my ($self, $cookie_new) = @_;
  my %c;
  foreach my $c ($self->cookies) {
    $c{$c->name} = $c;
  }
  foreach my $c ($cookie_new->cookies) {
    $c{$c->name} = $c;
  }
  $self->cookies([values %c]);
}

sub remove_expires {
  my ($self, $url) = @_;
  $self->cookies([grep $_->is_apply_strict($url), $self->cookies]);
}

1;

=pod

=head1 NAME

LinkSeeker::Cookies -  handling cookie (cheap implementation)

=head1 METHOD

=head2 parse

 $c->parse($url, @cookie_strings);

=head2 cookies

 $c->cookies(\@cookies_objects)

store LinkSeeker::Cookies::Cookie objects.

=head2 as_request_string

 $c->as_request_string($url);

=head2 as_response_string

 $c->as_response_string;

=head2 merge_cookie

 $c->merge_cookie($new_cookie);

=head2 remove_expires

 $c->remove_expires($url);

=head1 COPYRIGHT & LICENSE

Copyright 2009 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
