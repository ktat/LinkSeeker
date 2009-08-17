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
