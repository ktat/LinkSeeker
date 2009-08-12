package LinkSeeker::Base;

use Any::Moose;

has sites       => (is => 'rw',
                    isa => 'LinkSeeker::Sites');
has getter      => (is => 'rw',
                    isa => 'LinkSeeker::Getter');
has html_store  => (is => 'rw',
                    isa => 'LinkSeeker::HtmlStore');
has scraper     => (is => 'rw');

has scraper_method  => (is => 'rw');

has data_filter => (is => 'rw');

has data_filter_method => (is => 'rw');

has data_store  => (is => 'rw',
                     isa => 'LinkSeeker::DataStore');
has file        => (is => 'rw', default => '');

has prior_stored => (is => 'rw');

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

1;
