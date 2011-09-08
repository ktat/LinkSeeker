package LinkSeeker::Base;

use Any::Moose;
use String::CamelCase qw/camelize/;
use Class::Inspector;

has sites       => (is => 'rw',
                    isa => 'LinkSeeker::Sites');
has getter      => (is => 'rw',
                    isa => 'LinkSeeker::Getter');
has html_store  => (is => 'rw',
                    isa => 'LinkSeeker::HtmlStore');
has scraper     => (is => 'rw');

has message     => (is => 'rw');

has scraper_method  => (is => 'rw');

has data_filter => (is => 'rw');

has data_filter_method => (is => 'rw');

has data_store  => (is => 'rw',
                     isa => 'LinkSeeker::DataStore');
has file        => (is => 'rw', default => '');

has prior_stored => (is => 'rw');

has variables => (is => 'rw');

sub prior_stored_html {
  my ($self) = @_;
  my $stored = $self->prior_stored;
  return ref $stored ? (grep {$_ eq 'html'} @$stored) : $stored;
}

sub prior_stored_data {
  my ($self) = @_;
  my $stored = $self->prior_stored;
  return ref $stored ? (grep {$_ eq 'data'} @$stored) : $stored;
}

sub BUILD {
  my ($self, $opt) = @_;
  $self->_mk_object(@{delete $opt->{mk_objects} || []});
  return $self;
}

sub _mk_object {
  my ($self, $config, $opt) = @_;
  my $_class = 'LinkSeeker';
  foreach my $k (keys %$config) {
    my $class_config = $config->{$k};
    my $sub_class = ($class_config->{'class'}
                     ? $_class . '::' . camelize($k) . '::' . $class_config->{'class'}
                     : $_class . '::' . camelize($k));
    if (Class::Inspector->loaded($sub_class)) {
      $self->{$k} = $sub_class->new($self->isa('LinkSeeker') ? $self : $self->ls, $class_config);
    } else {
      my $ls_sub_class = 'LinkSeeker::' . camelize($k) . '::' . $class_config->{'class'};
      if (Class::Inspector->loaded($ls_sub_class)) {
        $class_config->{$k . '_method'} ||= 'process';
        $self->{$k} = $ls_sub_class->new($self->isa('LinkSeeker') ? $self : $self->ls, $class_config);
      } else {
        Carp::croak("$ls_sub_class is not loaded.");
      }
    }
  }
}

1;

=pod

=head1 NAME

LinkSeeker::SubClassBase - base class for LinkSeeker sub class

=head1 METHOD

=head2 prior_stored_html

=head2 prior_stored_data

=head1 COPYRIGHT & LICENSE

Copyright 2009 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
