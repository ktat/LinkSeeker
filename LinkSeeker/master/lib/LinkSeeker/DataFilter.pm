package LinkSeeker::DataFilter;

use Any::Moose;

# has store  => (is => 'rw', default => '');
# has filter => (is => 'rw', default => 'filter');
# has name   => (is => 'rw');
# 
# sub BUILDARGS {
#   my ($class, $o_class, $opt) = @_;
#   if (my $class_or_method = $opt->{filter}) {
#     my ($class, $method);
#     if ($class_or_method =~/^[A-Z]/) {
#       # it is class and method name is site_name
#       $class  = $o_class . '::' . $class_or_method;
#       $method = $opt->{name};
#     } else {
#       $class  = $o_class . '::' . 'DataFilter';
#       $method = $class_or_method;
#     }
#     $opt->{scraper} = $class->new;
#     $opt->{method}  = $method;
#   }
#   return {%$opt}
# }

1;
