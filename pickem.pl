#!/usr/bin/perl

@r1 = ("A", "B", "C", "D", "E", "F", "G", "H",
       "I", "J", "K", "L", "M", "N", "O", "P",
       "Q", "R", "S", "T", "U", "V", "W", "X",
       "AA", "BB", "CC", "DD", "EE", "FF", "GG", "HH",
       "II", "JJ", "KK", "LL", "MM", "NN", "OO", "PP",
       "QQ", "RR", "SS", "TT", "UU", "VV", "WW", "XX",
       "AAA", "BBB", "CCC", "DDD", "EEE", "FFF", "GGG", "HHH",
       "III", "JJJ", "KKK", "LLL", "MMM", "NNN", "OOO", "PPP",
    );  #64  north, south, east, west

@r2 = ();  #32 north, south, east, west
@r3 = ();  #16 north, south, east, west
@r4 = (); #8 north, south, east, west
@r5 = (); #4 north, south, east, west
@r6 = (); #2
@champ = ();

advance(\@r1, \@r2, 1);
advance(\@r2, \@r3, 1);
advance(\@r3, \@r4, 1);
advance(\@r4, \@r5, 0);
advance(\@r5, \@r6, 0);
advance(\@r6, \@champ, 0);

print $champ[0];

exit;


sub advance()
{
    my $ra_teams = shift;
    my $ra_winners = shift;
    my $cinderella = shift;
    
    print "Calling Advance...\n";
    use constant GO_BLUE => 1;
    use constant HOYA_SAXA => 1;
    use constant FUCK_DUKE => 1;

#    print scalar(@$ra_teams);
#    exit;

    for($i = 0; $i < scalar(@$ra_teams); $i+=2)
    {
#	print $i, "\n";
#	if($score{team1} > $score{team2})
#	{
#	    push(team1 , $ra_winners);
#	}
#	else
#	{
#	    push(team2, $ra_winners);
#	}
	
	push(@$ra_winners, $$ra_teams[$i]);

    }
	
    return $ra_winners;
}

