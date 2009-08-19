package LinkSeeker::Sites::Site;

use Any::Moose;
use File::Slurp qw/slurp write_file/;
use Clone qw/clone/;
use LinkSeeker::Sites::Site::URL;
use Data::Dumper;

extends 'LinkSeeker::Base';

has ls      => (is => 'rw', isa => 'LinkSeeker');
has url     => (is => 'rw');
has nest    => (is => 'rw');
has name    => (is => 'rw');
has parent_site  => (is => 'rw', isa => 'LinkSeeker::Sites::Site');
has parent_class => (is => 'rw');
has parent_object => (is => 'rw');

sub BUILDARGS {
  my ($class, $link_seeker, $opt) = @_;
  $opt->{ls} = $link_seeker;
  my $o_class = $opt->{parent_class} = (ref $link_seeker) || $link_seeker;
  $opt->{parent_object} = $link_seeker;
  die "not an object" unless ref $link_seeker;

  my %mk_objects;
  foreach my $class (qw/data_store html_store getter/) {
    if (exists $opt->{$class}) {
      $mk_objects{$class} = delete $opt->{$class};
    }
  }

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
    $opt->{scraper} = $class->new($link_seeker, {});
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
    $opt->{data_filter} = $class->new($link_seeker, {});
    $opt->{data_filter_method} ||= $method;
  }
  return {%$opt, mk_objects => [\%mk_objects]};
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
  my $parent_site = $self->parent_site;
  if (!$scraper and !$parent_site) {
    $self->ls->warn($self->name . " doesn't  have scraper setting and parent_site neither.");
    return;
  }
  until ($scraper) {
    if ($scraper = $parent_site->scraper) {
      $self->scraper_method($self->name);
    } else {
      $parent_site = $parent_site->parent_site or last;
    }
  }
  return $scraper;
};

override url => sub {
  my ($self) = @_;
  my $url = super();
  my $config = {};
  if (ref $url eq 'HASH' or ref $url eq 'LinkSeeker::Sites::Site::URL') {
    $config = clone $url;
    $url = '';
    my $base_url = delete $config->{base};
    my $base_post_data = delete $config->{post_data} || '';
    my $var = clone(delete $config->{variables} || $self->ls->variables) || {};
    my $num = 1;
    if (defined $var) {
      my $max = 0;
      foreach my $k (keys %$var) {
        my $v = $var->{$k};
        my $_max;
        if (ref $v) {
          # hoge: [1,2,3 ...]
          $_max = scalar @{[($v->[0] .. $v->[1])]};
        } elsif ($self->parent_object->can($v)) {
          # hoge: method_name
          $v = $self->parent_object->$v || '';
          $_max = ref $v eq 'ARRAY' ? scalar @$v : 1;
          $var->{$k} = {var => $v};
        } else {
          # hoge: variable -> $hoge = 'variable'
          $_max = 1;
        }
        $max = $_max if $max < $_max;
      }
      $num = $max if $max;
    }
    my @urls = ($base_url) x $num;
    my @post_data = ($base_post_data) x $num;
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
      my $post_data = $post_data[$i];
      foreach my $key (@var_keys) {
        if (ref $key_value{$key} eq 'ARRAY') {
          $self->ls->debug("assign $key: $key_value{$key}[$i]");
          $urls[$i] =~ s{\$\{?$key\}?}{$key_value{$key}[$i]}g      if $urls[$i];
          $post_data[$i] =~ s{\$\{?$key\}?}{$key_value{$key}[$i]}g if $base_post_data;
        } else {
          $self->ls->debug("assign $key: $key_value{$key}");
          $urls[$i] =~ s{\$\{?$key\}?}{$key_value{$key}}g      if $urls[$i];
          $post_data[$i] =~ s{\$\{?$key\}?}{$key_value{$key}}g if $base_post_data;
        }
      }
    }
    return @post_data
      ? (map {LinkSeeker::Sites::Site::URL->new(ls => $self->ls, url => $urls[$_], post_data => $post_data[$_], %$config)} 0 .. $#urls)
      : (map {LinkSeeker::Sites::Site::URL->new(ls => $self->ls, url => $_, %$config)} @urls);
  } elsif (ref $url->[0] eq 'LinkSeeker::Sites::Site::URL') {
    return @$url;
  } else {
    return map {LinkSeeker::Sites::Site::URL->new(ls => $self->ls, url => $_, %$config)} (ref $url ? @{$url} : $url);
  }
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
