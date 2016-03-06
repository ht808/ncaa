#!/usr/bin/perl

use LWP;

$session = LWP::UserAgent->new;
$response = $session->get("http://stats.ncaa.org/team/index/10260?org_id=721");
if(!$response->is_success) { die "query failed\n"; }

print $response->content;

exit;
@response_text = split(/\n/, $response->content);

$keep_table = 0;

for($i = 0; $i < scalar(@response_text); $i++)
{
    if($response_text[$i] =~ /<table/i) { $keep_table = 1; }
    elsif($response_text[$i] =~ /<\/table/i) { last; $keep_table = 0; }

    if($keep_table)
    {
	if($response_text[$i] =~ /[W|L]\s+(\d+)\s+-\s+(\d+)/)
	{
	    print $response_text[$i], "   $1 - $2\n";
	}
    }
}
