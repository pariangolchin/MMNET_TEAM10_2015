======================================================
                     WI-FI 
                  RADAR-BASED 
           PROFILING AND RECOMMENDER
======================================================

Bernadette Edith Ndjekal	(bernadette.ndjekal@studenti.unitn.it)
Parian Golchin 				(parian.golchin@studenti.unitn.it)


------------------------------------------------------
Main Content
------------------------------------------------------
	
	1. Introduction
	2. Prerequisites
	3. How to Install
	4. How to Configure the system
	5. How to prepare the tree structure
	6. How to run
	7. Perl files (how to develop your own implementation)
	8. HTML templates (how to customize advertisment view)
	9. API Documentation
   10. Used resources


------------------------------------------------------
1. Introduction
------------------------------------------------------

	Recently, accessing to Wi-Fi networks is been drastically increased, due to the growth of global
	interest in Wi-Fi technology. A significant amount of information  can be extracted from people’s
	preferred Wi-Fi networks. However, the main challenge is how one can explore these data for a 
	specific purpose. In fact, the main goal of this project is to investigate a solution to this problem.
	The key focus in the project is on finding the important features from the users’ Wi-Fi networks in 
	order to create their profile and demonstrate the relevant advertisement  on the public display. After 
	exploring data from Wi-Fi radar device, “semantic hierarchical tree structure” is found to be the most 
	applicable and suitable attribute to create the profiles. Then a responsive web-page based system has been 
	implemented to dynamically select and illustrate the advertisement based on the created profile.


------------------------------------------------------
2. Prerequisites
------------------------------------------------------

	To execute the scripts you need these prerequisites installed on your Linux machine:

	a) Perl interpreter:
	   In Linux/Mac OS probably it is already installed in your system (try to type perl -v in your
	   terminal/console). All the information related installing Perl on different OS can
	   be found here: https://www.perl.org/get.html.

	b) Perl JSON module:
	   Open a terminal (Linux) or cmd (windows) and type:
			cpan
	   install module with (if it is the first time you use CPAN it could ask some question, you can just
	   keep the default values):
			install JSON
	   exit with:
			quit

	d) A modern web browser (we tested the scripts with Chrome Version 41 and Firefox 37.0).

		........................................................................
		IMPORTANT: If you run the script locally outside the web-server folder and you need to use Chrome
		browser you need to:
		1. Add in settings file the attribute:
			"chromeCompatibility": 1
		2. Point web browser on the file adv.html (not index.html)!
		This procedure avoid a bug due to security policies of chrome: "Uncaught SecurityError: 
		Blocked a frame with origin "null" from accessing a frame with origin "null". 
		Protocols, domains, and ports must match." 
		........................................................................

	c) Not strictly required (optional), a web-server (eg: Apache).


------------------------------------------------------
3. How to Install
------------------------------------------------------

	Just copy the src files inside a folder. If you want show the web-page remotely, copy insider a folder
	in which your web-server can read and write (eg: /var/www/...) and change the owner as the web-server user
	(eg in Ubuntu: sudo chown www-data /var/www/YOUR_FOLDER -R). Be sure that your normal user can write configuration
	files.


------------------------------------------------------
4. How to Configure the system
------------------------------------------------------

	All the configurations you need to change are inside the text file "settings.json". In particular you would like to
	change:

		debug:	[0|1]
			Show or not to show debug messages on STDOUT
	
		refreshTime:	[integer]
			It is the time (in sec) that the system waits to collect data from different users before start 
			building the user's profiles and the merged profile.
			We suggest to use short times (eg 10 sec) if the screen is positioned in a place where 
			people pass quickly (eg: shop window), longer time (eg 60 sec) if the screen is positioned in a 
			place where people usually stand (eg: bus-stop, train platforms, ...).
	
		rulesFile:	[filename]
			Is the file that represents the tree.
	
		considerBusinessValue:	[true|false]
			If it is setted to "true", after selecting the compatible advertisements the system will pick one
			randomly but consider the probability to choose a linear function of the buisinessValues associated
			to each selected avertisement. If it is setted to "false", it will use a uniform distribution probability.
		
		maxLevelToCheck:	[integer]
			It is the max level the algorithm will check to find an absolute highest score value in the node of the tree.
			Lower it is, more specific will be the concepts.

		webPageAdressRoot:	[string]
			It is the root of html files. Use just "." if you don't want to access data through web-server, otherwise
			put the url of root (eg: "http://127.0.0.1/ADV/").
		
		webPageImageFolder:	[string]
			It is the folder with image files, refer to webPageAdressRoot (eg: "/images/")
	
		webServerFolder:	[string]
			It is the absolute path of root ON THE FILE SYSTEM (software will use this folder 
			to write adv.html file). It can be just "/var/www/ADV/" or "C:\...\...\..." .
	
		htmlTemplate:	[string]
			It is the html template file the system will use to show advertisement (see "Advertisement template").


