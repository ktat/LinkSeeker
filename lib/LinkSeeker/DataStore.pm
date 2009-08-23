package LinkSeeker::DataStore;

use Any::Moose;

extends "LinkSeeker::SubClassBase";

has store => (is => 'rw', default => '');

sub fetch_data {
  warn "store_data should be implemented in sub-class";
}

sub store_data {
  warn "fetch_data should be implemented in sub-class";
}

sub has_data {
  warn "has_data should be implemented in sub-class";
}

1;

=pod

=head1 NAME

LinkSeeker::DataStore

=head1 SYNOPSYS

 data_store
   class: DataStoreSubClass
   option: value

=head1 METHODS

implement the following methods in sub class.

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
