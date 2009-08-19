package LinkSeeker::Sites::Site::URL;

use Any::Moose;
use LinkSeeker::Cookies;

has url => (is => 'rw');
has base => (is => 'rw');
has from => (is => 'rw');
has post_data => (is => 'rw');
has unique_name  => (is => 'rw');
has header => (is => 'rw', isa => 'HashRef');
has agent  => (is => 'rw',);
has ls => (is => 'rw');

override unique_name => sub {
  my ($self) = @_;
  my $url = $self->url;
  my $unique = $self->{unique_name};
  if (my $re = $unique->{regexp}) {
    if (my @matches = $url =~ m{$re}) {
      return join "", @matches;
    }
  } elsif ($re = $unique->{variable}) {
    $re =~s/^\$//;
    return $self->ls->$re;
  }
  return $url;
};

1;
