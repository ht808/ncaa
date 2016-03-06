#!/usr/bin/perl
# Tseu
use LWP;

$| = 1;
$session = LWP::UserAgent->new;

#&print_teams();

@r1 = (
    # MIDWEST #
    328, 352, 465, 312, 416, 472, 392, 288, 
    694, 626, 251, 519, 521, 255, 518, 104,

    # WEST #
    688, 738, 260, 234,  87, 704, 736, 454,
    812, 428, 545, 514,  77, 235, 327, 497,

    # EAST #
    334, 198, 703, 749, 690, 167, 796, 2915,
    387, 756, 473, 441, 147, 434, 768, 446,

    # SOUTH #
    193, 2678, 107, 367, 697, 731, 559, 639,
    513, 523, 51, 624, 575, 610, 739, 579, 
    );  #64 teams

@r2 = ();  #32 MW, W, E, S
@r3 = ();  #16 MW, W, E, S
@r4 = (); #8 MW, W, E, S
@r5 = (); #4 MW, W, E, S
@r6 = (); #2                                                                                             
@champ = ();

get_results();
get_stats();

&advance(\@r1, \@r2, 1);
&advance(\@r2, \@r3, 1);
&advance(\@r3, \@r4, 1);
&advance(\@r4, \@r5, 0);
&advance(\@r5, \@r6, 0);
&advance(\@r6, \@champ, 0);

print_bracket();

exit;


sub cache_hash()
{
    my $ref_hash = shift;
    my $hash_id = shift;
    
    open(FILE, ">$hash_id.dat");
    
    foreach my $key (keys(%$ref_hash))
    {
	print FILE "#$key,$$ref_hash{$key}#\n";
    }

    close(FILE);

    return;
}

 
sub read_cache()
{
    foreach $file ("NAME", "RECORD", "STAT")
    {
	open(FILE, $file) or die("Cannot open $file\n");
	while(<FILE>)
	{
	    if($file == "NAME")
	    {
		$_ =~ /#%s,%s#/;
		$NAME{$1} = $2;
	    }
	    elsif($file == "RECORD")
	    {
		$_ =~ /#%s,%s#/;
		$RECORD{$1} = $2;
	    }
	    elsif($file == "STAT")
	    {
		$_ =~ /#%s,%s#/;
		$STAT{$1} = $2;
	    }
	}
    }
    return;
}

sub get_results()
{
    print "[Starting 1st pass data acquisition]\n";
    for($j = 0; $j < scalar(@r1); $j++)
    {
	my $x = $r1[$j];
	my $response = $session->get("http://stats.ncaa.org/team/index/10260?org_id=$x");
	if(!$response->is_success) { next; }
	
##print $response->content;
	
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
		    if($NAME{$x} =~ /Iowa/) { $NAME{$x} = "N. Iowa"; }
#		print "### $1 ###\n";
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
    
#    &cache_hash(\%NAME, "NAME");
#    &cache_hash(\%RECORD, "RECORD");

    print "[Initial data loaded]\n";
    return;
}

sub get_stats()
{
    print "[Starting 2nd pass data acquisition]\n";
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

#    &cache_hash(\%STAT, "STAT");
    print "[Statistics loaded]\n";
    return;
}

sub advance()
{
    my $ra_teams = shift;
    my $ra_winners = shift;
    my $cinderella = shift;
    print "[Advancing one round]\n";
    use constant GO_BLUE => 1;
    use constant HOYA_SAXA => 1;
    use constant FUCK_DUKE => 1;

    for($i = 0; $i < scalar(@$ra_teams); $i+=2)
    {
	my $teamA = $$ra_teams[$i];
	my $teamB = $$ra_teams[$i+1];
#	printf "%d %d %d %d\n", get_fta($teamA), get_fta($teamB), get_fga($teamA), get_fga($teamB);
#	printf "  %d %d %d %d\n", get_fgm($teamA), get_fgm($teamB), get_ftm($teamA), get_ftm($teamB);
	if(get_fta($teamA) != 0 && get_fta($teamB) !=0 && get_fga($teamA) !=0 && get_fga($teamB) !=0)
	{
	    $modA = get_fgm($teamA)/get_fga($teamA) * get_ftm($teamA)/get_fta($teamA);
	    $modB = get_fgm($teamB)/get_fga($teamB) * get_ftm($teamB)/get_fta($teamB);
	}
	else { $modA = 1; $modB = 1; }
	
	$scoreA = $modA * (get_points($teamA) - get_opp_points($teamA));
	$scoreB = $modB * (get_points($teamB) - get_opp_points($teamB));
	
#	printf "%f * %d --  %f * %d\n", $modA, get_points($teamA), $modB, get_points($teamB);

	if($NAME{$teamA} =~ /Duke/ && FUCK_DUKE) { $scoreA *= 0.9; }
	if($NAME{$teamB} =~ /Duke/ && FUCK_DUKE) { $scoreB *= 0.9; }
	if($NAME{$teamA} =~ /Georgetown/ && HOYA_SAXA) { $scoreA *= 1.25; }
	if($NAME{$teamB} =~ /Georgetown/ && HOYA_SAXA) { $scoreB *= 1.25; }
	    
	if($scoreA > $scoreB)                                                                
	{                                                                                                
	    push(@$ra_winners, $teamA);
	}                                                                                                
	elsif($scoreB > $scoreA)                                                                                             
	{                                                                                                
	    push(@$ra_winners, $teamB);                                                                    
	}
	else
	{
	    if(get_seed($teamA) => get_seed($teamB)) { push(@$ra_winners, $teamA); }
	    else { push(@$ra_winners, $teamB); }
	}
    }

    return $ra_winners;
}

sub print_bracket()
{
    my $size = scalar(@r1) / 4;
    
    for($quad = 0; $quad < 4; $quad++)
    {
	for($i = 0; $i < $size; $i++) ## 1 2 3 ... 16
	{
	    print ">", $NAME{shift(@r1)}, "\n";  #Ok
	    
	    if(($i + 1) % 2) 
	    {
		print ">>\t\t", $NAME{shift(@r2)}, "\n"; #Ok
	    }
	    elsif(!(($i - 1) % 4))
	    { 
		print ">>>\t\t\t\t", $NAME{shift(@r3)}, "\n";
	    }
	    elsif(!(($i - 3) % 8))
	    { 
		print ">>>>\t\t\t\t\t\t\t\t", $NAME{shift(@r4)}, "\n";
	    }
	    elsif(!(($i - 7) % 16))
	    {
		print ">>>>>\t\t\t\t\t\t\t\t\t\t\t\t", $NAME{shift(@r5)}, "\n"; #Ok
	    }
	}

	print "\n+--------------------+\n";
    }
    
    printf "\nChampionsip Game: %s vs. %s\n", $NAME{$r6[0]}, $NAME{$r6[1]};
    printf "Winner: %s\n\n", $NAME{$champ[0]};
    
    return;
}

sub print_teams()
{
    foreach $team_id (keys(%NAME))
    {
	print "#", $team_id, "  -- ", $NAME{$team_id}, "\n";
#	print "#", $RECORD{$team_id}->[0], "\n";

	$ra_rec = $RECORD{$team_id};
       
	for($i = 0; $i < scalar(@$ra_rec); $i++)
	{
	    print $RECORD{$team_id}->[$i], ",";
	}
	print "\n";
	
	print "pts: ",  get_points($team_id);


##	print "#", $STAT{$team_id}->[0], "\n\n";
    }
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


    
