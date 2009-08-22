package LSSample;

use Any::Moose;
use lib qw(../lib);
use IO::Prompt;
use CGI;

has stash => (is => 'rw', default => sub {{}});

extends 'LinkSeeker';

sub nikkei_news_category {
  # [ qw/main keizai sangyo kaigai seiji shakai/ ];
  [ qw/main keizai/];# sangyo kaigai seiji shakai/ ];
}

sub input_your_email {
  my ($self) = @_;

  return $self->stash->{email} if $self->stash->{email};

  prompt ("input your email: ");
  chomp(my $var = $_);
  return $self->stash->{email} = CGI::escape($var);
}

sub input_your_password {
  my ($self) = @_;

  return $self->stash->{password} if $self->stash->{password};

  prompt("input your password: ", -e => '*');
  chomp(my $var = $_);
  return $self->stash->{password} = CGI:escape($var);
}

1;
