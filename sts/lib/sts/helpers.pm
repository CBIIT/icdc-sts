package sts::helpers;
use warnings;
use strict;
use Mojo::Base 'Mojolicious';
use Exporter qw(import);
our @EXPORT= qw( setup_sanitizer );


############################################################
#
#
#DESCRIPTION:
#   #santize_input   
#
#INPUT:  
#    int/string
#
#OUTPUT: 
#    a 'santized' string that should be same to make query with...
#
############################################################

sub setup_sanitizer {
    my ($self) = @_;

    eval $self->helper( sanitize_input_sref => sub {
     return sub { 

        my $input = shift;

        # simple sanitation check
        ## remove invalid XML characters
        $input =~ s/[\x00-\x08 \x0B \x0C \x0E-\x19]//g;

        ## remove control characters
        $input =~ s/[[:cntrl:]]//g;

        ## remove whitespace and print stuff
        $input =~ s/[^[:print:][:space:]]//g;

        ## remove unicode (only allow ascii)
        $input =~ s/[^ [:ascii:] ]//g ;

        ## keep string under 100 characters
        $input = substr($input, 0, 100);

        ## possibly simplify to smaller subset
        unless ($input =~ m/^[a-zA-Z_0-9-]+\z/) {
            $input = undef;
        }

        return "$input";
       }
    } );
}

1;