package LinkSeeker::Getter::LWP;

use Any::Moose;
use LWP::UserAgent;

extends 'LinkSeeker::Getter';

has agent => (is => 'rw', default => 'LinkSeeker version ' . LinkSeeker->VERSION);
has header => (is => 'rw', isa => 'HashRef');
has post_data => (is => 'rw', default => '');

sub process {
  my $self = shift;
  my ($site_info, $data) = @_;
  print Data::Dumper::Dumper($site_info);
}

sub BUILD {
  my ($self) = @_;
  if (my $proxy = $self->ls->http_proxy) {
    if (my $user = $self->ls->proxy_user) {
      my $password = $self->ls->proxy_password || '';
      $proxy =~s{^(https?://)}{$1${user}:${password}\@};
    }
    $ENV{http_proxy} = $proxy;
  }
  return $self;
}

sub get {
  my ($self, $url_obj) = @_;
  my ($url, $post_data) = ($url_obj->url, $url_obj->post_data);
  my $method = $post_data ? 'POST' : 'GET';
  $self->ls->info("$method $url");

  my $cookie = $self->ls->cookie($url);

  my $h = $url_obj->header || $self->header;
  my $ua = LWP::UserAgent->new;
  if ($self->ls->{http_proxy}) {
    $ua->env_proxy;
  }
  $ua->agent($url_obj->agent || $self->agent || 'LinkSeeker - ' . LinkSeeker->VERSION);

  if (defined $cookie and my $c = $cookie->as_request_string($url)) {
    $self->ls->info("pass cookie: " . $c);
    $h->{'Cookie'} = $c;
  }
  if ($h) {
    $ua->default_header(%$h);
  }
  my $res;
  unless ($post_data || $self->post_data) {
    $res = $ua->get($url);
  } else {
    $self->ls->debug("send post data: " . $post_data || $self->post_data);
    $res = $ua->post($url, Content => $post_data || $self->post_data);
  }
  if ($res->is_success) {
    my @cookies = $res->header('Set-Cookie');
    $self->ls->info("receive cookie: " . $_) for @cookies;
    $self->ls->cookie($url, @cookies);
    return $res->content;
  } else {
    return;
  }
}

1;
