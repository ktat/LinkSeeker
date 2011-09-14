package LinkSeeker;

use Any::Moose;
use Config::Any;
use Time::HiRes ();
use Clone qw/clone/;
use Tie::IxHash;

extends 'LinkSeeker::Base';

has tmp_path   => (is => 'rw');
has sleep      => (is => 'rw');
has test       => (is => 'rw');
has tap        => (is => 'rw', default => 0);
has http_proxy => (is => 'rw');
has proxy_user => (is => 'rw');
has proxy_password => (is => 'rw');

our %DEFAULT_CLASS_CONFIG =
  (
   required => {
                getter => {class => 'LWP'},
                log        => { class => 'Stderr'},
                message    => { class => 'Stderr'},
               },
   optional => {
                html_store => { class => 'File'},
                data_store => { class => 'Dumper'},
                log        => { level => 'fatal'},
               }
  );

our $VERSION;

BEGIN {
  $VERSION = 0.01;
  use Module::Pluggable require => 1, search_path => ['LinkSeeker'], inner => 0;
  __PACKAGE__->plugins;
  foreach my $method (qw/info warn error debug/) {
    no strict 'refs';
    *{__PACKAGE__ . '::' . $method} = sub {
      my ($self, $message) = @_;
      $self->{log}->$method($message)
        if defined $self->{log};
    }
  }
}

sub import {
  my ($class) = @_;
  if ($class ne __PACKAGE__) {
    $class->search_path('add' => $class);
    $class->plugins;
  }
}

sub BUILDARGS {
  my ($class, %opt) = @_;
  my %option = (
                prior_stored   => 0,
                tmp_path       => $ENV{TMPDIR},
                sleep          => 1,
                variables      => '',
                test           => {},
                http_proxy     => '',
                proxy_user     => '',
                proxy_password => '',
               );
  my $prior_stored = 0;
  my %config;
  if (my $file = delete $opt{file} || '') {
    my $files =  ref $file ? $file : [$file];
    my $cfgs = Config::Any->load_files({files => $files, use_ext => 1});

    $config{sites} = {};
    tie %{$config{sites}}, 'Tie::IxHash';
    foreach my $f_cfg (@$cfgs) {
      my ($f, $cfg) = %{$f_cfg || {}};
      %{$config{sites}} = (%{$config{sites}}, %{delete $cfg->{sites}}) if $cfg->{sites};
      @config{keys %$cfg} = values %{$cfg};
    }
  } else {
    %config = %opt;
  }
  foreach my $k (keys %option) {
    if (defined $config{$k}) {
      $option{$k} = delete $config{$k};
    }
  }

  foreach my $type (qw/required optional/) {
    while (my ($class, $class_config) = each %{$DEFAULT_CLASS_CONFIG{$type}}) {
      if (defined $config{$class}) {
        foreach my $key (keys %$class_config) {
          $config{$class}->{$key} ||= $class_config->{$key};
        }
      } elsif ($type eq 'required') {
        $config{$class} = clone $class_config;
      }
    }
  }
  return { %opt, %option, mk_objects => [\%config, \%opt] };
}

sub run {
  my $self = shift;
  my (@target_site) = @_;
  my $sites = $self->sites;
  unless ($sites) {
    die "sites method returns false.\ncheck your configuration:\n";
  }

  my %results;
  my %tmp;
  @tmp{@target_site} = ();
  while (my $site = $sites->next_site) {
    if (!@target_site or exists $tmp{$site->name}) {
      $self->info("start linkseeker for: ". $site->name);
      $site->ls($self);
      %results = (%results, %{$self->seek_links($site)});
    }
  }
  return \%results;
}

