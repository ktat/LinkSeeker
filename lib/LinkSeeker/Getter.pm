package LinkSeeker::Getter;

use Any::Moose;

extends "LinkSeeker::SubClassBase";

has store => (is => 'rw', default => '');

1;

=pod

=head1 NAME

LinkSeeker::Getter

=head1 SYNOPSYS

 getter:
   class: GetterSubClass
   option: value

=head1 COPYRIGHT & LICENSE

Copyright 2009 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