------------------------------------------------------
5. How to prepare the tree structure
------------------------------------------------------	
	Tree structure is saved in a json text file (by default rules.json). Formally the tree structure 
	is an array of object. Each object (node) represents a rule and/or a semantic concept.
	The structure should be this:
	
	{
		"ruleName"	: <STRING>,
		"parents"	: [<STRING>, <STRING>, ...],
		"method"	: <STRING>,
		"data"		: [<STRING>, <STRING>, ...],
		"advs"		: 	[
							{
								"name": 			<STRING>,
								"file": 			<STRING>,
								"businessValue":	<INTEGER>
							},
							{
								...
							}
							,
								...
						]
	}
	
	In which the only mandatory field is "ruleName". More in details:
		ruleName:	
			is the name that identifies the rule inside the hash (map) internal structure.
		parents:
		 	array of ruleName string that represents the node(s) connected to current node,
		 	with higher level
		method:
		 	it is the name of Perl "custom" subroutine to evaluate input data (just node with level = 1,
		 	so leaves of the tree) should be associated to one method.
		data:
		 	it is the "internal" data that will be passed to the method to evaluate the user input
		 	data. According to the implementation of Perl method, it could be any kind of data
		 	(scalar, array, hash or complex data structure).
		advs:
			this array contain the adv data. As method should be defined just for node on first
			level. Mandatory for advs objects data are:
			name:
				it will be the "title" to show above the picture.
			file:
				it will be the image name (or in general the file name to pass to adv template).
			businessValue:
				this value is linearly related to the probability to pick this advertisement 
				from the array of compatible advertisements. It could be, for example the amount
				of money paid by customer for his/her advertisement campaign.
	

------------------------------------------------------
6. How to run
------------------------------------------------------
	Before running the scripts please read also the following chapters.
	We assume you are using a Linux system;
	briefly to run the main script, go in the src folder of the project and type this command:

	[RADAR APPLICATION] | perl ./userProfile.pl [SETTING-FILE]

	in which we assume [RADAR APPLICATION] is an application that reads data from radar and prints
	in STDOUT data in the format defined in the next chapter.

	If [RADAR APPLICATION] writes instead (in real time) inside a file, you can use:

	tail -f [FILE WRITTEN BY RADAR APPLICATION] | perl ./userProfile.pl [SETTING-FILE]

	Every <refreshTime> sec, the script userProfile.pl will overwrite the file "adv.html" with title
	and file extracted from selected advertisement. The main html file "index.html" will reload
	the content of "adv.html" each 10 sec, so, to show the updated advertisement you just need
	to point your browser to this index.html file.

	If your screen device is connected to Internet or Intranet to the machine that computes the 
	data, you need to contact the web-server on that machine pointing your browser to:

	<webPageAdressRoot>/index.html

	eg:

	http://[IP_ADRESS]/ADV/index.html

	
------------------------------------------------------
7. Perl files (how to develop your own implementation)
------------------------------------------------------

	In present repository you find four Perl files:

	userProfile.pl
		This is the main script. It collects radar data from STDIN and each <refreshTime> (sec), for each
		user it computes the profile. After that, it merges all data in a new profile and uses this last one
		to select and show advertisement.
		Input data (one per line) should be in the format:

		"MAC RADAR","MAC USER",SIGNAL,"DATE TIME","SSID1,SSID2,..."
		[STRING],[STRING],[SIGNED INT],[YYYY-MM-DD HH:MM:SS],[STRING]


	Profiler.pm
		It is the API with all the methods required to select and show advertisement. 
		Although in Perl there is no real distinction, we can divide these methods in:
		- Public methods: these are the methods you should call in your own implementation.
		- Private methods: you should not use these subroutine, that are called by public methods.
		- Custom methods: these are the subroutine you have to implement to check any kind of rules
			on user data. The names of these methods are included in rules.json (in the method field).
			A general structure should be:

			sub testMethodName(){
				my $self = shift;				// Data structure (if you need)
				my $param = shift;		

				# Input is scalar
				my $input = $param->{input};	// SSIDs names (comma separated)

				# Data is a scalar or a reference
				my $data = $param->{data};		// Data defined in rules.json for this method

				my $condition = ...;			// Your logic implementation
				if($condition){
					return 1;					// If condition is true
				}
				return 0;						// If condition is false
			}

	userProfileExample.pl
		This template file could help you to design your own implementation using our Profiler API.

	radar.pl
		This simple script simulates users passing near radar reading real SSID's from csv file 
		and returning random lines at random times.


------------------------------------------------------
8. HTML Templates (how to customize advertisment view)
------------------------------------------------------

	HTML is a very simple way to show advertisements. Basically the system works just 
	using two files:

	index.html
		Probably you don't need to change this file. It just loads inside an iFrame the content
		of "adv.html" and it refreshes the page evry <n> seconds.

	advTemplate.html
		If you need to customize the view you have to change this file. "adv.html" is just a copy
		of this file in which:
		__IMAGE__ will be the content of "file" field of selected advertisement.
		__TITLE__ will be the content of "name" field of selected advertisement.


------------------------------------------------------
9. API Documentation
------------------------------------------------------

	API documentation can be found in the ./doc/ folder.
	

------------------------------------------------------
10. Used resources
------------------------------------------------------

	Json syntax:
		http://json.org/
		http://www.w3schools.com/json/json_syntax.asp

	Json syntax validator and parser:
		http://json.parser.online.fr/

	Perl programming introduction:
		http://www.perl.com/pub/2000/10/begperl1.html

	Perl "Object Oriented Programming":
		http://www.tutorialspoint.com/perl/perl_oo_perl.htm
		http://perldoc.perl.org/perlootut.html

	Simple responsive html idea, from:
		https://forum.jquery.com/topic/responsive-image-resizing-that-fills-the-browers-window

