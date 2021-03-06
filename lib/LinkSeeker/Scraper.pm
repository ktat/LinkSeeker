package LinkSeeker::Scraper;

use Any::Moose;

extends "LinkSeeker::SubClassBase";

has 'base_url' => (is => 'rw');

our $AUTOLOAD;
sub AUTOLOAD {
  my $self = shift;
  $AUTOLOAD =~s{^.+::}{};
  $self->ls->info($AUTOLOAD . ' is not implement. scraper does nothing.');
}

1;

=pod

=head1 NAME

LinkSeeker::Scraper

=head1 SYNOPSYS

 scraper:
   class: ScraperSubClass
   option: value

=head1 COPYRIGHT & LICENSE

Copyright 2009 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
