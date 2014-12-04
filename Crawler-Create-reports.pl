#!/usr/bin/perl

use strict;
use warnings;

use LWP::UserAgent;

use AnyEvent;
use AnyEvent::Util 'fork_call';
use DDP;
use DateTime;
my $cv = AE::cv;

$AnyEvent::Util::MAX_FORKS = 1000;
my $ua = LWP::UserAgent->new( max_redirect => 3, timeout => 3, agent => "my crawler");

my $filename = 'report.txt';
open(my $fh, '>>', $filename) or die "Could not open file '$filename' $!";

my @hosts;
while (<>) {
 chomp;
 push(@hosts, $_);
}


sub fork_http {

    my %ret_val;
    foreach my $host (@hosts) {
        $cv->begin;
        fork_call {
	my $response = $ua->get( $host);
	my $time = DateTime->now;
	my $str=$response->code ." => $time";
		return $str;
        } sub {
            $ret_val{$host} = shift;
            $cv->end;
        };
    }

    return \%ret_val;
}


my $http_data = fork_http();
$cv->recv;
while (my ($key, $value) = each (%$http_data))
{
	print $fh "Host = $key >> HTTP CODE >> $value\n";
}
close $fh;
