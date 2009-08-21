package LSSample;

use Any::Moose;
use lib qw(../lib);

has stash => (is => 'rw', default => sub {{}});

extends 'LinkSeeker';

sub nikkei_news_category {
  # [ qw/main keizai sangyo kaigai seiji shakai/ ];
  [ qw/main keizai/];# sangyo kaigai seiji shakai/ ];
}

sub input_your_email {
  my ($self) = @_;

  return $self->stash->{email} if $self->stash->{email};

  print "input your email: ";
  my $var = <>;
  $| = 1;
  chomp $var;
  return $self->stash->{email} = $var;
}

sub input_your_password {
  my ($self) = @_;

  return $self->stash->{password} if $self->stash->{password};

  print "!!! password is displied as is\n";
  print "input your password: ";
  $| = 1;
  my $var = <>;
  chomp $var;
  return $self->stash->{password} = $var;
}

1;

