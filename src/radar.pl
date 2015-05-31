$| = 1;

my @data;
my $lineCount = 0;
open(FILE, "radarData.csv")||die;
while(my $line = <FILE>)
{
	$lineCount++;
	push(@data, $line);
}
close FILE;


while(1)
{
	sleep(int(rand(10)));

	my $lineToShow = int(rand($lineCount));

	print "$data[$lineToShow]";
}
