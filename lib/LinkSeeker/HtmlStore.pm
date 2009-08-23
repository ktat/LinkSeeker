package LinkSeeker::HtmlStore;

use Any::Moose;

extends "LinkSeeker::SubClassBase";

has store => (is => 'rw', default => '');

sub fetch_content {
  warn "store_content should be implemented in sub-class";
}

sub store_content {
  warn "fetch_content should be implemented in sub-class";
}

sub has_content {
  warn "has_content should be implemented in sub-class";
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

implement the following methods in sub class.

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
