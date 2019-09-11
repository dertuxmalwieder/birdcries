#!/usr/bin/env perl

# ----------------------------------------------------
# This is the birdcries service.
# It provides a no-bullshit UI to view single tweets
# from a certain bird-themed website.
#
# https://birdcries.net
# ----------------------------------------------------

our %conf = (

# ----------------------------------------------------
# General stuff
# ----------------------------------------------------

# Used for the header and the start site:
sitetitle           => 'b i r d c r i e s',
sitedomain          => 'birdcries.net',

# While birdcries will never show files attached to an
# original tweet, it can automatically add <a href>
# around URLs in said tweet, including (but not limited
# to) those which contain the attachments. Set this value
# to 0 if you don't want us to.
auto_link_href      => 1,

# ----------------------------------------------------
# Privacy
# ----------------------------------------------------

# Should we fetch and display avatar pictures from Twitter?
display_avatars     => 1,

# ----------------------------------------------------
# Caching
# ----------------------------------------------------

# Enables a file-based cache (you'll need some free space).
# This is highly recommended to avoid running into Twitter's
# artificial API limitations: You can fetch max. 1 tweet per
# second.
use_cache_files     => 1,

# By default, birdcries uses your system's tempdir to store
# its cache. If you prefer to set a different path, you'll
# need to uncomment the following line and adjust its value.
# cachedir            => '/temp',

# ----------------------------------------------------
# Twitter setup
# ----------------------------------------------------

# Register a new application with Twitter and put its tokens here:
consumer_key        => '',
consumer_secret     => '',
access_token        => '',
access_token_secret => '',

# ----------------------------------------------------
# That's it.
# ----------------------------------------------------

);