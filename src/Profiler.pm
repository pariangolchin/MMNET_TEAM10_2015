use JSON;

use strict;
use warnings;

package Profiler;

=head1 NAME

Profiler.pm - Profiler API

=head1 SYNOPSIS

  	use Profiler;
 
 	# Create Profile for User1
 	my $profile1 = Profiler->new({ rulesJson => $jsonStructure });
 
 	# Compute rules for User1
 	$profile1->runAll({ input => $dataInput1 });
 
 
 	# Create Profile for User2
 	my $profile2 = Profiler->new({ rulesJson => $jsonStructure });
 
 	# Compute rules for User2
 	$profile2->runAll({ input => $dataInput2 });
 
 
 	# Create an empty profile for the merge
 	my $mergedProfile = Profiler->new({ rulesJson => $jsonStructure });
 
 	# Merge profile of User1 and User2
 	$mergedProfile->merge({ profiles => [$profile1, $profile2] });
 
 	# Show the scores for each node on STDOUT
 	$mergedProfile->showScore();
 
 	# Prepare HTML page for advertisement
 	$mergedProfile->showAdvertisement({ settings => $settingsJson });
 



=head1 DESCRIPTION

Recently, accessing to Wi-Fi networks is been drastically increased, due to the growth of global
interest in Wi-Fi technology. A significant amount of information  can be extracted from people’s
preferred Wi-Fi networks. However, the main challenge is how one can explore these data for a 
specific purpose. In fact, the main goal of this project is to investigate a solution to this problem.
The key focus in the project is on finding the important features from the users’ Wi-Fi networks in 
order to create their profile and demonstrate the relevant advertisement  on the public display. After 
exploring data from Wi-Fi radar device, “semantic hierarchical tree structure” is found to be the most 
applicable and suitable attribute to create the profiles. Then a responsive web-page based system has been 
implemented to dynamically select and illustrate the advertisement based on the created profile.

=head1 REQUIRES
L<JSON> 

imports encode_json, decode_json, to_json and from_json.

http://search.cpan.org/~makamaka/JSON-2.90/lib/JSON.pm


=head1 "PUBLIC" METHODS

=head2 new

 $self->new({rulesJson => $rulesJson});

This method creates an object of type ("class") Profiler. Inside this object it is contained the data structure representing "rules tree" and selected advertisement.

$rulesJson is the JSON string that describe the rule. It is an array of hash, in which each element is a ruleNode according to this schema:

 {
 		"ruleName"	: <STRING>,
 		"parents"	: [<STRING>, <STRING>, ...],
 		"method"	: <STRING>,
 		"data"		: [<STRING>, <STRING>, ...],
 		"advs"		: [
 							{
 								"name": <STRING>,
 								"file": <STRING>,
 								"businessValue": <INTEGER>
 							},
 							{
 								...
 							}
 					  ]
 }

