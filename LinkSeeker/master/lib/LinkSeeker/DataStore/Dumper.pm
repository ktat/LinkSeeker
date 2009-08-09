package LinkSeeker::DataStore::Dumper;

use Any::Moose;
use Data::Dumper;
use File::Slurp qw/slurp write_file/;
use URI::Escape qw/uri_escape/;

extends 'LinkSeeker::DataStore';

has url => (is => 'rw');
has path => (is => 'rw');

sub store_data {
  my ($self, $name, $name_or_url, $data) = @_;
  my $path = join '/', $self->path, $name;
  unless (-d $path) {
    unless (-d $self->path) {
      mkdir $self->path;
    }
    mkdir join '/', $path;
  }
  my $file_name = join '/', $path, uri_escape($name_or_url);
  local $Data::Dumper::Terse = 1;
  write_file($file_name, Dumper($data));
}

sub fetch_data {
  my ($self, $name, $name_or_url) = @_;
  my $path = join '/', $self->path, $name;
  my $file_name = join '/', $path, uri_escape($name_or_url);
  my $data = slurp($file_name);
  return eval "$data";
}

sub has_data {
  my ($self, $name, $name_or_url) = @_;
  my $path = join '/', $self->path, $name;
  my $file_name = join '/', $path, uri_escape($name_or_url);
  return -e $file_name || 0;
}

1;
