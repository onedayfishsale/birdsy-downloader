# birdsy-downloader
Perl script to download your wildlife video clips from birdsy.com

## Support
Report issues via [GitHub Issues](https://github.com/onedayfishsale/birdsy-downloader/issues). I believe there is a [Facebook group](https://www.facebook.com/groups/1705527023541736/) using this code, but I'm not on Facebook so can't participate directly. Feel free to email josh@feep.org, or if you're on the fediverse (Mastodon, etc.), message [@josh@feep.org](https://social.feep.org/@josh).

A Birdsy friend, Dusty, recorded [a tutorial](https://www.loom.com/share/e0e180564a2242c0897a9e9cd075ce70?sid=7f7fdb57-b345-4ca0-b59c-78f7104fbd92) for running this script on Windows using Strawberry Perl. I've tested it briefly on Windows 11 and it works fine. Thanks, Dusty!

## Setup
1. Update config.ph with your birdsy.com username and password. Change the download path to a path that exists on your computer.
2. Update the `require` path in birdsy.pl to the actual path of your config.ph.

## Synopsis

`./birdsy.pl --action=<action> --date=<YYYY-MM-DD>`
where `<action>` is `list`, `delete`, `download`, or `sync`

## Actions
### list
Lists videos for a single day.
```
$ ./birdsy.pl --action=list --date=2024-08-10
Found 2 videos for 2024-08-10T00:00:00. Loading...

Title:     Wildlife visits
ID:        I3GBelHfpNDR
Favorite:  true
Uploaded:  Aug 10, 2024 8:33 pm
Duration:  56 s
Thumbnail: https://data.birdsy.com/I3GBelHfpNDR/preview.jpg
Video:     https://data.birdsy.com/I3GBelHfpNDR/I3GBelHfpNDR.mp4


Title:     Wildlife visits
ID:        ECkQHyfpmuca
Favorite:  true
Uploaded:  Aug 10, 2024 8:31 pm
Duration:  76 s
Thumbnail: https://data.birdsy.com/ECkQHyfpmuca/preview.jpg
Video:     https://data.birdsy.com/ECkQHyfpmuca/ECkQHyfpmuca.mp4
$
```

### delete
Deletes add non-favorited videos for a single day.

```
$ ./birdsy.pl --action=delete --date=2024-08-10
...
```

### download
Downloads favorited videos for a single day. Three files are created for each video.
 - `<id>.csv`: video clip metadata, readable in Excel, etc.
 - `<id>.jpg`: video clip thumbnail, JPEG
 - `<id>.mp4`: video clip, MP4

```
$ ./birdsy.pl --action=download --date=2024-08-10
Found 2 videos for 2024-08-10T00:00:00. Loading...

Title:     Wildlife visits
ID:        I3GBelHfpNDR
Favorite:  true
Uploaded:  Aug 10, 2024 8:33 pm
Duration:  56 s
Thumbnail: https://data.birdsy.com/I3GBelHfpNDR/preview.jpg
Video:     https://data.birdsy.com/I3GBelHfpNDR/I3GBelHfRNDR.mp4

Downloading I3GBelHfpNDR.
Metadata:  /tmp/birdsy/I3GBelHfpNDR.csv
Thumbnail: /tmp/birdsy/I3GBelHfpNDR.jpg
Video:     /tmp/birdsy/I3GBelHfpNDR.mp4


Title:     Wildlife visits
ID:        ECkQHyfpmuca
Favorite:  true
Uploaded:  Aug 10, 2024 8:31 pm
Duration:  76 s
Thumbnail: https://data.birdsy.com/ECkQHyfpmuca/preview.jpg
Video:     https://data.birdsy.com/ECkQHyfpmuca/ECkQHyfpmuca.mp4

Downloading ECkQHyf1muca.
Metadata:  /tmp/birdsy/ECkQHyfpmuca.csv
Thumbnail: /tmp/birdsy/ECkQHyfpmuca.jpg
Video:     /tmp/birdsy/ECkQHyfpmuca.mp4
$ 
```

### sync
Downloads all favorited videos from all days if they haven't already been downloaded.

```
$ ./birdsy.pl --action=sync
Syncing 1 videos for 2021-05-21T00:00:00.
85bv_DlXpMQp already downloaded. (Delete /tmp/birdsy/85bv_DlXpMQp.csv to re-download.)

Syncing 1 videos for 2021-05-28T00:00:00.
Z5F45DUa_GpV already downloaded. (Delete /tmp/birdsy/Z5F45DUa_GpV.csv to re-download.)

Syncing 2 videos for 2021-05-29T00:00:00.
lQ0X_MppWq6O already downloaded. (Delete /tmp/birdsy/lQ0X_MppWq6O.csv to re-download.)
zKfwthgPa5Qa already downloaded. (Delete /tmp/birdsy/zKfwthgPa5Qa.csv to re-download.)

Syncing 2 videos for 2021-05-30T00:00:00.
...
```
