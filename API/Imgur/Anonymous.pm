package API::Imgur::Anonymous;

use strict;
use warnings;
use Carp;
use HTTP::Request;
use LWP::UserAgent;
use JSON::XS qw(decode_json);
use Data::Dumper;

my $API_BASE = "https://api.imgur.com/3/";

# Initialize
sub new 
{
    my $class = shift;
    my $self = { 
                    parse => shift,
               };
    bless $self, $class;
    return $self;
}

# Authenticate with imgur API
sub ident 
{
    my $self = shift;
    my $client_id = shift;
    
    $self->{"client_id"} = $client_id;
    return $self;
}

# Start the useragent
sub agent
{
    my ($self) = @_;
    bless $self;
    return LWP::UserAgent->new;  
}

sub make_request
{
    my ($self, @opts) = @_;
    my $qstring = join("/", @opts);
    my $request = HTTP::Request->new(GET => "$API_BASE/$qstring");
       $request->header("Authorization" => "Client-ID $self->{client_id}");
    my $raw;
    if ($self->{parse}) {
        $raw = $self->agent->request($request);
        my $decoded = decode_json($raw->content) or croak "ERROR: $!";
        return $decoded;
    } else {
        return $self->agent($request);
    }
}

sub album
{
    my ($self, $album_id) = @_;
    unless ($album_id) {
        croak "ERROR: Valid imgur album ID required";
        return;
    } 
    return $self->make_request("album", $album_id);
}

sub image
{
    my ($self, $image_id, $opt) = @_;
    unless ($image_id) {
        croak "ERROR: Valid imgur image ID required";
        return;
    } 
    return $self->make_request("image", $image_id);
}

sub account
{
    my ($self, $username, $opt) = @_;
    unless ($username) {
        croak "ERROR: Valid imgur account name required";
        return;
    }

    if ($opt) {     
        return $self->make_request("account", $username, $opt); 
    } else {
        return $self->make_request("account", $username);
    }
    
}

1;
