package News::Nikkei;

use Any::Moose;

use Web::Scraper;

my $base_url = 'http://www.nikkei.co.jp';

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
    if ($url !~ /^$base_url/) {
      $url = $url =~m{^/} ?  $base_url . $url : $base_url .'/'. $url;
    }
  }
  return $result;
}

sub nikkei_news_detail {
  my ($self, $src) = @_;
  my $scraper = scraper {
    process 'h3.topNews-ttl3';
    process 'h3.topNews-ttl3', 'title' => 'TEXT';
    process 'div.article-cap', 'content' => 'TEXT';
  };
  my $result = $scraper->scrape(\$src);
  return $result;
}

1;
