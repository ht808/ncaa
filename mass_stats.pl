#!/usr/bin/perl

use LWP;

$session = LWP::UserAgent->new;
print "[Starting 1st pass data acquisition]\n";
&get_results();
print "[Initial data loaded]\n";
print "[Starting 2nd pass data acquisition]\n";
&get_stats();
print "[Statistics loaded]\n";
&print_output();

exit;


sub get_results()
{
    for($x = 1; $x < 10000; $x++)
    {
	my $response = $session->get("http://stats.ncaa.org/team/index/10260?org_id=$x");
	if(!$response->is_success) { next; }
	
	my @response_text = split(/\n/, $response->content);
	my $keep_table = 0;
	my $strip_name = 0;
	my @record = ();
	
	for($i = 0; $i < scalar(@response_text); $i++)
	{
	    if($response_text[$i] =~ /<h1>/i && $strip_name != 2) { $strip_name = 1; }
	    if($strip_name == 1) 
	    {
		if($response_text[$i] =~ /not available for (.*)\./) ## no data available, set name and goto next team
		{
		    $NAME{$x} = $1;
		    last;
		}
	    if($response_text[$i] =~ /(\w+.*?)\s+\(/)
	    {
		$strip_name = 2;
		$NAME{$x} = $1; ## Set team name
##		print "### $1 ###\n";
	    }
	    }
	    
	    if($response_text[$i] =~ /<table/i) { $keep_table = 1; }
	    elsif($response_text[$i] =~ /<\/table/i) { last; $keep_table = 0; }
	    
	    if($keep_table)
	    {
		if($response_text[$i] =~ /[W|L]\s+(\d+)\s+-\s+(\d+)/)
		{
		    push @record, "$1#$2";
#		print $response_text[$i], "   $1 - $2\n";
		}
	    }
	} ## END OF FOR LOOP -- parse each html line
	
	$RECORD{$x} = \@record;
	
    } ## END OF FOR LOOP -- team_id
    return;
}

sub get_stats()
{
    foreach my $team_id (keys(%NAME))
    {
	my $response = $session->get("http://stats.ncaa.org/team/stats?org_id=$team_id&sport_year_ctl_id=10260");
	if(!$response->is_success) { next; }
	
	my @response_text = split (/\n/, $response->content);
	my $total_row = 0;
	my $opp_total_row = 0;
	my @record = ();

##	print $team_id, "--", scalar(@response_text), "\n";
	for(my $i = 0; $i < scalar(@response_text); $i++)
	{
	    if($response_text[$i] =~ /^\s*Totals/) { $total_row = 1; }
	    if($response_text[$i] =~ /Opponent Totals/) { $opp_total_row = 1; }
 	    if($total_row)
	    {
		if($opp_total_row && $response_text[$i] =~ /<\/table/)
		{
		    last;
		}
		if($response_text[$i] =~ /<div\s*>(.*)<\/td>/)
		{
		    my $num = $1;
		    $num =~ s/,//g;
##		    print "## $num ## ";
		    push @record, $num;
		}
	    }
	} ## END OF FOR LOOP -- line of html
	$STAT{$team_id} = \@record;
    } ## END OF FOR EACH TEAM

    return;
}

sub print_output()
{

    print "[Printing to file]\n";

    open(OUTPUT, ">output.dat") or die("Cannot open output file\n\n");

    foreach $team_id (keys(%NAME))
    {
#	print "#", $team_id, "  -- ", $NAME{$team_id}, "\n";
#	print "#", $RECORD{$team_id}->[0], "\n";
	
#	print "hey";
	$ra_rec = $RECORD{$team_id};
	my $wins = 0;
	my $losses = 0;
       
	for($i = 0; $i < scalar(@$ra_rec); $i++)
	{
	    $$ra_rec[$i] =~ /(\d+)#(\d+)/;
#	    print "$1 $2 ##";
	    if($1 > $2)
	    {
		$wins++;
	    }
	    else
	    {
		$losses++;
	    }
	    
	}

	my $record;
	if(($wins + $losses) > 0)
	{
	    $record = $wins / ($wins + $losses);
	}
	else { $record = 0; next; }

	printf(OUTPUT "%f,", $record);
	$ra_stat = $STAT{$team_id};

	for($i = 0; $i < scalar(@$ra_stat); $i++)
	{
	    printf(OUTPUT "%s,", $$ra_stat[$i]);
	}
	print(OUTPUT "\n");
	
##	print "#", $STAT{$team_id}->[0], "\n\n";
    }
    
    close(OUTPUT);
    return;
}

sub get_seed()
{
    my $team_id = shift;
    my $ra = shift;
    
    for($i = 0; $i < scalar(@$ra); $i++)
    {
	if($$ra[$i] == $team_id)
	{
	    my @seedpos = (1, 16, 8, 9, 5, 12, 13, 6, 11, 3, 14, 7, 10, 2, 15);
	    $seed = $seedpos[$i % 16 - 1];
	}
    }
    
    return $seed;
}

sub get_points()
{
    return @{$STAT{$_[0]}}->[10];
}

sub get_opp_points()
{
    return @{$STAT{$_[0]}}->[31];
}

sub get_fga()
{
     return @{$STAT{$_[0]}}->[2];
}

sub get_fgm()
{
     return @{$STAT{$_[0]}}->[1];
}

sub get_opp_fga()
{
     return @{$STAT{$_[0]}}->[23];
}

sub get_opp_fgm()
{
     return @{$STAT{$_[0]}}->[22];
}

sub get_fta()
{
     return @{$STAT{$_[0]}}->[8];
}

sub get_ftm()
{
     return @{$STAT{$_[0]}}->[7];
}

sub get_opp_fta()
{
     return @{$STAT{$_[0]}}->[29];
}

sub get_opp_ftm()
{
     return @{$STAT{$_[0]}}->[28];
}

sub get_reb()
{
     return @{$STAT{$_[0]}}->[14];
}

sub get_opp_reb()
{
     return @{$STAT{$_[0]}}->[35];
}


    
