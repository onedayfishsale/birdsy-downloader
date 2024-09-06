#!/usr/bin/perl -w

use strict;
no warnings 'once';

use Getopt::Long;
use LWP::UserAgent; 
use LWP::Simple;
use JSON::PP;

require '/tmp/birdsy-dev/config.ph';

my $action = 'none';
my $date;

sub usage {
  my $command = $0;
  $command =~ s,^.*/,,;

  print STDERR (
    "usage: $command --action=<action> --date=<YYYY-MM-DD>\n"
  );

  die("\n")
}

GetOptions(
  'action=s' => \$action,
  'date=s'   => \$date
) or usage();

$date .= "T00:00:00";

sub getAuthToken {
  my $email   = shift(@_);
  my $password = shift(@_);

  my $data = {
    'email'      => $email,
    'grant_type' => 'password',
    'password'   => $password
  };
  my $payload = encode_json($data);

  my $birdsy = HTTP::Request->new(
    POST => 'https://birdsy.com/api/v1/auth'
  );
  $birdsy->content($payload);
  $birdsy->header('Content-Type' => "application/json");

  my $ua = LWP::UserAgent->new();
  my $res = $ua->request($birdsy);

  if ($res->is_success) {
    my $data = decode_json($res->content());
    return $data->{'data'}{'attributes'}{'token'};
  } else {
    if (my $message = decode_json($res->content())->{'message'}) {
      print "$message\n";
    }
    die $res->status_line;
  }
}

sub getSpecies {
  my $token = shift(@_);
  my $id    = shift(@_);

  my @species = ();

  my $birdsy = HTTP::Request->new(
    GET => "https://birdsy.com/api/v1/episodes/$id/birds"
  );
  $birdsy->header('authorization' => $token);
  $birdsy->header('Accept'        => 'application/json');

  my $ua = LWP::UserAgent->new();
  my $res = $ua->request($birdsy);

  if ($res->is_success) {
    my $json = decode_json($res->content());
    for my $data (@{$json->{'data'}}) {
      push @species, $data->{'attributes'}{'name'};
    }
  }

  return \@species;
}

sub getAllVideoCounts {
  my $token = shift(@_);

  my $birdsy = HTTP::Request->new(
    GET => 'https://birdsy.com/api/v2/episodes/days'
  );
  $birdsy->header('authorization' => $token);
  $birdsy->header('Accept'        => 'application/json');

  my $ua = LWP::UserAgent->new();
  my $res = $ua->request($birdsy);

  if ($res->is_success) {
    my $days = decode_json($res->content());
    return @{$days->{'meta'}{'days'}};
  } else {
    if (my $message = decode_json($res->content())->{'message'}) {
      print "$message\n";
    }
    die $res->status_line;
  }
}

sub getVideoCountForDate {
  my $token = shift(@_);
  my $date  = shift(@_);

  my $birdsy = HTTP::Request->new(
    GET => 'https://birdsy.com/api/v2/episodes/days'
  );
  $birdsy->header('authorization' => $token);
  $birdsy->header('Accept'        => 'application/json');

  my $ua = LWP::UserAgent->new();
  my $res = $ua->request($birdsy);

  if ($res->is_success) {
    my $days = decode_json($res->content());

    my $count = 0;
    if (my ($day) = grep {$_->{'date'} eq $date} @{$days->{'meta'}{'days'}}) {
      $count = $day->{'count'};
    }
    return $count;
  } else {
    if (my $message = decode_json($res->content())->{'message'}) {
      print "$message\n";
    }
    die $res->status_line;
  }
}

sub getAllVideosForDate {
  my $token = shift(@_);
  my $date  = shift(@_);

  my @videos;
  my $page = 1;

  my $total = getVideoCountForDate($token, $date);

  while (scalar @videos < $total) {
    my $birdsy = HTTP::Request->new(
      GET => 'https://birdsy.com/api/v2/episodes?page=' . $page . '&date=' . $date
    );
    $birdsy->header('authorization' => $token);
    $birdsy->header('Accept'        => 'application/json');
  
    my $ua = LWP::UserAgent->new();
    my $res = $ua->request($birdsy);
  
    if ($res->is_success) {
      my $json = decode_json($res->content());
      push @videos, @{$json->{'data'}};
    } else {
      next;
    }

    $page++;
  }
  return \@videos;
}

sub deleteVideoById {
  my $token = shift(@_);
  my $id    = shift(@_);

  my $data = {
    'ids' => [$id]
  };
  my $payload = encode_json($data);

  my $birdsy = HTTP::Request->new(
    POST => 'https://birdsy.com/api/v2/episodes/group_actions/delete'
  );
  $birdsy->header('authorization' => $token);
  $birdsy->content($payload);
  $birdsy->header('Content-Type' => "application/json");

  my $ua = LWP::UserAgent->new();
  my $res = $ua->request($birdsy);

  if ($res->is_success) {
    return decode_json($res->content());
  } else {
    return -1;
  }
}

# get auth token
#
my $token = getAuthToken($main::BIRDSY_EMAIL, $main::BIRDSY_PASSWORD);

