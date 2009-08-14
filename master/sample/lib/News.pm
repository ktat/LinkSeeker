package News;

use Any::Moose;
use lib qw(../lib);

extends 'LinkSeeker';

sub nikkei_news_category {
  # [ qw/main keizai sangyo kaigai seiji shakai/ ];
  [ qw/main keizai/];# sangyo kaigai seiji shakai/ ];
}

1;

