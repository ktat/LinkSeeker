package LinkSeeker::Sites;

use Data::Dumper;
use Any::Moose;

has url_count => (is => 'rw', default => 0, isa => 'Int');
has sites     => (is => 'rw', default => sub {[]});
has ls        => (is => 'rw', isa => 'LinkSeeker');

sub BUILDARGS {
  my ($self, $linkseeker, $sites_info) = @_;
  my @sites;
  foreach my $site (keys %$sites_info) {
    push @sites, LinkSeeker::Sites::Site->new($linkseeker, {name => $site, %{$sites_info->{$site}}});
  }
  return {sites => \@sites};
}

sub next_site {
  my $self = shift;
  my $count = $self->url_count;
  my $site = $self->sites->[$count++];
  $self->url_count($count);
  return $site;
}

1;
