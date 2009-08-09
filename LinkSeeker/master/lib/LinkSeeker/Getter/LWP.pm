package LinkSeeker::Getter::LWP;

use Any::Moose;
use LWP::UserAgent;

extends 'LinkSeeker::Getter';
has agent => (is => 'rw', default => 'LinkSeeker version ' . LinkSeeker->VERSION);

sub process {
  my $self = shift;
  my ($site_info, $data) = @_;
  print Data::Dumper::Dumper($site_info);
#  return LWP::Simple::get($self->url);
}

sub get {
  my ($self, $url) = @_;
  warn "get $url";
  my $ua = LWP::UserAgent->new;
  $ua->agent('LinkSeeker - ' . LinkSeeker->VERSION);
  my $res = $ua->get($url);
  if ($res->is_success) {
    return $res->content;
  } else {
    return;
  }
}

1;
