package LinkSeeker::Sites::Site;

use Any::Moose;
use File::Slurp qw/slurp write_file/;
use Clone qw/clone/;
use Data::Dumper;

extends 'LinkSeeker::Base';

has ls      => (is => 'rw', isa => 'LinkSeeker');
has url     => (is => 'rw');
has nest    => (is => 'rw');
has from    => (is => 'rw');
has name    => (is => 'rw');
has parent_site  => (is => 'rw', isa => 'LinkSeeker::Sites::Site');
has parent_class => (is => 'rw');
has parent_object => (is => 'rw');
has unique_name  => (is => 'rw');

sub BUILDARGS {
  my ($class, $link_seeker, $opt) = @_;
  $opt->{ls} = $link_seeker;
  my $o_class = $opt->{parent_class} = (ref $link_seeker) || $link_seeker;
  $opt->{parent_object} = $link_seeker;
  die "not an object" unless ref $link_seeker;
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
        } elsif ($self->parent_object->can($v)) {
          $v = $self->parent_object->$v;
          $_max = 1; #scalar @$v;
          $var->{$k} = {var => $v};
        }
        $max = $_max if $max < $_max;
      }
      $num = $max if $max;
    }
    my @urls = ($base_url) x $num;
    my @var_keys = keys %$var;
    my %key_value;
    foreach my $key (@var_keys) {
      my $v = $var->{$key};
      if (ref $v eq 'ARRAY') {
        $key_value{$key} = [$v->[0] .. $v->[1]];
      } elsif (ref $v eq 'HASH') {
        $key_value{$key} = $v->{var};
      } else {
        $key_value{$key} = $v;
      }
    }
    foreach (my $i = 0; $i < @urls; $i++) {
      my $url = $urls[$i];
      foreach my $key (@var_keys) {
        if (ref $key_value{$key} eq 'ARRAY') {
          $urls[$i] =~ s{\$\{?$key\}?}{$key_value{$key}[$i]}g;
        } else {
          $urls[$i] =~ s{\$\{?$key\}?}{$key_value{$key}}g;
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

sub stored_url {
  return;
  my ($self) = @_;
  my $file_name = $self->ls->tmp_path . '/url_list.tmp';
  if (-e $file_name and (-M $file_name) * 86400 < 36000) {
    my $data = slurp($file_name);
    $data = eval "$data";
    return @$data;
  }
  return;
}

sub delete_stored_url {
  return;
  my ($self) = @_;
  my $file_name = $self->ls->tmp_path . '/' . $self->name . 'url_list.tmp';
  unlink $file_name;
}

sub store_url {
  return;
  my ($self, $urls) = @_;
  my $file_name = $self->ls->tmp_path . '/' . $self->name . 'url_list.tmp';
  local $Data::Dumper::Terse = 1;
  write_file($file_name, Dumper($urls));
}

1;
