package LinkSeeker::Sites::Site::URL;

use Any::Moose;

has url => (is => 'rw');
has base => (is => 'rw');
has from => (is => 'rw');
has post_data => (is => 'rw');
has unique_name  => (is => 'rw');
has header => (is => 'rw', isa => 'HashRef');
has agent  => (is => 'rw',);

override unique_name => sub {
  my ($self) = @_;
  my $url = $self->url;
  my $unique = $self->{unique_name};
  if (my $re = $unique->{regexp}) {
    if ($url =~ m{$re}) {
      return $1;
    }
  }
  return $url;
};

1;
