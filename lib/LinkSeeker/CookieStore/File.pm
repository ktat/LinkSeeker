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
  my %cookies;
  foreach my $cookie (@{$cookies->cookies}) {
    push @{$cookies{$self->_file_name($url, $cookie->domain)} ||= []}, $cookie->as_response_string;
  }
  foreach my $file (keys %cookies) {
    next unless $file;
    $self->ls->info("cookie is written to: $file");
    write_file($file, join "\n", @{$cookies{$file}});
  }
  return $cookies;
}

sub fetch_cookie {
  my ($self, $url) = @_;
  my @files;
  if (opendir my $dir, $self->path) {
    my ($domain) = $url =~m{^https?://([^/]+)};
    foreach my $file (grep !/^\.\.?$/, readdir $dir) {
      if ($domain =~m{\Q$file\E}) {
	push @files, join '/', $self->path, $file;
      }
    }
  }
  push @files, $self->_file_name($url);
  my $cookies = '';
  foreach my $f (@files) {
    if (my $cookie = -e $f ? scalar slurp($f) : '') {
      $cookies .= $cookie;
    }
  }
  if ($cookies) {
    return LinkSeeker::Cookies->parse($url, split /[\r\n]/, $cookies);
  } else {
    return;
  }
}

sub _file_name {
  my ($self, $url, $domain) = @_;
  ($domain) = $url =~m{^https?://([^/]+)} unless $domain;
  my $path = $self->path eq $ENV{TMPDIR} ? $self->path . '/link_seeker' : $self->path;
  my $f = join '/', $path, $domain;
  return $f;
}

1;
