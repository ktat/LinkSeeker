package LinkSeeker::HtmlStore::File;

use Any::Moose;
use File::Slurp qw/slurp write_file/;
use URI::Escape qw/uri_escape/;

extends 'LinkSeeker::HtmlStore';

has 'path', (is => 'rw');

sub store_content {
  my ($self, $name, $name_or_url, $src) = @_;
  my $path = join '/', $self->path, $name;
  unless (-d $path) {
    unless (-d $self->path) {
      mkdir $self->path;
    }
    mkdir join '/', $path;
  }
  my $file_name = join '/', $path, uri_escape($name_or_url);
  write_file($file_name, $src);
}

sub fetch_content {
  my ($self, $name, $name_or_url) = @_;
  my $path = join '/', $self->path, $name;
  my $file_name = join '/', $path, uri_escape($name_or_url);
  return scalar slurp($file_name);
}

sub has_content {
  my ($self, $name, $name_or_url) = @_;
  Carp::croak "name/url is required" unless $name_or_url;
  my $path = join '/', $self->path, $name;
  my $file_name = join '/', $path, uri_escape($name_or_url);
  return -e $file_name || 0;
}

1;
