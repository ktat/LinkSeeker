package LinkSeeker::HtmlStore::File;

use Any::Moose;
use File::Slurp qw/slurp write_file/;
use URI::Escape qw/uri_escape/;

extends 'LinkSeeker::HtmlStore';

has 'path', (is => 'rw');

sub store_content {
  my ($self, $site_name, $name_or_url, $src) = @_;
  my $path = join '/', $self->path, $site_name;
  unless (-d $path) {
    unless (-d $self->path) {
      mkdir $self->path;
    }
    mkdir $path;
  }
  my $file_name = join '/', $path, uri_escape($name_or_url);
  $self->ls->debug("html is written to: $file_name");
  write_file($file_name, $src);
}

sub fetch_content {
  my ($self, $site_name, $name_or_url) = @_;
  my $path = join '/', $self->path, $site_name;
  my $file_name = join '/', $path, uri_escape($name_or_url);
  $self->ls->debug("html is read from: $file_name");
  return scalar slurp($file_name);
}

sub has_content {
  my ($self, $site_name, $name_or_url) = @_;
  Carp::croak "name/url is required" unless $name_or_url;
  my $path = join '/', $self->path, $site_name;
  my $file_name = join '/', $path, uri_escape($name_or_url);
  return -e $file_name || 0;
}

1;

=pod

=head1 NAME

LinkSeeker::HtmlStore

=head1 SYNOPSYS

 html_store:
   class: HtmlStoreSubClass
   option: value

=head1 METHOD

=head2 fetch_content

 $o->fetch_content($site_name, $unique_name);

fetch stored content(html source)

=head2 store_content

 $o->has_data($site_name, $unique_name, $data)

store fetched content(html source)

=head2 has_content

if having content, return 1 or 0.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
