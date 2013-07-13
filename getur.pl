#!/usr/bin/env perl -w
#
#
#   TODO:
#   -----
#   - Use moose
#   - Use getopts
#   - Make subs:
#       + Progress
#       + Success
#       + Fail
#     That output ↪ ✓ ✘ respectively
#   - Get user:
#       + Then ask what to do. Download all albums?
#

use strict;
package Files;

use 5.014;

# Custom libraries
use API::Imgur::Anonymous;

# CPAN
use JSON::XS qw(decode_json);
use File::Path qw(make_path);
use v5.14;

# Autoflush on
$|=1;

my @errors          = ('400', '401', '403', '404', '429', '500');
my @types           = ('album', 'image');
my $default_prompt  = "↪";
my $default_success = "✓";
my $default_fail    = "✘";

sub get
{
    my $target = shift;
    my $type = shift;
    my $subpath = shift;
            
    print $default_prompt, " ", $target->{id};
    
    my $total = 1;
    $total = scalar @{ $target->{images} } if $target->{images};
    say " ($total)";
    
    if ($target->{images}) {
        while (my($id, $img) = each @{ $target->{images} }) {
            download($target->{id}, $img->{id}, $img->{link}, $id, $total, $subpath);
        }
    } else {
            download($target->{id}, $target->{id}, $target->{link}, 0, $total, $subpath);
    }
    say "\e[A$default_success Grabbed ($total/$total)\e[K";
}

sub download 
{
    my $album = shift;
    my $id = shift;
    my $image = shift;
    my $current = (shift) + 1;
    my $total = shift;
    my $subpath = shift;
    
    say "\e[A$default_prompt $id ($current/$total)";
    
    # Add leading zeroes for formatting
    my $alz = sprintf("%0".length($total)."d", ($current));
    # Grab the HREF 
    # Split URL so we get the filename only.
    my $removeqm = (split "/", $image)[-1];
    # imgur likes to append '?1' to the filename for some reason; let's
    # trim it.
    $removeqm =~ s/\?.*//;
    my $local_file = ($total == 1) ? join('/', $subpath, "$removeqm") : join('/', $subpath, $album, "$alz-$removeqm");
    make_path(join('/', $subpath, $album)) unless (-e $local_file or $total == 1);
    
    my $ua = LWP::UserAgent->new(  );

    # Open fh for writing
    open (PIC,">$local_file") or die "Couldn't open $local_file: $!";
    # Let's get that file. Pass chunks to callback sub
    my $response = $ua->get($image, ':content_cb' => \&callback );
    # And we're done.
    close (PIC);
    
}

sub callback {
    my ($data, $response, $protocol) = @_;
    # Print chunks to file.
    print PIC $data;
}

package main;
        
# Initialize the API library
my $imgur = API::Imgur::Anonymous->new("json");

# Give it our app's ident code
# (necessary for authenticating with imgur API)
$imgur->ident("37d87caf158e8a4");
        
given (scalar @ARGV) {
    when (0) { no_args() }
    default  { args(@ARGV) }
}

# check if the id supplied even exists on imgur, and what type it is
sub check_validity {
    my $id = shift;
    my $handler = shift;
    
    foreach (@types) {
        # check if numbers are in the error loop.
        unless ($handler->$_($id)->{status} ~~ @errors) {
            return $_, $handler->$_($id)->{data};
        }
    }
    
    # if we make it this far, we're SOL.
    die "$default_fail '$id' just doesn't exist on imgur, man. $default_prompt";
}

# prompt function
sub prompt {
    my $input = shift;
    my $prompt = shift // $default_prompt;
    print "$prompt $input: ";
    chomp(my $line = <STDIN>);
    return $line;
}

# if we haven't been supplied with args
sub no_args 
{
    # take input
    while (1) {
        my $id = prompt("Gimme an ID");
        my ($response, $imgur) = check_validity($id, $imgur);
        
        if ($ARGV[1]) { Files::get($imgur, $response, $ARGV[1]) }
        else { Files::get($imgur, $response, ".") }
        
        exit 0;
    }   
}

# if we've been supplied with command-line args
sub args {
    my $id = shift;
    say "$default_prompt $ARGV[0] ...";
    my ($response, $imgur) = check_validity($id, $imgur);
    say "\e[A$default_success $ARGV[0] is $response";
    
    if ($ARGV[1]) { Files::get($imgur, $response, $ARGV[1]) }
    else { Files::get($imgur, $response, ".") }
}