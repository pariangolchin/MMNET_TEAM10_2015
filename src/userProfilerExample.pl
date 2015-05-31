use strict;
use Profiler;

my $settingsFile = $ARGV[0];	# read file name from command line
if(! $settingsFile){
	die " you need to indicate settings file!\n";
}

# Read SETTINGS structure from json file
my $settingsJson = "";
open(F, $settingsFile)||die("I can not read the file $settingsFile");
while(my $r = <F>){
	$settingsJson .= $r;
}
close F;
my $settings = JSON::decode_json($settingsJson);


# Read RULES structure from json file
my $rulesJson = "";
open(F, $settings->{rulesFile})||die("I can not read the file $settings->{rulesFile}");
while(my $r = <F>){
	$rulesJson .= $r;
}
close F;


# This is the simple API to check all the rules and to compute
# the rule score for each node of the tree.
# If we need to introduce new method, just add it in the end of Profiler.pm class file 
# (copy and modify testMethod).

print "PROFILE1:\n";
my $profile1 = Profiler->new({
	rulesJson => $rulesJson
});
$profile1->runAll({
	input => "Vodafone-27416816"
});
$profile1->showScores();

print "\n\n";

print "PROFILE2:\n";
my $profile2 = Profiler->new({
	rulesJson => $rulesJson
});
$profile2->runAll({
	input => "freccia,tim"
});
$profile2->showScores();


print "\n\n";
print "MERGED:\n";
my $mergeProfile = Profiler->new({
	rulesJson => $rulesJson
});
$mergeProfile->merge({
	profiles => [$profile1, $profile2]
	});
$mergeProfile->showScores();


print "\n\n";


$mergeProfile->showAdvertisement({
	settings => $settings
});

