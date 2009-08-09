package LinkSeeker;

use Any::Moose;
use String::CamelCase qw/camelize/;
use Config::Any;
use HTML::TreeBuilder::LibXML;

extends 'LinkSeeker::Base';

our $VERSION;

BEGIN {
  $VERSION = 0.01;
  use Module::Pluggable require => 1, search_path => ['LinkSeeker'], inner => 0;
  __PACKAGE__->plugins;
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
  my $prior_stored = 0;
  if (my $file = delete $opt{file} || '') {
    my $files =  ref $file ? $file : [$file];
    my $cfgs = Config::Any->load_files({files => $files, use_ext => 1});
    my %config;
    foreach my $f_cfg (@$cfgs) {
      my ($f, $cfg) = %{$f_cfg || {}};
      @config{keys %$cfg} = values %{$cfg};
    }
    $prior_stored = delete $config{prior_stored};
    $class->_mk_object(\%config, \%opt);
  }
  return { %opt, prior_stored => $prior_stored };
}

sub _mk_object {
  my ($class, $config, $opt) = @_;
  foreach my $k (keys %$config) {
    my $class_config = $config->{$k};
    my $sub_class = ($class_config->{'class'}
                     ? __PACKAGE__ . '::' . camelize($k) . '::' . $class_config->{'class'}
                     : __PACKAGE__ . '::' . camelize($k));
    $opt->{$k} = $sub_class->new($class, $class_config);
  }
}

sub run {
  my $self = shift;
  my $sites = $self->sites;
  while (my $site = $sites->next_site) {
    $self->seek_links($site);
  }
}

sub seek_links {
  my ($self, $site) = @_;

  foreach my $url ($site->url) {
    my $data = $self->get_scraped_data($site, $url, $self->get_html_src($site, $url)) || '';
    next unless $data;

    # data_filter
    #  insert data to DB? do anything as you like
    if (my $data_filter = $site->data_filter) {
      my $unique_name = $site->unique_name($url);
      my $method = $site->data_filter_method || $site->name;
      $data_filter->$method($unique_name, $url, $data);
    }
    if (my $nest = $site->nest) {
      my $child_sites = LinkSeeker::Sites->new(ref $self, $nest);
      my $parent_site = $site;
      while (my $site = $child_sites->next_site) {
        $site->parent_site($parent_site);
        my $target = $site->from || 'link_seeker_url';
        if (ref $target) {
          my @urls;
          for my $t (@$target) {
            if (ref $data eq 'HASH') {
              $data = $data->{$t};
            } else {
              foreach my $d (@$data) {
                push @urls, $d->{$t};
              }
            }
          }
          $data = \@urls if @urls;
        } else {
          $data = $data->{$target};
        }
        if (defined $data) {
          $site->url($data);
          $self->seek_links($site);
        }
      }
    }
  }
}

sub get_html_src {
  my ($self, $site, $url) = @_;
  Carp::croak("url is required for " . $site->name) unless $url;
  my ($getter, $html_store) = ($self->getter, $site->html_store || $self->html_store);
  my $unique_name = $site->unique_name($url);
  my $name = $site->name;
  my $prior_stored_html = $site->prior_stored_html || $self->prior_stored_html;
  if ($unique_name and $prior_stored_html and defined $html_store and $html_store->has_content($name, $unique_name)) {
    return $html_store->fetch_content($name, $unique_name);
  }
  my $src = $getter->get($url);
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
  my $unique_name = $site->unique_name($url);
  my $name = $site->name;
  my $prior_stored_data = $site->prior_stored_data || $self->prior_stored_data;
  if ($prior_stored_data and defined $data_store and $data_store->has_data($name, $unique_name)) {
    return $data_store->fetch_data($name, $unique_name);
  }
  my $scraper_method = $site->scraper_method;
  my $data = $scraper->$scraper_method($src);
  # data_store
  if (defined $data and $data) {
    $data_store->store_data($name, $unique_name, $data);
  } elsif ($data_store->has_data($name, $unique_name)) {
    $data = $data_store->fetch_data($name, $unique_name);
  }
  if (ref $data eq 'HASH') {
    $data->{_source_url} = $url;
  }
  return $data;
}

1;

=pod

=head1 NAME

LinkSeeker - seeks link in pages deeply with scraping.

=head1 SYNOPSIS

LSSample.pm

 package LSSample;
 
 use LSSample::Scraper;
 use Any::Moose;
 extends 'LinkSeeker';
 
 1;

LSSample/Scraper.pm

 package LSSample::Scraper;
 
 use Any::Moose;
 use Web::Scraper;
 
 extends 'LinkSeeker::Scraper';
 
 sub page_list {
   # some code to scrape page
 }
 
 sub page_detail {
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
          url: /([^/]+)$
        nest:
          # write here site setting without url.
          # url is scraperd by parent site data
          shop_detail:
            from: shop_urls
            uniuqe_name :
              url: /([^/]+)$
            # use LSSample::Scraper::shop_detail method as scraper
            scraper: shop_detail

lssample.pl

 #!/usr/bin/perl
 use LSSample;
 
 LSSample->new(file =>['site.yml'])->run;

You can find source html under ...

 data/src/pref_list
 data/src/shop_list
 data/src/shop_detail

You can find scraped data under ...

 data/scraped/pref_list
 data/scraped/shop_list
 data/scraped/shop_detail


=head1 DESCRIPTION

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

=head3 SITE SETTING

=head3 html_store

as same as first layer html_store

=head3 data_store

as same as first layer data_store

=head3 scraper

    scraper : pref_list

scraper method name(class is YourPakcage::Scraper)
or class name and method name is as same as any_name in SITES SETTING.

If its value is started from Capital letter, it is regareded as class name.

=head3 data_filter

    data_filter : data_filter

data filter method name(class is YourPakcage::DataFilter)
or class name and method name is as same as any_name in SITES SETTING.

If its value is started from Capital letter, it is regareded as class name.

=cut

