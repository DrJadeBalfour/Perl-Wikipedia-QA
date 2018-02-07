#!/usr/bin/perl
#Robert Trachy
#CMSC 416 Assignment 6
#Due Monday, May 1, updated Thursday, May 4 to deal with potential Linux-Windows errors

#Enhancement 1 to Query Reformulation:
#Uses the Named Entity Recognizer on some of the questions to determine the search term. 
#Enhancement 2 to Query Reformulation:
#On instances where NER is less useful, such as places or objects, a manual regex matching was used.
#Enhancement 2 to Query Reformulation:
#Remove "the" from search term if nothing is found in Wikipedia.
#Enhancement 1 to Answer Composition:
#The resulting Wikipedia articles are separated into sentences, which can then be looked through.
#Enhancement 2 to Answer Composition:
#If a direct answer isn't found/a more in depth answer is needed, the article is searched for words about the topic.
#The rank given to answers is dependent on the type of question/context.
#If it is a question of a place being founded or a person being born, the first date in the article has the highest rank.
#If it is a question on someone's death, the second date has the highest rank.
#Location questions give the highest rank to the first location.
#Who and what questions assign rank if the sentences have a keyword and if the top sentence does not contain too much information, the next highest is added on.

#This assignment revolved around building an enhanced version of a QA system using Wikipedia.  The user asks a question, then some parsing is done on the input.  
#This is then searched in Wikipedia.  Then an answer is built depending on what the question was.  If nothing is found, the system outpus so.
#This can be run on the command line with one arguement for a logfile.
#Example input and output:
#In: Where is The Lourve?
#Out: Louvre is located in Paris, France.
#In: When did Abraham Lincoln die?
#Out: When did Abraham Lincoln die?
#In: What is Burn Notice?
#Out: Burn Notice is an American television series created by Matt Nix which originally aired on the USA Network from June 28, 2007 to September 12, 2013 and were produced and released in JanuaryApril 2011.
#The system looks at the question word and then goes to the matching function.  What, when, and where all use the same Wikipedia search and result formatting while who has something similar. (it was written before and I did not want to mess it up)
#Who and what look for sentences with keywords and tries to combine them.  When looks for dates, picking the first one that matches the assumed order (1st born, 2nd death, with the rest hoping to match a keyword).  
#Where tries to find a location in City, Country form.  In general, the rank is just the first option unless a specific context is decided.

#I used the OpenNLP Person NER as well as their sentence detector. If there are issues running this, the uses are on lines 85, 155, 257, 371, 406, 488.

use WWW::Wikipedia; #Wikipedia module
$filename = $ARGV[0]; #log file name
open (OUT, ">",$filename); #Open output file
## Default: English
$wiki = WWW::Wikipedia->new( clean_html => 1 ); #I was having issues with wide characters, this never solved it but I just left it in.

<>; #User input wouldnt work without this being here.
#I've finally started to use subroutines.  
print "This is a Question and Answering system designed by Robert Trachy.  It attempts to answer simple Who, What, When, and Where questions via Wikipedia.\n";
print "What would you like to ask? (type 'exit' to exit)\n";
while (<>) {
	chomp $_;
	@out;
	%possib =();
	if($_ =~ /^exit\b/i) { #Say exit to exit
		exit;
	}
	else {
		#Find the question type to search through
		print OUT "$_\n";
		$_ =~ s/\?//;
		$_ =~ s/\'s//;
		$_ =~ /(\w+).*/;
		$ques = $1;
		if($ques  =~ /who/i) {
			WHO ($_);
		}
		elsif($ques  =~ /when/i) {
			WHEN ($_);
		}
		elsif($ques =~ /what/i) {
			WHAT ($_);
		}
		elsif($ques =~ /where/i) {
			WHERE ($_);
		}
		else {
			print "I'm sorry, I do not understand the question.\n";
		}
	}
}

