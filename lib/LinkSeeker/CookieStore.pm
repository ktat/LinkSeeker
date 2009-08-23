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

=pod

=head1 NAME

LinkSeeker::CookieStore

=head1 SYNOPSYS

 cookie_store
   class: CookieStoreSubClass
   option: value

=head1 METHODS

=head2 fetch_cookie

=head2 store_cookie

=head1 COPYRIGHT & LICENSE

Copyright 2009 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
