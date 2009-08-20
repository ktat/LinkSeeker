package LinkSeeker;

use Any::Moose;
use Config::Any;
use Time::HiRes ();
use Clone qw/clone/;

extends 'LinkSeeker::Base';

has tmp_path  => (is => 'rw');
has sleep     => (is => 'rw');
has http_proxy => (is => 'rw');
has proxy_user => (is => 'rw');
has proxy_password => (is => 'rw');

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
                prior_stored => 0,
                tmp_path     => $ENV{TMPDIR},
                sleep        => 1,
                variables    => '',
                http_proxy     => '',
                proxy_user     => '',
                proxy_password => '',
               );
  my $prior_stored = 0;
  my $mk_objects;
  if (my $file = delete $opt{file} || '') {
    my $files =  ref $file ? $file : [$file];
    my $cfgs = Config::Any->load_files({files => $files, use_ext => 1});

    my %config;
    foreach my $f_cfg (@$cfgs) {
      my ($f, $cfg) = %{$f_cfg || {}};
      @config{keys %$cfg} = values %{$cfg};
    }
    foreach my $k (keys %option) {
      if (defined $config{$k}) {
        $option{$k} = delete $config{$k};
      }
    }
    $config{cookie_store} ||= {
                         class => 'File',
                         path  => $option{tmp_path}
                        };
    $config{log} ||= {
                      class => 'Stderr',
                      level => 0,
                     };
    $mk_objects = [\%config, \%opt];
  }
  return { %opt, %option, mk_objects => $mk_objects };
}

sub run {
  my $self = shift;
  my (@target_site) = @_;
  my $sites = $self->sites;
  unless ($sites) {
    die "sites method returns undefine value.\ncheck your configuration:\n";
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
  unless (@url_list = $site->stored_url) {
    @url_list = $site->url;
    $site->store_url(\@url_list);
  }
  foreach my $url (@url_list) {
    my $src = $self->get_html_src($site, $url);
    next unless $src;
    my $data = $self->get_scraped_data($site, $url, $src);
    my $unique_name = $url->unique_name;
    if (defined $data and my $data_filter = $site->data_filter) {
      my $method = $site->data_filter_method || $site->name;
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
        # ignore when I remember why impmenet
        if (ref $target) {
          my @urls;
          for my $t (@$target) {
            if (ref $data eq 'HASH') {
               push @urls, LinkSeeker::Sites::Site::URL->new(ls => $self, url => $data->{$t});
            } else {
              foreach my $d (@$data) {
                push @urls, LinkSeeker::Sites::Site::URL->new(ls => $self, url => $d->{$t});
              }
            }
          }
          if (@urls) {
            $site->url(\@urls);
          }
        } elsif (ref $data eq 'HASH' and $data->{$target}) {
          my $target_url = $data->{$target};
          $self->debug("url is gotten from $target: " . join (", ", ref $target_url ? @$target_url : $target_url));
          if (ref $url) {
            my @urls;
            foreach my $url_string (ref $target_url ? @$target_url : $target_url) {
              push @urls, clone $url;
              $urls[-1]->url($url_string);
            }
            $site->url(\@urls);
          } else {
            $url = $target_url;
            $site->url($url);
          }
        }
        %result = (%result, %{$self->seek_links($site)});
      }
    }
  }
  $site->delete_stored_url;
  return \%result;
}

sub get_html_src {
  my ($self, $site, $url) = @_;
  Carp::croak("url is required for " . $site->name) unless $url;
  my ($getter, $html_store) = ($site->getter || $self->getter, $site->html_store || $self->html_store);
  my $unique_name = $url->unique_name;
  my $name = $site->name;
  my $prior_stored_html = $site->prior_stored_html || $self->prior_stored_html;
  if ($unique_name and $prior_stored_html and defined $html_store and $html_store->has_content($name, $unique_name)) {
    return $html_store->fetch_content($name, $unique_name);
  }
  my $src = $getter->get($url);
  if ($self->sleep) {
    Time::HiRes::usleep($self->sleep);
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

sub get_scraped_data {
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

sub cookie {
  my ($self, $url, @cookies) = @_;
  $self->{urls} ||= {};
  $self->{urls}->{$url} = 1;
  my $stored_cookie = $self->{cookie_store}->fetch_cookie($url);
  # if @cookies is passed, it is time to store cookie.
  # @cookies is cookie string
  if (@cookies) {
    if (my $cookies = LinkSeeker::Cookies->parse($url, @cookies)) {
      if ($stored_cookie) {
        $stored_cookie->merge_cookie($cookies);
      } else {
        $stored_cookie = $cookies;
      }
      $self->{cookie_store}->store_cookie($url, $stored_cookie);
    }
  }
  return $self->{cookie} = $stored_cookie;
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

    scraper : pref_list

scraper method name(class is YourPakcage::Scraper)
or class name and method name is as same as any_name in SITES SETTING.

If its value is started from Capital letter, it is regareded as class name.

If you don't set this in site section,
the one in parent layer is used.

=head3 data_filter

    data_filter : data_filter

data filter method name(class is YourPakcage::DataFilter)
or class name and method name is as same as any_name in SITES SETTING.

If its value is started from Capital letter, it is regareded as class name.


=head3 url

    url : http://example.com/

or

    url :
      base:  http://example.com/$variable

See URL SETTING.

=head2 URL SETTING

=head3 unique_name

 unique_name
   regexp : /([^/]+)$

to determine unique name of URL.
the matched is used for the name.

=head3 variables

 variables :
   variable_name : method_name


$variable_name can be used in url string.
method_name should be defined your root class inheriting LinkSeeker.

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

=head1 COPYRIGHT & LICENSE

Copyright 2009 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