sub WHERE { 
	$line = $_[0];
	open (DST, ">","tempi.txt"); #User question
	print DST "$line";
	#system ("opennlp.bat TokenNameFinder en-ner-person.bin <tempi.txt> tempo.txt"); #These models in general do not seem to work for a lot of my queries. And from asking around, what counts as a 'person' varies from system to system.
	system ("opennlp TokenNameFinder en-ner-person.bin <tempi.txt> tempo.txt"); 
	close DST;
	open (SRC, "tempo.txt"); #NER returned
	$line = <SRC>;
	close SRC;
	chomp $line;
	$line =~ s/(is|was|did|were) //i;
	$line =~ s/where //i;
	$search = $line;
	$extra ="";
	$temp = $line;
	if($line =~ /(\b[a-z]\w+)$/) {
		$extra =$1;
		$line =~s/\b[a-z]\w+$//;
		$search = $line;
	}
	if($search eq"") {
		$search = $temp;
	}
	chomp $search;
	$entry = $wiki->search($search);
	if(!$entry) {
		$search =~ s/^(an? |the )//i;
		$entry = $wiki->search( $search );
	}
	if($entry) {
		$entry = $wiki->search($search);
		print OUT "$search\n";
		PRE();
		$rank = 1;
		if($extra ne "") {
			$extra =! s/(\w+)(ed|s|'s|)/$1/i;
		}
		foreach $line (@text) { 
				@temp = split/ /, $line;
				if($extra eq "") {
					if($line =~ /[A-Z]\w+, \b[A-Z]\w+\b/) {
						$line =~ s/.*([A-Z]\w+, \b[A-Z]\w+\b).*/$1/;
						$possib{$rank} = $line;
						print OUT "$rank $line\n";
						$rank -= 1/$#text;
					}		
				}
				elsif($extra ne "" && $line =~ /$extra/i && $line =~ /([A-Z]\w+, \b[A-Z]\w+\b)/) {
					$possib{$rank} = $1;
					print OUT "$rank $line\n";
					$rank -= 1/$#text;
				}
			}
			if(keys %possib <1) {
				print "I'm sorry, nothing was found.\n";
				print OUT "I'm sorry, nothing was found.\n";
			}
			else {
				print "$title is located in $possib{1}.\n";
				print OUT "$title is located in $possib{1}.\n";
			}
		}
	else {
		print "I'm sorry, I do not understand the question.\n";
		print OUT "I'm sorry, I do not understand the question.\n";
	}	
}

#Similar to WHO, tries to combine two sentences.
sub WHAT {
	$line = $_[0];
	open (DST, ">","tempi.txt"); #User question
	print DST "$line";
	#system ("opennlp.bat TokenNameFinder en-ner-person.bin <tempi.txt> tempo.txt");
	system ("opennlp TokenNameFinder en-ner-person.bin <tempi.txt> tempo.txt"); 
	close DST;
	open (SRC, "tempo.txt"); #NER returned
	$line = <SRC>;
	close SRC;
	chomp $line;
	$line =~ s/(is|was|did|were) //i;
	$line =~ s/what //i;
	$search = $line;
	$temp = $line;
	$extra ="";
	if($line =~ /(\b[a-z]\w+)$/) {
		$extra =$1;
		$line =~s/\b[a-z]\w+$//;
		$search = $line;
	}
	if($search eq "") {
		$search = $temp;
	}
	chomp $search;
	$entry = $wiki->search($search);
	if(!$entry) {
		$search =~ s/^(an? |the )//i;
		$entry = $wiki->search( $search );
	}
	if($entry) {
		$entry = $wiki->search($search);
		print OUT "$search\n";
		PRE();
		$rank = 1;
		if($extra ne "") {
			$extra =! s/(\w+)(ed|s|'s|)/$1/i;
		}
		foreach $line (@text) { 
			@temp = split/ /, $line;
			if($extra eq "") {
				if($line =~ /\b(is|was|were|are)\b/i) {
					$line =~ s/\b(is|was|were|are)\b(.*)/$1$2/i;
					$possib{$rank} = $line;
					print OUT "$rank $line\n";
					$rank -= 1/$#text;
				}		
			}
			elsif($extra ne "" && $line =~ /$extra/i) {
				$possib{$rank} = $line;
				print OUT "$rank $line\n";
				$rank -= 1/$#text;
			}
		}
		if(keys %possib <1) {
			print "I'm sorry, nothing was found.\n";
			print OUT "I'm sorry, nothing was found.\n";
		}
		$n=0;
		AAGAIN:
		$c=1;
		foreach $line (sort {$possib{$b} <=> $possib{$a}} keys %possib) {
			if($c==1 ){
				#print "1 $possib{$line}\n";
				$possib{$line} =~ /\b(were|is|was)\b(.*)/;
				$part1=$1;
				$part1.=$2;
				$c++;
				delete $possib{$line};
			}
			elsif($c==2) {
				$possib{$line} =~ /\b(were|is|was)\b(.*)/;
				$part2 =$1;
				$part2 .=$2;
				$c++;
			}
		}
		@ans = split/ /, $part1;
		$ans = "";
		$ans .= $title;
		$ans .= " ";
		$ans .= $part1;
		if($#ans <=25) {
			$ans =~ s/\.$//;
			$ans .= " and ";
			$ans .= $part2;
		}
		$n++;
		if($ans eq " " && $n==0) {
			goto AAGAIN;
		}
		print "$ans\n";
		print OUT "$ans\n";
	}
	else {
		print "I'm sorry, I do not understand the question.\n";
		print OUT "I'm sorry, I do not understand the question.\n";
	}
}

#WHEN focuses on dates in the sentences, only pointing out the sentences with a date.

sub WHEN { #The opennlp date module seemed rather useless, at least for me.  It kept splitting dates or combining them.  For instance, Napolean's lifespan would be "15 <START: date> August 1769 5 May 1821 <END>.  US format was equally poor.
	$line = $_[0];
	open (DST, ">","tempi.txt"); #User question
	print DST "$line";
	#system ("opennlp.bat TokenNameFinder en-ner-person.bin <tempi.txt> tempo.txt"); 
	system ("opennlp TokenNameFinder en-ner-person.bin <tempi.txt> tempo.txt"); 
	close DST;
	open (SRC, "tempo.txt"); #NER returned
	$line = <SRC>;
	close SRC;
	$line =~ s/(is|was|did|were) //;
	#print "$line\n";
	if($line =~ /person\>(.*)\</ || $line=~/when (.*) \w+/i) {
		$search = $1;
		$entry = $wiki->search($search);
		#exit;
		if($entry) {
			print OUT "$search\n";
			PRE();
			@filtl =();
			@filtd =();
			foreach $line (@text) { #My makeshift date finder, only gets complete dates, no partials.  
				MULT:
				@temp = split/ /, $line;
				#print "$line\n";
				if($#temp <= 7) {
					next;
				}
				if($line =~ /(\d+ (january|february|march|april|may|june|july|august|september|october|november|december) \d+)/i) {
					push (@filtl, $line);
					push (@filtd, $1);
					$line =~s/(\d+ (january|february|march|april|may|june|july|august|september|october|november|december) \d+)//i;
				}
				elsif($line =~ /((january|february|march|april|may|june|july|august|september|october|november|december) \d+, \d+)/i) {
					push (@filtl, $line);
					push (@filtd, $1);
					$line =~s/((january|february|march|april|may|june|july|august|september|october|november|december) \d+, \d+)//i
				}
				else {
					next;
				}
				goto MULT;
			}
			$found =0;
			$title =~ s/\%20/ /g;
			#With the way Wikipedia works, the first and second dates are when the person is born and when they die.  If that is not part of the question, then this attempts to search for is.
			if($#filtd==-1) {
				print "I'm sorry, nothing was found.\n";
				print OUT "I'm sorry, nothing was found.\n";
			}
			elsif($line =~ /\>?\s*(born|birthday)/i && $#filtd!=-1) {
				$n=1;
				for($i=0;$i<=$#filtd;$i++) {
					print OUT "$n $filtd[$i]\n";
					$n = $n-1/($#filtd+1);
				}
				print "$title was born on $filtd[0].\n";
				print OUT "$title was born on $filtd[0].\n";
			}
			elsif($line =~/\>?\s*(die|died|death|croaked|passed away)/i && $#filtd>0) {
				$n=1-1/$#filtd;
				for($i=0;$i<=$#filtd;$i++) {
					if($i!=1) {
						print OUT "$n. $filtd[$i]\n";
					}
					else {
						print OUT "1. $filtd[$i]\n";
					}
					$n = $n-1/($#filtd-1);
				}
				print "$title died on $filtd[1].\n";
				print OUT "$title died on $filtd[1].\n";
			}
			elsif($line =~/\>?\s*(create|form|start|found)/i && $filtd>0) { #If the extra search term is in the sentence, count it
				print "$title was formed on $filtd[0].\n";
				print OUT "$title was formed on $filtd[0].\n";
			}
			elsif($line =~/\>?\s*([a-z]\w*)/ && $filtd>-1) {
				$n=1;
				for($i=0;$i<$#filtd;$i++) {
					$n = $n-1/$#filtd;
						print OUT "$n. $line.\n";					
				}
				$line=~s/\>?\s*([a-z]\w*)/$1/;
				foreach $sent (@filtl) {
					if($sent =~ /$line/) {
						print "$sent.\n";
						print OUT "$sent.\n";
						last;
					}
				}
				if($found ==0) {
					print "I'm sorry, nothing was found.\n";
					print OUT"I'm sorry, nothing was found.\n";
				}
			}
			else {
				print "I'm sorry, nothing was found.\n";
				print OUT "I'm sorry, nothing was found.\n";
			}
		}
		else {
			print "I'm sorry, nothing was found under that name.\n";
			print OUT "I'm sorry, nothing was found under that name.\n";
		}
	}
	else {
		print "I'm sorry, I do not understand the question.\n";
		print OUT "I'm sorry, I do not understand the question.\n";
	}
}


#WHO was written first, with the rest using the same idea, but relying on a different subroutine to set up the text used.
sub WHO {
	$line = $_[0];
	open (DST, ">","tempi.txt"); #User question
	print DST "$line";
	#system ("opennlp.bat TokenNameFinder en-ner-person.bin <tempi.txt> tempo.txt");
	system ("opennlp TokenNameFinder en-ner-person.bin <tempi.txt> tempo.txt"); 
	close DST;
	open (SRC, "tempo.txt"); #NER returned
	$line = <SRC>;
	close SRC;
	$line =~ s/^who //i;
	$search ="a";
	if( $line =~ /person\>\s(.+)\s\</) {
		$search = $1;
	}
	if($search =~ /^a\b/) {
		$line =~ /\w+ (.*)/;
		$search = $1;
	}
	if($search ne "") {
		$entry = $wiki->search($search);
	}
	if(!$entry) {
		$search =~ /(.*) \w+/;
		$search = $1;
		$entry = $wiki->search( $search );
		
	}
	if($entry) {
		print OUT "$search\n";;
		$temp = ($entry->text());
		$title = ($entry->title());
		$title =~ s/\%20/ /g;
		$temp =~ s/[^[:ascii:]]+//g;
		$temp =~ s/\n/ /g;
		$temp =~ s/  / /g;
		$temp =~ s/^\s+//;
		open (DST, ">","tempi.txt"); #User question
		print DST "$temp";
		#system ("opennlp.bat SentenceDetector en-sent.bin <tempi.txt> tempo.txt");
		system ("opennlp SentenceDetector en-sent.bin <tempi.txt> tempo.txt");
		close DST;
		open (SRC, "tempo.txt"); #NER returned
		@text =();
		while ($temp =<SRC>) {
			chomp $temp;
			push (@text,$temp);
		}
		close SRC;
		$rank = 1;
		%possib= ();
		$title =~ /.*([A-Z]\w+)/;
		$name = $1;
		for($i=0;$i<=$#text;$i++) {
			print OUT "$text[$i]\n";
			#print "$text[$i]\n";
			if($text[$i] =~ /\b(were|was|is)\b/ ) {
				#if(!$text[$i] =~ /(\||\'|\;)/) {
					$possib{$rank} = $text[$i];
					#print "$rank $text[$i]\n";
					$rank -= 1/$#text;
				#}
			}
		}
		$n=0;
		$part2="";
		$part1 ="";
		AGAIN: #Attempt to build a sentence out of the results.
		$c =1;
		foreach $line (sort {$possib{$b} <=> $possib{$a}} keys %possib) {
			if($c==1 ){
				#print "1 $possib{$line}\n";
				$possib{$line} =~ /\b(were|is|was)\b(.*)/;
				$part1=$1;
				$part1.=$2;
				$c++;
				delete $possib{$line};
			}
			elsif($c==2) {
				$possib{$line} =~ /\b(were|is|was)\b(.*)/;
				$part2 =$1;
				$part2 .=$2;
				$c++;
			}
		}
		@ans = split/ /, $part1;
		$ans = "";
		$ans .= $title;
		$ans .= " ";
		$ans .= $part1;
		if($#ans <=25 && $part2 ne "") {
			$ans =~ s/\.$//;
			$ans .= " and ";
			$ans .= $part2;
		}
		$n++;
		if($ans eq "" && $n==0) {
			goto AGAIN;
		}
		print "$ans\n";
		print OUT "$ans\n";
	}
	else {
		print "I'm sorry, nothing was found by that name.\n";
		print OUT "I'm sorry, nothing was found by that name.\n";
	}
}

sub PRE {
	$temp = ($entry->text());
	$title = ($entry->title());
	$title =~ s/\%20/ /g;
	$temp =~ s/[^[:ascii:]]+//g;
	$temp =~ s/\n/ /g;
	$temp =~ s/  / /g;
	$temp =~ s/^\s+//;
	$temp =~ s/(.+\}\}.*?\s+')//;
	#print "$1\n\n\n";
	open (DST, ">","tempi.txt"); #User question
	print DST "$temp";
	close DST;
	#system ("opennlp.bat SentenceDetector en-sent.bin <tempi.txt> tempo.txt");
	system ("opennlp SentenceDetector en-sent.bin <tempi.txt> tempo.txt");
	open (SRC, "tempo.txt"); #NER returned
	@text =();
	while ($temp =<SRC>) {
		chomp $temp;
		push (@text,$temp);
		print OUT "$temp\n";
	}
	close SRC;
}