package LinkSeeker::Sites;

use Data::Dumper;
use Any::Moose;

has site_count => (is => 'rw', default => 0, isa => 'Int');
has sites     => (is => 'rw', default => sub {[]});
has ls        => (is => 'rw', isa => 'LinkSeeker');

sub BUILDARGS {
  my ($self, $linkseeker, $sites_info) = @_;
  my @sites;
  foreach my $site (keys %$sites_info) {
    push @sites, LinkSeeker::Sites::Site->new
      ($linkseeker, {name => $site, %{$sites_info->{$site}}});
    $linkseeker->debug('site object is created: ' . $sites[-1]->name);
  }
  return {sites => \@sites};
}

sub next_site {
  my $self = shift;
  my $count = $self->site_count;
  if (@{$self->sites} == $count) {
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
