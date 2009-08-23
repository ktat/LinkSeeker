package LinkSeeker::Sites::Site;

use Any::Moose;
use File::Slurp qw/slurp write_file/;
use String::CamelCase qw/camelize/;
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
  my ($class, $linkseeker, $opt) = @_;
  $opt->{ls} = $linkseeker;
  my $o_class = $opt->{parent_class} = ref $linkseeker or die "LinkSeeker object is not passed";
  $opt->{parent_object} = $linkseeker;

  my %mk_objects;
  foreach my $class (qw/data_store html_store getter/) {
    if (exists $opt->{$class}) {
      $mk_objects{$class} = delete $opt->{$class};
    }
  }
  foreach my $kind (qw/scraper data_filter/) {
    if (my $class_or_method = $opt->{$kind}) {
      my ($class, $method) = $class_or_method =~/^[A-Z]/
                              ? ($class_or_method, $opt->{name})
                              : (camelize($kind), ($class_or_method =~/^1$/ ? $opt->{name} : $class_or_method));
      $class = $o_class . '::' . $class;
      $opt->{$kind} = $class->new($linkseeker, {});
      $opt->{$kind . '_method'} ||= $method;
    }
  }
  return {%$opt, ls => $linkseeker, mk_objects => [\%mk_objects]};
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
    $self->ls->info($self->name . " doesn't  have scraper setting and parent_site neither.");
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
    my @urls      = ($base_url) x $num;
    my @post_data = ($base_post_data) x $num;
    my @var_keys  = keys %$var;
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
  } elsif (ref $url eq 'ARRAY' and ref $url->[0] eq 'LinkSeeker::Sites::Site::URL') {
    return @$url;
  } else {
    return map {LinkSeeker::Sites::Site::URL->new(ls => $self->ls, url => $_, %$config)} (ref $url ? @{$url} : $url);
  }
};

# sub stored_url {
#   return;
#   my ($self) = @_;
#   my $file_name = $self->ls->tmp_path . '/url_list.tmp';
#   if (-e $file_name and (-M $file_name) * 86400 < 36000) {
#     my $data = slurp($file_name);
#     $data = eval "$data";
#     return @$data;
#   }
#   return;
# }
# 
# sub delete_stored_url {
#   return;
#   my ($self) = @_;
#   my $file_name = $self->ls->tmp_path . '/' . $self->name . 'url_list.tmp';
#   unlink $file_name;
# }
# 
# sub store_url {
#   return;
#   my ($self, $urls) = @_;
#   my $file_name = $self->ls->tmp_path . '/' . $self->name . 'url_list.tmp';
#   local $Data::Dumper::Terse = 1;
#   write_file($file_name, Dumper($urls));
# }

1;

=pod

=head1 NAME

LinkSeeker::Sites::Site

=head1 METHODS

=head2 data_filter

 $site->data_filter;

=head2 scraper

 $site->scraper;

=head2 url

 $site->url;

=head1 COPYRIGHT & LICENSE

Copyright 2009 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
