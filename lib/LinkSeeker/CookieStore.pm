package LinkSeeker::CookieStore;

use Any::Moose;
use CGI::Lite::Request::Cookie;

extends "LinkSeeker::SubClassBase";

sub DESTROY {
  my ($self) = @_;
  if (defined $self->ls) { 
    foreach my $url (keys %{$self->ls->{urls}}) {
      if (my $stored_cookie = $self->fetch_cookie($url)) {
	$stored_cookie->remove_expires($url);
	$self->store_cookie($url, $stored_cookie);
      }
    }
  }
}

1;
