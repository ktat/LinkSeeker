package LinkSeeker::CookieStore::File;

use Any::Moose;
use File::Slurp qw/slurp write_file/;

extends "LinkSeeker::CookieStore";

has path => (is => 'rw');

sub store_cookie {
  my ($self, $url, $cookies) = @_;
  my $path = $self->path;
  if ($path eq $ENV{TMPDIR}) {
    $path .= '/link_seeker';
  }
  if (!-d $path) {
    mkdir $path or die "cannot create directory: " . $path;
  }
  write_file($self->_file_name($url), join "\n", @{$cookies->as_response_string});
  return $cookies;
}

sub fetch_cookie {
  my ($self, $url) = @_;
  my $f = $self->_file_name($url);
  if (my $cookies = -e $f ? scalar slurp($f) : '') {
    return LinkSeeker::Cookies->parse($url, split /[\r\n]/, $cookies);
  }
  return;
}

sub _file_name {
  my ($self, $url) = @_;
  my ($domain) = $url =~m{^https?://([^/]+)};
  my $path = $self->path eq $ENV{TMPDIR} ? $self->path . '/link_seeker' : $self->path;
  return join '/', $path, $domain;
}

1;
