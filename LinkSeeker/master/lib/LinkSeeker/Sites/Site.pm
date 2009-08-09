package LinkSeeker::Sites::Site;

use Any::Moose;
use Clone qw/clone/;

extends 'LinkSeeker::Base';

has url     => (is => 'rw');
has nest    => (is => 'rw');
has from    => (is => 'rw');
has name    => (is => 'rw');
has parent_site  => (is => 'rw', isa => 'LinkSeeker::Sites::Site');
has parent_class => (is => 'rw');
has unique_name  => (is => 'rw');

sub BUILDARGS {
  my ($class, $o_class, $opt) = @_;
  $opt->{parent_class} = $o_class;
  LinkSeeker->_mk_object({map {exists $opt->{$_} ? ($_ => $opt->{$_}) : ()}
                          qw/data_store html_store/}, $opt);
  if (my $class_or_method = $opt->{scraper}) {
    my ($class, $method);
    if ($class_or_method =~/^[A-Z]/) {
      # it is class and method name is site_name
      $class  = $o_class . '::' . $class_or_method;
      $method = $opt->{name};
    } else {
      $class  = $o_class . '::' . 'Scraper';
      $method = $class_or_method;
    }
    $opt->{scraper} = $class->new;
    $opt->{scraper_method} ||= $method;
  }
  if (my $class_or_method = $opt->{data_filter}) {
    my ($class, $method);
    if ($class_or_method =~/^[A-Z]/) {
      # it is class and method name is site_name
      $class  = $o_class . '::' . $class_or_method;
      $method = $opt->{name};
    } else {
      $class  = $o_class . '::' . 'DataFilter';
      $method = $class_or_method == 1 ? $opt->{name} : $class_or_method;
    }
    $opt->{data_filter} = $class->new;
    $opt->{data_filter_method} ||= $method;
  }
  return {%$opt}
}

override data_filter => sub {
  my ($self) = @_;
  my $data_filter = super();
  if (my $ps = $self->parent_site) {
    until ($data_filter) {
      if ($data_filter = $ps->data_filter) {
        $self->data_filter_method($self->name);
      } else {
        $ps = $ps->parent_site or last;
      }
    }
  }
  return $data_filter;
};

override scraper => sub {
  my ($self) = @_;
  my $scraper = super();
  my $ps = $self->parent_site;
  until ($scraper) {
    if ($scraper = $ps->scraper) {
      $self->scraper_method($self->name);
    } else {
      $ps = $ps->parent_site or last;
    }
  }
  return $scraper;
};

override url => sub {
  my ($self) = @_;
  my $url = super();
  if (ref $url eq 'HASH') {
    my $config = $url;
    $url = '';
    my $base_url = $config->{base};
    my $var = clone $config->{variables};
    my $num = 1;
    if (defined $var) {
      my $max = 0;
      foreach my $k (keys %$var) {
        my $v = $var->{$k};
        my $_max;
        if (ref $v) {
          $_max = scalar @{[($v->[0] .. $v->[1])]};
        } elsif ($self->parent_class->can($v)) {
          $v = $self->parent_class->$v;
          $_max = scalar @$v;
          $var->{$k} = {var => $v};
        }
        $max = $_max if $max < $_max;
      }
      $num = $max if $max;
    }
    my @urls = ($base_url) x $num;
    foreach (my $i = 0; $i < @urls; $i++) {
      my $url = $urls[$i];
      foreach my $key (keys %$var) {
        my $v = $var->{$key};
        if (ref $v eq 'ARRAY') {
          my @vars = ($v->[0] .. $v->[1]);
          $urls[$i] =~ s{\$\{?$key\}?}{$vars[$i]}g;
        } elsif (ref $v eq 'HASH') {
          my @vars = @{$v->{var}};
          $urls[$i] =~ s{\$\{?$key\}?}{$vars[$i]}g;
        } else {
          $urls[$i] =~ s{\$\{?$key\}?}{$v}g;
        }
      }
    }
    return @urls;
  } else {
    return ref $url ? @{$url} : $url;
  }
};

override unique_name => sub {
  my ($self, $url) = @_;
  my $unique = $self->{unique_name};
  if (my $re = $unique->{url}) {
    if ($url =~ m{$re}) {
      return $1;
    }
  }
  return $url;
};

1;
