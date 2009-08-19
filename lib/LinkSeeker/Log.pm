package LinkSeeker::Log;

use Any::Moose;
extends "LinkSeeker::SubClassBase";

has level => (is => 'rw');

my %LOG_LEVEL = (
                 FATAL => 0,
                 ERROR => 1,
                 WARN  => 2,
                 INFO  => 3,
                 DEBUG => 4,
);

foreach my $level (keys %LOG_LEVEL) {
  no strict "refs";
  my $lc_level = lc $level;
  *{__PACKAGE__ . '::' . $lc_level} = sub {
    my ($self, $message) = @_;
    if ($self->level >= $LOG_LEVEL{$level}) {
      $message = "[$lc_level] " . $message;
      if ($self->can("do_log")) {
        return $self->do_log($message);
      } else {
        return $message;
      }
    }
  };
}

sub BUILDARGS {
  my ($class, $ls, $opt) = @_;
  $opt->{level} = $LOG_LEVEL{uc($opt->{level})} || 0;
  { ls => $ls, %$opt };
}

1;
