package LinkSeeker::Sites;

use Data::Dumper;
use Any::Moose;

has site_count => (is => 'rw', default => 0, isa => 'Int');
has sites     => (is => 'rw', default => sub {[]});
has ls        => (is => 'rw', isa => 'LinkSeeker');

sub BUILDARGS {
  my ($self, $linkseeker, $sites_info) = @_;
  my @sites;
  foreach my $site (sort {$a cmp $b} keys %$sites_info) {
    push @sites, LinkSeeker::Sites::Site->new
      ($linkseeker, {name => $site, %{$sites_info->{$site}}});
    $linkseeker->debug('site object is created: ' . $sites[-1]->name);
  }
  return {ls => $linkseeker, sites => \@sites};
}

sub next_site {
  my $self = shift;
  my $count = $self->site_count;
  if (@{$self->sites} == $count) {
    $self->ls->total_count(scalar @{$self->sites});
    $self->site_count(0);
    return;
  } else {
    my $site = $self->sites->[$count];
    $self->site_count(++$count);
    return $site;
  }
}

sub reset_site_count {
  my ($self) = shift;
  $self->sites->site_count(0);
}

1;

=pod

=head1 NAME

LinkSeeker::Sites

=head1 METHODS

=head2 next_site

 while (my $site = $sites->next_site) {
   # ...
 }

if existing next site, return it and increment site count.
if not existing next site, return undef and reset site count.
So, you can use next site in another place, again.


=head2 reset_site_count

reset site count.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
