package LSSample::Nikkei;

use Any::Moose;

use Web::Scraper;

extends "LinkSeeker::Scraper";

my $nikkei_url = 'http://www.nikkei.co.jp';

sub nikkei_main_list {
  my ($self, $src) = @_;
  my $scraper = scraper {
    process 'ul.arrow-w-m-list li a', 'news_detail_url[]' => '@href';
    process 'h3.topNews-ttl2 a', 'top_news_detail_url[]' => '@href';
  };
  my $result = $scraper->scrape(\$src);
  my $top_news = delete $result->{top_news_detail_url};
  unshift @{$result->{news_detail_url}}, @$top_news;
  for my $url (@{$result->{news_detail_url}}) {
    if ($url !~ /^$nikkei_url/) {
      $url = $url =~m{^/} ?  $nikkei_url . $url : $nikkei_url .'/'. $url;
    }
  }
  return $result;
}

sub nikkei_news_detail {
  my ($self, $src) = @_;
  my $scraper = scraper {
    process 'h3.topNews-ttl3', 'title' => 'TEXT';
    process 'div.article-cap', 'content' => 'TEXT';
  };
  return $scraper->scrape(\$src);
}

1;
