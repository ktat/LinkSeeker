package LinkSeeker::Getter::LWP;

use Any::Moose;
use LWP::UserAgent;

extends 'LinkSeeker::Getter';

has agent => (is => 'rw', default => 'LinkSeeker version ' . LinkSeeker->VERSION);
has header => (is => 'rw', isa => 'HashRef');
has post_data => (is => 'rw', default => '');
has method => (is => 'rw', default => 'get');

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
  my ($url, $post_data) = ($url_obj->url, $url_obj->post_data || $self->post_data);
  my $method = $post_data ? 'post' : $self->method;
  my $ua = LWP::UserAgent->new;
  my $header = $url_obj->header || $self->header;

  $ua->env_proxy  if $self->ls->{http_proxy};
  $ua->max_redirect(0);
  $ua->agent($url_obj->agent || $self->agent || 'LinkSeeker - ' . LinkSeeker->VERSION);

  my $res = $self->_get($ua, $method, $url, $post_data, $header);

 GET: {
    if ($res->is_success) {
      my @cookies = $res->header('Set-Cookie');
      $self->ls->info("receive cookie: " . $_) for @cookies;
      $self->ls->cookie($url, @cookies);
      my $content =  $res->content;
      return $content;
    } elsif ($res->is_redirect) {
      my $location = $res->headers->header('Location');
      $self->ls->info("redirect to: " . $location);
      $res = $self->_get($ua, 'get', $location, '', $header);
      redo GET;
    } else {
      return;
    }
  }
}

sub _get {
  my ($self, $ua, $method, $url, $post_data, $h) = @_;
  my $res;
  my $header = $self->_create_header($url, $h);
  $ua->default_header(%$header) if %$header;

  $self->ls->info("$method $url");
  if (lc($method) eq 'get') {
    $res = $ua->get($url);
  } else {
    $self->ls->debug("send post data: " . $post_data);
    $res = $ua->post($url, Content => $post_data);
  }
  return $res;
}

sub _create_header {
  my ($self, $url, $h) = @_;
  my $cookie = $self->ls->cookie($url);
  if (defined $cookie and my $c = $cookie->as_request_string($url)) {
    $self->ls->info("pass cookie: " . $c);
    $h->{'Cookie'} = $c;
  }
  return $h || {};
}

1;
