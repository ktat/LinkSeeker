package LinkSeeker::Cookies::Cookie;

use Any::Moose;
use HTTP::Date qw/str2time/;
use CGI::Lite::Request::Cookie;
use DateTime;

has name    => (is => 'rw');
has value   => (is => 'rw');
has domain  => (is => 'rw');
has path    => (is => 'rw');
has expires => (is => 'rw');

sub parse {
  my ($self, $url, $cookie) = @_;
  my %cookie = CGI::Lite::Request::Cookie->parse($cookie);
  my ($default_domain) = $url =~m{^https?://([^/]+)};
  my %self;
  foreach my $k (qw/path domain expires/) {
    if (exists $cookie{$k}) {
      $self{$k} = $cookie{$k}->value;
      delete $cookie{$k};
    }
  }
  $self{domain} ||= $default_domain;
  if (%cookie) {
    my ($name, $value) = (each %cookie);
    $self{name} = $name;
    $self{value} = $value->value;
  }
  $self->new(%self);
}

sub is_apply {
  my ($self, $url, $strict) = @_;
  $strict ||= 0;

  my ($target_domain) = ref $self->domain ? @{$self->domain} : $self->domain;
  if ($url =~s{^http://([^/]+)}{}) {
    my $domain = $1;
    return if $domain !~/$target_domain$/;
  } else {
    return;
  }

  my ($target_path) = ref $self->path ? @{$self->path} : $self->path;
  return unless $url =~/^$target_path/;
  my ($expires) = ref $self->expires ?  @{$self->expires} : $self->expires;
  if (defined $expires) {
    my $now = DateTime->now;
    $expires = DateTime->from_epoch(epoch => str2time($expires));

    return if $now > $expires;
  } elsif ($strict) {
    return 0;
  }

  return 1;
}

sub is_apply_strict {
  my ($self, $url) = @_;
  $self->is_apply($url, 1);
}

sub as_request_string {
  my ($self) = @_;
  my $c = CGI::Lite::Request::Cookie->new;
  $c->name($self->name);
  $c->value($self->value);
  return $c->as_string;
}

sub as_response_string {
  my ($self) = @_;
  my $c = CGI::Lite::Request::Cookie->new;
  $c->name($self->name);
  $c->value($self->value);
  foreach my $m (qw/domain path expires/) {
    $c->$m(ref $self->$m ? @{$self->$m} : $self->$m);
  }
  return $c->as_string;
}

1;
