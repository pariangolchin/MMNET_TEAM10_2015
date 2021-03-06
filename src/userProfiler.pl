use strict;
use Profiler;

$| = 1;	# Force to write on the screen in the moment we call print

# ========================================================================
# Read SETTINGS structure from json file
# ========================================================================
my $settingsFile = $ARGV[0];	# read file name from command line
if(! $settingsFile){
	die " you need to indicate settings file!\n";
}

my $settingsJson = "";
open(F, $settingsFile)||die("I can not read the file $settingsFile");
while(my $r = <F>){
	$settingsJson .= $r;
}
close F;
my $settings = JSON::decode_json($settingsJson);

# ========================================================================
# Read RULES structure from json file
# ========================================================================
my $rulesJson = "";
open(F, $settings->{rulesFile})||die("I can not read the file $settings->{rulesFile}");
while(my $r = <F>){
	$rulesJson .= $r;
}
close F;


# ========================================================================
# Start the timer and listen
# ========================================================================
# $refresh: how many seconds wait to collect user data.
my $refresh = $settings->{refreshTime};
our $radarData = "";	# Global variable
# After $refresh seconds pause the execution of the script and call the function analyze
alarm($refresh);
$SIG{ALRM} = \&analyze;

# Infinite loop to read input from keyboard or from pipe of another script (eg: radar)
while(1){
	while(my $line = <STDIN>){
		$radarData .= "$line";
	}
}

# ========================================================================
# Compute profile evrey $refresh seconds using data in $radarData!
# ========================================================================
sub analyze(){

	# If there is new radar data
	if($radarData){
		if($settings->{debug}){
			print "\n\n";
			print "===========================================\n";
			print "ANALYZING DATA: \n";
			print "$radarData\n";
		}

		# Hash that, for each MAC adress contain the list (as string) of SSIDs
		my %MACtoSSIDs;

		# Split radarData (one element for line and put in array)
		my @lines = split(/\n/, $radarData);
		foreach my $line (@lines){
			# Example of $line:
			# "C0A0BBED842E","B407F94B2B87",-43,"2015-03-05 13:48:37","u-hopper-cisco"

			# Remove the characters "
			$line =~ s/"//gi;
			
			# Split user data on coma and put in array
			my @userData = split(/,/, $line);
			
			# Keep networks
			my $MACAdress = $userData[1];
			my $networks = "";
			for(my $i = 4; $i < scalar @userData; $i++){
				$networks .= "$userData[$i],";
			}

			if(!exists $MACtoSSIDs{$MACAdress}){
				$MACtoSSIDs{$MACAdress} = "";
			}

			$MACtoSSIDs{$MACAdress} .= "$networks,";
		}

		# Clean $radarData
		$radarData = "";

		# =================================================================
		# CALL Profiler API
		# =================================================================
		my @userProfiles;
		# For each user:
		foreach my $MACAdress (keys %MACtoSSIDs){

			# Remove duplicate in $MACtoSSIDs{$MACAdress} es: 
			# USER=F8D11121AE96	SSIDs=TP1,Vodafone,TP1 => SSIDs=TP1,Vodafone
			#print "$MACtoSSIDs{$MACAdress} => ";
			$MACtoSSIDs{$MACAdress} = &removeDuplicates( $MACtoSSIDs{$MACAdress} );
			#print "$MACtoSSIDs{$MACAdress}\n";

			if($settings->{debug}){
				print "DEBUG: Generating Profile for USER=$MACAdress\tSSIDs=$MACtoSSIDs{$MACAdress}\n";
			}

			# Create Profile Object
			my $profile = Profiler->new({
					rulesJson => $rulesJson
				});

			# Compute profile tree based on input data
			$profile->runAll({
					input => $MACtoSSIDs{$MACAdress}
				});
			# Push profiles in @userProfilesArray (used later to compute the merge)
			push(@userProfiles, $profile);
		}

		# Creating empty the merge:
		my $mergedProfile = Profiler->new({
					rulesJson => $rulesJson
				});
		# Computing merge with profiles in @userProfiles
		# Note: @userProfiles must be passed as reference to array, so as \@userProfiles
		$mergedProfile->merge({
			profiles => \@userProfiles
			});

		$mergedProfile->showScores();

		# Show advertaising
		$mergedProfile->showAdvertisement({
			settings => $settings
			});


		# =================================================================
		
	}
	else{
		# Pick random advertisement ?
		# ..
	}

	# Restart alarm. now the script go to listen again inside the main infinite loop 
	alarm($refresh);
}


sub removeDuplicates{
	my $string = shift;

	# Split list off SSIDs (in $sting) on commas and put in @SSIDs array
	my @SSIDs = split(",", $string);

	# Clean list without dumplicates
	my $cleanList = "";

	# When I see an element I mark as seen in $skip flag, so if I will see again, next time
	# I will skip.
	my %skip;
	foreach my $SSID (@SSIDs){
		# if is empty
		if(!$SSID){
			next;
		}
		if(exists $skip{$SSID}){
			next;
		}
		else{
			$skip{$SSID} = 1;
			$cleanList .= "$SSID,";
		}
	}

	return $cleanList;
}

#