The $self inner structure (you should not use outside this API!) it is an hash and comprises JSON defined structure:

 $self = {
 	rules => {
 		RuleName1 => {
 			ruleName => "RuleName1",
 			parents => [...],
 			method => ...,
 			data => ...,
 			advs => [...],
 			level => ...,
 			result => ...
 		},
 		{
 		RuleName2 => {
 			ruleName => "RuleName2",
 			parents => [...],
 			children => [...],
 			level => ...,
 			result => ...
 		},
 		...
 	}
 	adv => {
 		name: ...,
 		file: ...
 	}
 }

The attributes "level" and "children" of each node are computed based on tree structure, all the other are keeped as in original JSON configuration. $self->{adv} will store the selected advertisement.


=head2 runAll

 $self->runAll({input => $radarData});

Run all "registred" rule-checks in the JSON File against input data (SSIDs names). 

This method call private _run() that, in turn, executes each custom method, evaluates the rules and updates nodes result.


=head2 merge

 $self->merge({profiles => \@profiles});

Takes as input (a reference to) an array, in which have to be saved the Profiles of one or more users. This method just sum, for each node, the result of all the relative nodes of considered user profiles.

=head2 selectAdvertisement

 $self->selectAdvertisement({settings => $setting});

This method uses the algorithm described in details the technical documentation to select an appropriate advertisement to show to the user(s). $settings is the setting file content as JSON string.

In practice, copies the selected object in $self->{adv} so that showAdvertisement() can produce the final HTML output.

You probably do not have to use this method, because it is automatically called by showAdvertisement() in case $self->{adv} is empty.


=head2 showAdvertisement

 $self->showAdvertisement({settings => \$settings});

This method uses data copied in $self->{adv} from selectAdvertisement() in order to produce the final HTML output (adv.html). If no data are present in $self->{adv} it calls before - in your place - selectAdvertisement().


=head2 showScores

 $self->showScores();

Just for debugging purpose, he shows the overall score for each node of the tree.


=head1 "CUSTOM" METHODS

=head2 IsTravelerBasedOnNetworksNumber

1 | 0 = $self->IsTravelerBasedOnNetworksNumber({input => $SSIDs, data => $numberOfNetworks});

It returns 1 (true) if the user data contains more than $numberOfNetworks network names. The rationale is that if an user visited several networks, it is resonable that he/her is a "traveler". The correct threshold to use should require accurate benchmarking.


=head2 PatternSearch

 1 | 0 = $self->PatternSearch();

It returns 1 (true) if the user data is compatible ("contains") one or more string patterns. String patterns are Perl regular expressions (regex).


=head1 "PRIVATE" METHODS

=head2 NOTE

Although Perl does not implement a real distinction between public and private methods, you should not use these methods
 directly from the calling script. 

Here is a quick description just for smoother eventual maintenance of the source code and to allow you to more easily follow the software logic.


=head2 _computeChildren

 $self->_computeChildren();

Uses nested iterations inside three data structure to associate, for each node, the parent(s), if any.


=head2 _computeAllLevels

 $self->_computeAllLevels();

For each node compute the level (leaves is level 1). Node on the same level "contains the same amount of concept information". If a node can have different leveles according to his children, keep the higest one; eg:

 ROOT -> A -> B -> C
         |    \--> D
         \-------> E

In this case node A will have level = 3 (not 2).

This method just checks all the nodes of the tree; if one node is a leaf (so it has a method associated), it calls on this node the method _computeLevel().

=head2 _computeLevel

 $self->_computeLevel({rule => \%ruleObject, childLevel => $childLevel});

Recursively move from a selected leaf to the root and compute, for each node of the tree the correct level.


=head2 _run

 1 | 0 = $self->_run({ruleName => $ruleName});

Given a ruleName, if there is an associated method, it calls this subroutine (that can return 1 or 0). After that it call _incrementParentRule() to increment recursively the score of the parents until reach the root.


=head2 _incrementParentRule

 $self->_incrementParentRule({value => $valueFromChild, parents = \@parents});

Compute the score of parents. After that, for each parent, call again _incrementParentRule(), until there are no more parents (eg: ROOT).

If there are N parent and the value to propagate is 1, each parent will be incresed by 1/N.



=head2 _getAdvertisementFromRule

 $self->_getAdvertisementFromRule({rule => \%ruleObject, advertisements => \@advertisementObjects});

Once that selectAdvertisement() find one or more node(s) that describe the user(s), this method move down in the tree (from ROOT to leaves) and find all the leaves descendent by the selected node(s). If the score in the leaves is not zero, it save the associated advertisement objects inside the advertisements (array reference initially empty, passed be selectAdvertisement). The appropriate advertisment will be (more or less) randomly chosen from the final @advertisements array.


=head1 AUTHORS

Bernadette Edith Ndjekal	(bernadette.ndjekal@studenti.unitn.it)
Parian Golchin 				(parian.golchin@studenti.unitn.it)


=cut




############################################################
# "Public" methods
############################################################

# Creating object of "Class" Profiler
sub new{
	my $class = shift;	# $class: will contain the string "Profiler"
	my $param = shift;

	# Perl class manage system
	my $self = {}; 			# It is the empty structure that will contain all attribute and methods reference
	bless $self, $class; 	# "Assign" this object to the current class (the current package),
							# so $self will be an object of type "Profiler".
	
	# Transforming the content of the rule.json file (a string) in the Perl structure of the Profiler tree
	# that is (a reference to) an array
	my $rulesStructure = JSON::decode_json($param->{rulesJson});

	# Inject each rule in $self, so in the current object
	# $rule is (reference) to hash
	# We are translating $rulesStructure that is an array in $self that is an hash
	foreach my $rule (     @{$rulesStructure}   ){	
		my $ruleName = $rule->{ruleName};
		$self->{rules}->{$ruleName} = $rule;
		# Initialize result to zero.
		$self->{rules}->{$ruleName}->{result} = 0;
	}

	# Compute levels of each rule in the tree
	# 	Add to each $self->{rules}->{RULENAME} the field level (scalar)
	$self->_computeAllLevels();

	# Compute children
	# 	Add to each $self->{rules}->{RULENAME} the field children (reference to an array of string)
	$self->_computeChildren();

	# No selected advertisement
	$self->{adv} = "";

	# Finally return the object.
	return $self;
}

# Run all "registred" rule-checks in the JSON File
sub runAll(){
	my $self = shift;
	my $param = shift;

	foreach my $ruleName (keys %{$self->{rules}}){
		$self->_run({
			ruleName => $ruleName, 
			input => $param->{input}
		});
	}
	
}

sub merge(){
	my $self = shift;
	my $param = shift;

	my @ruleNames = keys %{$self->{rules}};

	# For each profile
	foreach my $profile (@{$param->{profiles}}){
		# For each rule
		foreach my $ruleName (@ruleNames){
			# Add score to current merge object
			$self->{rules}->{$ruleName}->{result} += $profile->{rules}->{$ruleName}->{result};
		}
	}
}

sub showScores(){
	my $self = shift;
	my $param = shift;

	print "SCORE\tLEVEL\tRULE_NAME\n";
	foreach my $ruleName (sort keys %{$self->{rules}}){
		print "$self->{rules}->{$ruleName}->{result}\t$self->{rules}->{$ruleName}->{level}\t$ruleName\n";
	}
	
}

sub selectAdvertisement(){
	my $self = shift;
	my $param = shift;

	my $settings = $param->{settings};

	my @bestRules;

	# For each level
	for(my $l = 1; $l <= $settings->{maxLevelToCheck}; $l++){

		# Delete all bestNodes (return to empty array)
		@bestRules = ();

		my $bestResult 		= 0;		# What is higest score?
		my $bestResultCount = 0;		# How many nodes in this level have the best score?

		# Foreach rule
		foreach my $ruleName (keys %{$self->{rules}}){
		
			my $rule = $self->{rules}->{$ruleName};
 	
			# If rule is in the level I'm checking
			if($rule->{level} == $l){
				
				# If rule result is > bestResult
				if($rule->{result} > $bestResult){
					# Delete all bestNodes (return to empty array)
					@bestRules = ();

					# Push rule in @bestRules
					push(@bestRules, $rule);

					# Set best score and reset counter
					$bestResult = $rule->{result};
					$bestResultCount = 1;
				}
				# else, if result == bestResult
				elsif($rule->{result} == $bestResult){
					# Push rule in @bestRules
					push(@bestRules, $rule);

					# Increment counter
					$bestResultCount = $bestResultCount + 1;
				}
			}
		}

		if($settings->{debug}){
			print "DEBUG: level=$l, bestResult=$bestResult, bestResultCount=$bestResultCount\n";
		}

		# If I found a rule with absolute best result ($bestResultCount == 1) use this
		if($bestResultCount == 1){

			if($settings->{debug}){
				print "DEBUG: level=$l: found absolute best score!\n";
			}

			last;	# Don't go to next level
		}
		# If I can not found an absolute best score ($bestResultCount > 1)
		else{
			# If I'm not in last level I can check, go ahead
			if($l < $settings->{maxLevelToCheck}){
				if($settings->{debug}){
					print "DEBUG: level=$l: not found absolute best score, check next level\n\n";
				}				
				next;
			}
			# If I'm in last level
			else{
				# Use data contained in @bestRules
				if($settings->{debug}){
					print "DEBUG: level=$l: not found absolute best score, I'm in last level.\n\n";
				}
			}
		}

	}

	# At this point @bestRules contains references to the best rules (the rules nearest the interest of the user[s])
	# I need all advertisement objects related to this user (searching in children, children-of-children, ...)
	my @advertisements;
	foreach my $rule (@bestRules){
		if($settings->{debug}){		
			print "DEBUG: Searching advertisements from rule = $rule->{ruleName}\n";
		}
		$self->_getAdvertisementFromRule({
				rule 			=> $rule,
				advertisements 	=> \@advertisements		# I pass the reference of this array!
			});
	}

	# If @advertisement is empty it means that we didn't find any true rule. In this case we consider all
	# advertisements and we pick one randomly (or based on buisinessValues).
	# In this case we copy in @advertisements all the possible advertisements and continue as normal.
	if(@{advertisements} == 0){
		if($settings->{debug}){
			print "\nDEBUG: Not possible find a true rule. Considering all advertisements!\n";
		}
		foreach my $ruleName (keys %{$self->{rules}}){
			foreach my $adv ( @{ $self->{rules}->{$ruleName}->{advs} } ){
				push(@advertisements, $adv);
			}
		}
	}


	# Normalizing buisiness values
	my $businessValueSum = 0;
	foreach my $adv (@advertisements){

		if(!$adv->{businessValue}){
			$adv->{businessValue} = 1;
		}

		$adv->{businessValue} += $businessValueSum;
		$businessValueSum = $adv->{businessValue};
	}

	if($settings->{debug}){
		print "\nDEBUG: ADVERTAISMENT\tBUISINESS VALUE\n";
		foreach my $adv (@advertisements){
			print "DEBUG: $adv->{name}\t$adv->{businessValue}\n";
		}
	}

	# If don't consider buisinessValue picks random advertisement
	if(! $settings->{considerBusinessValue} || $settings->{considerBusinessValue} eq "false"){
		my $numberOfAdvertisement = @advertisements;
		my $randomIndex = int(rand($numberOfAdvertisement));
		$self->{adv} = $advertisements[$randomIndex];
	}
	# Else picks considering buisinessValue
	else {
		my $randomValue = int(rand($businessValueSum) + 1);
		
		if($settings->{debug}){
			print "\nDEBUG: Random value\t$randomValue\n\n";
		}

		# For each advertisement
		my $previousValue = 0;
		for(my $advIndex = 0; $advIndex < @advertisements; $advIndex++){
			my $adv = $advertisements[$advIndex];
			if( $randomValue > $previousValue && $randomValue <= $adv->{businessValue}){
				$self->{adv} = $adv;
				last;
			}
			else{
				$previousValue = $adv->{businessValue};
			}
		}	
	}

}


sub showAdvertisement(){
	my $self = shift;
	my $param = shift;

	my $settings = $param->{settings};

	# If it was not yet selected advertisement, select it now using API!
	if($self->{adv} eq ""){
		$self->selectAdvertisement({
				settings => $settings
			});
	}

	my $adv = $self->{adv};

	print "** Show advertisement =======> $adv->{name}\n\n";

	# Copy template file content to a string
	my $template = "";
	open(F, $settings->{htmlTemplate})||die("I can not read $settings->{htmlTemplate}");
	while(my $r = <F>){
		$template .= $r;
	}
	close F;

	$adv->{file} = $settings->{webPageAdressRoot} . $settings->{webPageImageFolder} . "/" . $adv->{file};

	# Perform substitutions in text from htmlTemplate with selected advertisement data
	$template =~ s/__TITLE__/$adv->{name}/gi;
	$template =~ s/__IMAGE__/$adv->{file}/gi;

	# Compatibility function
	if($settings->{chromeCompatibility}){
		# Allow the page to refresh itself
		my $meta = "<meta http-equiv='refresh' content='10'>";
		$template =~ s/<!--COMPATIBILITY-->/$meta/gi;
	}

	# Write new html file
	open(H, ">$settings->{webServerFolder}/adv.html")||die("I can not write $settings->{webFolder}");
	print H $template;
	close H;


	# Reset advertisement
	$self->{adv} = "";
}

############################################################
# Helper methods
############################################################

# For each node compute the level (leaves is level 1), if a node can have different
# leveles according to his children, keep the higest one
sub _computeAllLevels(){
	my $self = shift;
	my $param = shift;

	# 1: find the leaves (rules with method) and go up in the tree for parents
	foreach my $ruleName (keys %{$self->{rules}}){
		if($self->{rules}->{$ruleName}->{method}){
			$self->_computeLevel({
				rule => $self->{rules}->{$ruleName},
				childLevel => 0
			});
		}
	}
}

sub _computeLevel(){
	my $self = shift;
	my $param = shift;

	my $rule 		= $param->{rule};	
	my $childLevel 	= $param->{childLevel};

	# SET LEVEL OF THIS RULE
	# If it is a rule with method set level = 1
	if($rule->{method}){
		$rule->{level} = 1;
	}	
	# If exists a level for this node check if $childLevel + 1 is bigger
	elsif($rule->{level}){
		if($rule->{level} < $childLevel + 1){
			$rule->{level} = $childLevel + 1
		}
	}
	# Else save $childLevel + 1
	else{
		$rule->{level} = $childLevel + 1
	}

	# SET IN RECURSIVE WAY LEVEL OF PARENTS
	foreach my $parentName (@{$rule->{parents}}){
		$self->_computeLevel({
				rule 		=> $self->{rules}->{$parentName},
				childLevel 	=> $rule->{level}
			});
	}
}


# Find children and add to Profile stucture
sub _computeChildren(){
	my $self = shift;
	my $param = shift;

	# Try each possible pair of node inside the tree ($ruleNameParent, $ruleNameX).
	# If inside the array @parents of the second one ($ruleNameX) I find the name of the first node ($ruleNameParent)
	# I add the name of the second ($ruleNameX) inside the array @children of the first one ($ruleNameParent).

	# Compute children list for each node.
	foreach my $ruleNameParent (keys %{$self->{rules}}){
		# Fore each node in the tree (ruleNameX)
		foreach my $ruleNameX (keys %{$self->{rules}}){
			# List of parents of ruleNameX
			foreach my $parentName (@{$self->{rules}->{$ruleNameX}->{parents}}){
				# If the parent of ruleNameX is $ruleNameParent, save in $ruleNameParent ulre $ruleNameX as child.
				if($parentName eq $ruleNameParent){

					# Before saving check child rule is not arleady saved for this parent
					my $skip = 0;
					foreach my $ruleNameChild (@{$self->{rules}->{$ruleNameParent}->{children}}){
						if ($ruleNameChild eq $ruleNameX){
							$skip = 1;
							last;
						}
					}
					if($skip){
						# skip to next parent
						next;
					}

					push(@{$self->{rules}->{$ruleNameParent}->{children}}, $ruleNameX);
				}
			}
		}
	}
}

# Run one rule check based on the rule name
sub _run(){
	my $self = shift;
	my $param = shift;

	my $ruleName = $param->{ruleName};
	# $rule is now (a reference to) an hash an reppresent a leaf of structure saved in $self
	my $rule = $self->{rules}->{$ruleName};	

	# $method is a string and reppresent the function that I have to call to evaluate input
	my $method = $rule->{method};

	# If method exists do something (just leaves have methods)
	if ($method){

		# Call method functions and pass as parameters the rule structure, the data present in json
		# and the input
		my $result = $self->$method({
			rule => $rule, 
			data => $rule->{data}, 
			input => $param->{input}
		});	

		# Save the result in this rule
		$rule->{result} = $result;

		# If rule is true ($result = 1)
		# Go up on the tree and add $result (1) in all the node I can find
		if($result){
		
			$self->_incrementParentRule({
				value => $result, 
				parents => $rule->{parents} 
			});
		
		}

		return $result;
	}
}

# Compute the score, recorsively to parent(s)
sub _incrementParentRule(){
	my $self = shift;
	my $param = shift;

	my $value = $param->{value};

	my $numberOfParents = @{$param->{parents}};

	foreach my $parentRuleName (@{$param->{parents}}){
		$self->{rules}->{$parentRuleName}->{result} = $self->{rules}->{$parentRuleName}->{result} + $value / $numberOfParents ;
		$self->_incrementParentRule({
			value => $value / $numberOfParents, 
			parents => $self->{rules}->{$parentRuleName}->{parents}
		});
	}

}

# Go dow in the tree and, from a rule find all advertisements.
sub _getAdvertisementFromRule(){
	my $self = shift;
	my $param = shift;

	my $rule 			= $param->{rule};
	my $advertisements 	= $param->{advertisements};		# It is a reference to array, each element is an advertisement object

	# If rule has advertisement, push in the array
	if($rule->{advs}){
		foreach my $adv (@{$rule->{advs}}){
			push(@{$advertisements}, $adv);
		}
	}

	# If rule has children, recursively call _getAdvertisementFromRule()
	if($rule->{children}){
		foreach my $childName ( @{ $rule->{children} } ){
			
			# If the result (the score) of this child is zero, just skip it!
			# We don't want consider the advertisements connected to this rule!
			if($self->{rules}->{$childName}->{result} == 0){
				next;
			}

			$self->_getAdvertisementFromRule({
					rule 				=> $self->{rules}->{$childName},
					advertisements 		=> $advertisements
				});
		}
	}

}


############################################################
# Custom methods
############################################################

sub IsTravelerBasedOnNetworksNumber(){
	my $self = shift;
	my $param = shift;

	my @networks = split(/,/, $param->{input});
	if(@networks >= $param->{data}){
		return 1;
	}
	return 0;
}

# Find the text-pattern inside the input (if at least one is found, return true)
sub PatternSearch(){
	my $self = shift;
	my $param = shift;

	foreach my $pattern (@{$param->{data}}){
		if($param->{input} =~ /$pattern/i){
			return 1;
		}
	}
	return 0;
}

# Template to develop new custom methods
sub testMethod(){
	my $self = shift;
	my $param = shift;

	# Input is scalar
	my $input = $param->{input};

	# Data is a reference of array
	my $data = $param->{data};

	my $condition = '';
	if($condition){
		return 1;
	}
	return 0;
}



1;


