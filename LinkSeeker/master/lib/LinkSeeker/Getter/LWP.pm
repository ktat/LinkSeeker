package LinkSeeker::Getter::LWP;

use Any::Moose;
use LWP::UserAgent;

extends 'LinkSeeker::Getter';
has agent => (is => 'rw', default => 'LinkSeeker version ' . LinkSeeker->VERSION);
has header => (is => 'rw', isa => 'HashRef');

sub process {
  my $self = shift;
  my ($site_info, $data) = @_;
  print Data::Dumper::Dumper($site_info);
}

sub get {
  my ($self, $url) = @_;
  warn "get $url";
  my $ua = LWP::UserAgent->new;
  $ua->agent($self->agent || 'LinkSeeker - ' . LinkSeeker->VERSION);
  if (my $h = $self->header) {
    if ($h->{referer}) {
      $ua->default_header(Referrer => $self->header->{referer});
    }
  }
  my $res = $ua->get($url);
  if ($res->is_success) {
    return $res->content;
  } else {
    return;
  }
}

1;