sub seek_links {
  my ($self, $site) = @_;
  my @url_list;
  my %result;
  @url_list = $site->url;
  # unless (@url_list = $site->stored_url) {
  #   @url_list = $site->url;
  #   $site->store_url(\@url_list);
  # }
  foreach my $url (@url_list) {
    my $src = $self->_get_html_src($site, $url);
    next unless $src;
    my $data = $self->_get_scraped_data($site, $url, $src);
    my $unique_name = $url->unique_name($data);
    if (defined $data and my $data_filter = $site->data_filter) {
      my $method = $site->data_filter_method;
      $self->info("data filter with: " . ref($data_filter) . '->' . $method);
      $data = $data_filter->$method($unique_name, $url->url, $data);
    }
    $result{$site->name}{$unique_name} = $data;
    if (my $nest = $site->nest) {
      my $child_sites = LinkSeeker::Sites->new($self, $nest);
      my $parent_site = $site;
      while (my $site = $child_sites->next_site) {
        $site->ls($self);
        $site->parent_site($parent_site);
        my ($url) = $site->url;
        my $target = $url->from || 'link_seeker_url';
        if (ref $target) {
          my $_data = $data;
          my @urls;
          foreach my $t (@{$target}[0 .. ($#{$target} - 1)]) {
            $_data = $_data->{$t};
          }
          my $last = $target->[$#{$target}];
          if (ref $_data eq 'HASH' and %$_data) {
            push @urls, LinkSeeker::Sites::Site::URL->new(ls => $self, url => $_data->{$last});
          } elsif (ref $_data eq 'ARRAY') {
            foreach my $d (@$_data) {
              push @urls, LinkSeeker::Sites::Site::URL->new(ls => $self, url => $d->{$last});
            }
          } else {
            $self->warn("no url is found. cannot get url from '$last' of data.");
          }
          if (@urls) {
            $site->_url(\@urls);
          }
        } elsif (ref $data eq 'HASH' and $data->{$target}) {
          my $target_url = $data->{$target} or $self->debug("target ($target) doesn't have any data.");
          if (ref $url) {
            my @target_urls = ref $target_url ? @$target_url : $target_url;
            # if (defined (my $match = $url->match)) {
            #   @target_urls = grep qr/$match/, @target_urls;
            # }
            $self->debug("url is gotten from $target: " . join(", ", @target_urls));
            my @urls;
            foreach my $url_string (@target_urls) {
              my $u = $url->clone;
              $u->url($url_string);
              push @urls, $u;
            }
            $site->_url(\@urls);
          } else {
            $self->debug("url is gotten from $target: $target_url");
            $url = $target_url;
            $site->_url($url);
          }
        }
        %result = (%result, %{$self->seek_links($site)});
      }
    }
  }
  # $site->delete_stored_url;
  return \%result;
}

sub _get_html_src {
  my ($self, $site, $url) = @_;
#  Carp::croak("url is required for " . $site->name) if not $url;
#  Carp::confess("url must be object for " . $site->name) if ref $url ne 'LinkSeeker::Sites::Site::URL';
  my ($getter, $html_store) = ($site->getter || $self->getter, $site->html_store || $self->html_store);
  my $unique_name = $url->unique_name;
  my $name = $site->name;
  my $prior_stored_html = $site->prior_stored_html || $self->prior_stored_html;
  if ($unique_name and $prior_stored_html and defined $html_store and $html_store->has_content($name, $unique_name)) {
    return $html_store->fetch_content($name, $unique_name);
  }
  my ($src, $res) = $getter->get($url);

  if (my %test = (%{$self->test}, %{$url->test})) {
    my $ok = 0;
    my $_url = $url->url;
    if ($test{res}) {
      my $st = $res->status_line;
      my @res = ref $test{res} ? @{$test{res}} : $test{res};
      foreach my $r (@res) {
        if ($st =~m{$r}) {
          $ok = 1;
          last;
        }
      }
      $st = "$_url : $st";
      $ok ? $self->message->ok($st) : $self->message->ng($st);
    }
    if ($test{src}) {
      my $msg = "$_url includes '$test{src}'";
      $src =~ m{$test{src}} ? $self->message->ok($msg) : $self->message->ng($msg);
    }
  }

  if ($self->sleep) {
    Time::HiRes::sleep($self->sleep);
  }
  # html_store
  if (defined $html_store) {
    if (defined $src) {
      $html_store->store_content($name, $unique_name, $src);
    } elsif ($html_store->has_content($name, $unique_name)) {
      $src = $html_store->fetch_content($name, $unique_name);
    }
  }
  return $src;
}

sub _get_scraped_data {
  my ($self, $site, $url, $src) = @_;
  my ($scraper, $data_store) = ($site->scraper, $site->data_store || $self->data_store);
  my $unique_name = $url->unique_name;
  my $name = $site->name;
  my $prior_stored_data = $site->prior_stored_data || $self->prior_stored_data;
  if ($prior_stored_data and defined $data_store and $data_store->has_data($name, $unique_name)) {
    return $data_store->fetch_data($name, $unique_name);
  }
  my $data;
  if (defined $scraper and my $scraper_method = $site->scraper_method) {
    $scraper->base_url($url->url);
    $data = $scraper->$scraper_method($src);
  }

  # data_store
  if (defined $data_store) {
    if (defined $data and $data) {
      $data_store->store_data($name, $unique_name, $data);
    } elsif ($data_store->has_data($name, $unique_name)) {
      $data = $data_store->fetch_data($name, $unique_name);
    }
    if (ref $data eq 'HASH') {
      $data->{_source_url} = $url->url;
    }
  }
  return $data;
}

sub ok {
  my ($self, $message) = @_;
  $self->message->ok($message);
}

sub total_count {
  my ($self, $count) = @_;
  $self->{total_count} ||= 0;
  $self->{total_count} += $count if $count;
  return $self->{ttoal_count};
}

sub ng {
  my ($self, $message) = @_;
  $self->message->ng($message);
}

1;

=pod

=head1 NAME

LinkSeeker - scraping framework to seek link deeply

=head1 SYNOPSIS

LSSample.pm

 package LSSample;
 
 use Any::Moose;
 extends 'LinkSeeker';
 
 1;

LSSample/Scraper.pm

 package LSSample::Scraper;
 
 use Any::Moose;
 use Web::Scraper;
 
 extends 'LinkSeeker::Scraper';
 
 sub pref_list {
   # some code to scrape page
 }
 
 sub shop_list {
   # some code to scrape page
 }
 
 sub shop_detail {
   # some code to scrape page
 }

site.yml

 ---
 # if you have stored data/html, skip to get html source
 prior_stored : 1
 # or you can write as the following
 # prior_stored : ['html', 'data']
 getter :
   # use LinkSeeker::Getter::LWP as getter
   class: LWP
 html_store :
   # use LinkSeeker::HtmlStore::File as html_store
   class:  File
   path : data/src
 data_store :
   # use LinkSeeker::DataStore::Dumper as data_store
   class: Dumper
   path : data/scraped
 
 sites:
  pref_list:
    url : http://example.jp/pref
    # use LSSample::Scraper::pref_list method as scraper
    scraper : pref_list
    nest :
      # write here site setting without url.
      # url is scraperd by parent site data
      shop_list:
        from: pref_urls
        # use LSSample::Scraper::shop_list method as scraper
        scraper : shop_list
        unique_name :
          regexp: /([^/]+)$
        nest:
          # write here site setting without url.
          # url is scraperd by parent site data
          shop_detail:
            from: shop_urls
            uniuqe_name :
              regexp: /([^/]+)$
            # use LSSample::Scraper::shop_detail method as scraper
            scraper: shop_detail

  another_site:
    ...

lssample.pl

 #!/usr/bin/perl
 use LSSample;
 
 LSSample->new(file =>['site.yml'])->run;
 
 # only selected site
 LSSample->new(file =>['site.yml'])->run('pref_list', ...);

You can find source html under the following directory

 data/src/pref_list/
 data/src/shop_list/
 data/src/shop_detail/

You can find scraped data under the following directory

 data/scraped/pref_list/
 data/scraped/shop_list/
 data/scraped/shop_detail/

=head1 DESCRIPTION

When you scrape web pages, don't you do the following steps?

1. get web page
2. (store web page to file)
3. scrape web page
4. (store scraped data to file)
5. insert scraped data to somewhere(file/db)

Some of the steps are common work.

=head1 METHODS

=head2 new

 my $ls = LinkSeeker->new(file => ['site.yml']);

=head2 run

 $ls->run;

Do scraping.

=head2 seek_links

used in run method.
recursively seek links.

=head2 fatal

 $ls->fatal('fatal message');

=head2 error

 $ls->error('error message');

=head2 warn

 $ls->warn('warn message');

=head2 info

 $ls->info('info message');

=head2 debug

 $ls->debug('debug message');

=head1 YAML FILE

=head2 FIRST LAYER SETTING

=head3 prior_stored

 # if you have stored data/html, skip to get html source
 prior_stored : 1
 # or you can write as the following
 # prior_stored : ['html', 'data']

=head3 getter

 getter :
   # use LinkSeeker::Getter::LWP as getter
   class: LWP

=head3 html_store

 html_store :
   # use LinkSeeker::HtmlStore::File as html_store
   class:  File
   path : data/src

=head3 data_store

 data_store :
   # use LinkSeeker::DataStore::Dumper as data_store
   class: Dumper
   path : data/scraped

=head3 sites

 sites:
  pref_list: # (any_name)
    # site setting

as key, you can use any name(^\w+$).
as value, see SITE SETTING

=head2 SITE SETTING

=head3 html_store

as same as first layer html_store

If you don't set this in site section,
the one in first layer is used.

=head3 data_store

as same as first layer data_store.

If you don't set this in site section,
the one in first layer is used.

=head3 scraper

This takes 3 kind of value.

    scraper: method_name
    # started from Capital letter, it is regareded as class name.
    scraper: ClassName
    scraper: 1

If you write method_name, it should be defined in YourClass::Scraper.
If you write ClassName, method name is site name in ClassName class.
If you write 1, medhod name is site name and class name is YourCalss::Scraper.

If you don't set this in site section, the one in parent layer is used.

=head3 data_filter

    data_filter: method_name
    # started from Capital letter, it is regareded as class name.
    data_filter: ClassName
    data_filter: 1

If you write method_name, it should be defined in YourClass::DataFilter.
If you write ClassName, method name is site name in ClassName class.
If you write 1, medhod name is site name and class name is YourCalss::DataFilter.

If you don't set this in site section, the one in root layer is used.

=head3 url

    url : http://example.com/

or

    url :
      base:  http://example.com/$variable
      ...

See URL SETTING.

=head2 URL SETTING

=head3 unique_name

 unique_name
   regexp : /([^/]+)$

to determine unique name of URL.
the matched is used for the name.

If you want to use variable for unique_name.
You can write as the following.

 unique_name:
  variable: $unique_name

=head3 variables

 variables :
   variable_name : method_name_or_value

$variable_name can be used in url string.
If method_name is defined your root class inheriting LinkSeeker, it is called.
If not defined, it is just replaced from $variables_name to "method_name_or_value".

for example, In site setting:

 one_site:
   url :
     base : http://www.example.com/$category
     variables :
       category : target_category

in YourClass.pm

 sub target_category {
   return ['main', 'economy', 'sports'];
 }

LinkSeeker scrape the following urls.

 http://www.example.com/main
 http://www.example.com/economy
 http://www.example.com/sports

This variables setting can be written in first layer.
But, in first layer, don't return multiple value.

=head1 SEE ALSO

see LinkSeeker::Manual::Cookbook for detail.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

