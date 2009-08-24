package LinkSeeker::Scraper::LinkExtor;

use Any::Moose;
use HTML::LinkExtor;
use URI;

extends 'LinkSeeker::Scraper';

has match => (is => 'rw');

sub process {
  my ($self, $src) = @_;
  my $match = $self->match;
  my $base_url = $self->base_url;
  my @urls;
  my $cb = sub {
    my($tag, %attr) = @_;
    return if $tag ne 'a' or not defined $attr{href} or $attr{href} =~/^#/;
    if (defined $match) {
      return if $attr{href} !~ qr/$match/;
    }
    push (@urls, URI->new_abs($attr{href}, $base_url));
  };
  my $p = HTML::LinkExtor->new($cb);
  $p->parse($src);
  return { link_seeker_url => \@urls };
}

1;

=pod

=head1 NAME

LinkSeeker::Scraper::LinkExtor - extract links with HTML::LinkExtor

=head1 SYNOPSYS

 scrpaer:
   class: LinkExtor
   # regexp to match URL
   match: news/.+/.+\.html

=head1 DESCRIPTION

LinkExtor extract links from source with HTML::LinkExtor.
If you set regexp as match, only links matched with the regexp are extracted.
These links are stored in hash ref with key 'link_seeker_url'.

 {
    link_seeker_url => [
       'http://matched.example.com/1',
       ...
    ],
 }


=head1 COPYRIGHT & LICENSE

Copyright 2009 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

