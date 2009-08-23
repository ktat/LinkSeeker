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

=pod

=head1 NAME

LinkSeeker::DataStore::Dumper

=head1 SYNOPSYS

 data_store:
   class: Dumper
   path: /path/to/store

=head1 METHODS

=head2 fetch_data

 $o->fetch_data($site_name, $unique_name);

fetch stored data

=head2 store_data

 $o->has_data($site_name, $unique_name, $data)

store fetched data

=head2 has_data

 $o->has_data($site_name, $unique_name)

if having data, return 1 or 0;

=head1 COPYRIGHT & LICENSE

Copyright 2009 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