# bulk action mode
#
if ($action eq 'sync') {
  foreach my $day (reverse(getAllVideoCounts($token))) {
    print "Syncing $day->{'count'} videos for $day->{'date'}.\n\n";

    my $videos = getAllVideosForDate($token, $day->{'date'});
    foreach my $video (@$videos) {
      my $csv       = "$main::DOWNLOAD_PATH/$video->{'id'}.csv";
      my $thumbfile = "$main::DOWNLOAD_PATH/$video->{'id'}.jpg";
      my $videofile = "$main::DOWNLOAD_PATH/$video->{'id'}.mp4";

      my $favorite = "false";
      if ($video->{'attributes'}->{'favorite'}) {
        $favorite = "true";
      }

      my $species = getSpecies($token, $video->{'id'});

      if (! $video->{'attributes'}->{'favorite'}) {
        print "Not downloading $video->{'id'} (not marked as favorite).";
      } else {
        print "Metadata:  $csv\n";
        open(my $fh, '>', $csv) or die "Couldn't open $csv: $!";
        print $fh "id,title,species,favorite,uploaded,duration,thumbnail,video\n";
        print $fh "$video->{'id'},$video->{'attributes'}->{'title'},", join(':', @{$species}), ",$favorite,$video->{'attributes'}->{'formatted_recorded_at'},$video->{'attributes'}->{'duration'} s,$video->{'attributes'}->{'image_url'},$video->{'attributes'}->{'video_url'}\n";
        close($fh);
  
        print "Thumbnail: $thumbfile\n";
        if (-e $thumbfile) {
          print "  $video->{'id'}.jpg already downloaded. Delete it to re-download.\n";
        } else {
          getstore($video->{'attributes'}->{'image_url'}, $thumbfile)
            or die "Couldn't download thumbnail: $!";
        }
  
        print "Video:     $videofile\n";
        if (-e $videofile) {
          print "  $video->{'id'}.mp4 already downloaded. Delete it to re-download.\n";
        } else {
          getstore($video->{'attributes'}->{'video_url'}, $videofile)
            or die "Couldn't download video: $!";
        }
      }
      print "\n";
    }
    print "\n";
  }
}

# single day mode
#
if ($action eq 'list' or $action eq 'delete' or $action eq 'download') {
  my $count = getVideoCountForDate($token, $date);
  print "Found $count videos for $date.";
  if ($count > 0) {
    print " Loading...";
    $|++;
  } else {
    print "\n";
    exit;
  }
  my $videos = getAllVideosForDate($token, $date);
  
  foreach my $video (@$videos) {
    my $favorite = "false";
    if ($video->{'attributes'}->{'favorite'}) {
      $favorite = "true";
    }

    my $species = getSpecies($token, $video->{'id'});

    print "\n\n";
    print "Title:     $video->{'attributes'}->{'title'}\n";
    print "ID:        $video->{'id'}\n";
    print "Species:   ", join(', ', @{$species}), "\n";
    print "Favorite:  $favorite\n";
    print "Uploaded:  $video->{'attributes'}->{'formatted_recorded_at'}\n";
    print "Duration:  $video->{'attributes'}->{'duration'} s\n";
    print "Thumbnail: $video->{'attributes'}->{'image_url'}\n";
    print "Video:     $video->{'attributes'}->{'video_url'}\n";
  
    if ($action eq 'delete') {
      if ($video->{'attributes'}->{'favorite'}) {
        print "\nNot deleting $video->{'id'}.\n";
      } else {
        print "\nDeleting $video->{'id'}...";
        $|++;
        if (deleteVideoById($token, $video->{'id'}) ne -1) {
          print "done.\n";
        } else {
          print "failed.\n";
        }
      }
    } elsif ($action eq 'download') {
      if (! $video->{'attributes'}->{'favorite'}) {
        print "\nNot downloading $video->{'id'}.\n";
      } else {
        print "\nDownloading $video->{'id'}.\n";
  
        my $csv = "$main::DOWNLOAD_PATH/$video->{'id'}.csv";
        print "Metadata:  $csv\n";
        open(my $fh, '>', $csv) or die "Couldn't open $csv: $!";
        print $fh "id,title,species,favorite,uploaded,duration,thumbnail,video\n";
        print $fh "$video->{'id'},$video->{'attributes'}->{'title'},", join(':', @{$species}), ",$favorite,$video->{'attributes'}->{'formatted_recorded_at'},$video->{'attributes'}->{'duration'} s,$video->{'attributes'}->{'image_url'},$video->{'attributes'}->{'video_url'}\n";
        close($fh);
  
        my $thumbfile = "$main::DOWNLOAD_PATH/$video->{'id'}.jpg";
        print "Thumbnail: $thumbfile\n";
        getstore($video->{'attributes'}->{'image_url'}, $thumbfile)
          or die "Couldn't download thumbnail: $!";
  
        my $videofile = "$main::DOWNLOAD_PATH/$video->{'id'}.mp4";
        print "Video:     $videofile\n";
        getstore($video->{'attributes'}->{'video_url'}, $videofile)
          or die "Couldn't download video: $!";
      }
    }
  }
}
