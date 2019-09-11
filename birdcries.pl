#!/usr/bin/env perl

package birdcries;

# ----------------------------------------------------
# This is the birdcries service.
# It provides a no-bullshit UI to view single tweets
# from a certain bird-themed website.
#
# https://birdcries.net
# ----------------------------------------------------

use strict;
use warnings;
use utf8;
use feature ':5.10';

use Twitter::API;
use Mojolicious::Lite;
use Try::Tiny;
use File::Util::Tempdir qw(get_tempdir);

# ----------------------------------------------------
# Twitter setup
# ----------------------------------------------------

our %conf;
require "./config.pl";

our $client = Twitter::API->new_with_traits(
    traits              => 'Enchilada',
    consumer_key        => $conf{'consumer_key'},
    consumer_secret     => $conf{'consumer_secret'},
    access_token        => $conf{'access_token'},
    access_token_secret => $conf{'access_token_secret'}
);

try {
    my $r = $client->verify_credentials;
}
catch {
    # Could not log in. :-(
    die $_ unless is_twitter_api_error($_);
 
    say $_->http_request->as_string;
    say $_->http_response->as_string;

    if ( $_->is_token_error ) {
        say "There's something wrong with this token."
    }
    if ( $_->twitter_error_code == 326 ) {
        say "Twitter thinks we're a spam bot.";
    }
};

# ----------------------------------------------------
# Caching
# ----------------------------------------------------

my $cachedir = get_tempdir();
if (defined $conf{'cachedir'}) {
    $cachedir = $conf{'cachedir'};
}

plugin 'CHI' => {
  Birdcries => {
    driver   => 'File',
    root_dir => $cachedir
  }
};

# ----------------------------------------------------
# Routing
# ----------------------------------------------------

get '/' => sub {
    # This is the default "home" page.
    # Display general information:
    my $c = shift;
    
    $c->stash(sitetitle => $conf{'sitetitle'});
    $c->stash(sitedom   => $conf{'sitedomain'});
    
    $c->render(template => 'start');
};

get '/:name/status/:id' => sub {
    # Actually open a tweet (with a certain ID).
    my $c = shift;
    my $id = $c->stash('id');
    my $name = $c->stash('name');
    
    my $tweet;
    my $retval;
    
    if ($conf{'use_cache_files'} == 1 && defined $c->chi('Birdcries')->get($id)) {
        # Save some time (and API calls), don't fetch tweets twice.
        $retval = $c->chi('Birdcries')->get($id);
        
        # Store the value for debug reasons:
        $c->stash(was_cached => 1);
    }
    else {
        my ($result, $context) = $client->show_status({
            id => $id,
            include_card_uri => 0,
            tweet_mode => 'extended'
        });
        
        if ($conf{'use_cache_files'} == 1) {
            # Only store the result if caching is not turned off.
            $c->chi('Birdcries')->set($id => $result);
        }
        
        $c->stash(was_cached => 0);
        $retval = $result;
    }
    
    if ($conf{'display_avatars'} == 1) {
        # The administrator wants us to fetch avatar pictures.
        $c->stash(avatar => $retval->{user}{profile_image_url_https});
    }
    else {
        $c->stash(avatar => "");
    }
    
    if (defined $retval->{full_text}) {
        # 280-character tweet detected.
        $tweet = $retval->{full_text};
    }
    else {
        $tweet = $retval->{text};
    }
    
    # URL handling:
    # Find long ("expanded") URLs, use them wisely.    
    if (defined $retval->{entities}->{urls}) {
        foreach my $url (@{$retval->{entities}->{urls}}) {
            my ($shorturl, $longurl) = map { $url->{$_} } qw(url expanded_url);
            
            # Replace <url> by <expanded_url> in our tweet text.
            $tweet =~ s/$shorturl/$longurl/g;
        }
    }
    
    if ($conf{'auto_link_href'} == 1) {
        # We add <a href> around valid HTTP(S) URLs.
        $tweet =~ s/((http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/[^\s]*)?)/<a href="$1" target="_blank">$1<\/a>/g;
    }
    
    $c->content_for(tweet => $tweet);
    
    $c->stash(author    => $name);
    $c->stash(authordisplay => $retval->{user}{screen_name});
    $c->stash(datetime  => $retval->{created_at});
    $c->stash(tweetid   => $id);
    
    $c->stash(sitetitle => $conf{'sitetitle'});
    $c->stash(sitedom   => $conf{'sitedomain'});
    
    $c->stash(use_cache => $conf{'use_cache_files'});
    
    $c->render(template => 'tweet');
};

app->start;