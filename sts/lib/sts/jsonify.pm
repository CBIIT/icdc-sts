package sts::jsonify;
use base Exporter;
use JSON;
use strict;
our @EXPORT;


sub print_result_as_json {
    my (@query_result_set) = @_;

    ## now print the nice json
    my $jason = new JSON;
    print $jason->pretty->encode(\@query_result_set);

}
