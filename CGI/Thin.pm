#!/usr/local/bin/perl

package CGI::Thin;
use strict;

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK);
	$VERSION = 0.41;
	@ISA		= qw (Exporter);
	@EXPORT		= qw (
					  &Parse_CGI
					 );
	@EXPORT_OK	= qw (
					  &Force_Array
					 );
}

END { }

################################################ subroutine header begin ##
=pod
=head2 Parse_CGI
=over 4
=item SUBROUTINE:
Parse_CGI
=item INPUT:
none
=item OUTPUT:
%hash			all data from CGI form sent into script
=item GLOBALS USED:
%ENV
=item FUNCTIONS CALLED:
none
=item DESCRIPTION:
Collect all pairs of CGI inputs and return them in a hash for processing
=item HISTORY:
	Steven E. Brenner (1993)
	- wrote CGILIB.pl, original available from...
     http://cgi-lib.stanford.edu/cgi-lib/
	Craig R. Meyer (7/5/95)
	- Optimized ReadParse(), Use read() not getc(), don't use subscripts
	R. Geoffrey Avery (12/18/98)
	- changed to Parse_CGI and now returns the hash not the size of the hash
	  and has no input pointer to the hash
	R. Geoffrey Avery (4/22/99)
	- now can handle multipart forms and read in files
	- also changed multiple entries in one name, now returns an array of values
=back
=cut
################################################## subroutine header end ##

sub Parse_CGI () {

	my(
	   $i, $loc, $key, $val, $in, @args,
	   %hash, $boundary, $firstval, 
	  );

	%hash = ();
	
	unless ((defined $ENV{'CONTENT_TYPE'}) &&
			($ENV{'CONTENT_TYPE'} =~ m|multipart/form-data|si)) {
		# Read in text
		if( $ENV{'REQUEST_METHOD'} eq "GET" ){
			$in = $ENV{'QUERY_STRING'};
		} elsif( $ENV{'REQUEST_METHOD'} eq "POST" ){
			read(STDIN, $in, $ENV{'CONTENT_LENGTH'});
		} 

		@args = split(/&/,$in);
		
		foreach $i (@args) {
			# Convert plus's to spaces
			$i =~ s/\+/ /g;
			# Convert %XX from hex numbers to alphanumeric
			$i =~ s/%(..)/pack("C",hex($1))/ge;

			# Split into key and value.
			$loc = index($i,"=");
			$key = substr($i,0,$loc);
			$val = substr($i,$loc+1);

			if ( defined($hash{$key})) {
				unless (ref ($hash{$key}) eq "ARRAY") {
					$firstval = $hash{$key};
					$hash{$key} = [$firstval];
				}
				push (@{$hash{$key}}, $val);
			} else {
				$hash{$key} = $val;
			}
		} # foreach
							  
	} else {
		my ($head, $item, $name, $file);
		read(STDIN, $in, $ENV{'CONTENT_LENGTH'});

		### Find the field "boundary" string.
		$boundary = substr($in, 0, index($in, "\r\n") - 1);
		
		### Tokenize the input.
		@args = split(/\s*$boundary\s*/s, $in);
		
		### Iterate over the tokens...
		foreach (@args[1..$#args - 1]) {

			# Split the token into header and content
			($head, $item) = split(/\r\n\r\n/ios, $_, 2);

			# ... name="CGI_FILE" filename="myfile.txt" ....
			# so this is a bit of a trick, based on the double
			# occurence of 'name'.
			($name, $file) = ($head =~ /name="(.*?)"/gios);

			my $mimetype;
			if ($head =~ /Content-type:\s*(\S+)/gios) {
				$mimetype = $1;
			}
			# Build the hash.
			$hash{$name} = $file ? { 
				### If a filename was specified, store a hash
				"Name"		=> $file,
				"Content"	=> $item,
				"MIME_Type"	=> $mimetype || 'unknown mime type',
				"head"		=> $head,
				} 
				### Otherwise just store the value.
				: $item;
		} # foreach
							  
	}

	foreach (@_) {
		$hash{$_} = &Force_Array ($hash{$_}) if ($hash{$_});
	}

	return (%hash);

} # Parse_CGI

################################################ subroutine header begin ##
################################################## subroutine header end ##

sub Force_Array
{
	my ($item) = @_;

	$item = [$item] unless( ref($item) eq "ARRAY" );

	return ($item);
}

###########################################################################
###########################################################################
###########################################################################
###########################################################################

1;

__END__
