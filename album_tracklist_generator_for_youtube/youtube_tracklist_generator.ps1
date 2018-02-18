#Requires -Version 5
# Script will write to stdout formatted tracklist for i.e. youtube
# Now supports only manual pasta format from bandcamp, like
# 1.
# Whatever title - just whatever 01:23
# 2.
# ...

# Usage: .\youtube_tracklist_generator.ps1 -BandcampPastaMode -Path .\path\to\pasta\from.bandcamp.txt

param(
  [parameter(Mandatory=$true)][string]$Path,
  [parameter(Mandatory=$true)][switch]$BandcampPastaMode  # TODO : change parameter to $Mode with ValidateSet
)

class Track {
  [int]$Number
  [string]$Title
  [timespan]$Length
}

function getTracklistFromBandcampPasta([parameter(mandatory=$true)][string]$PathToPasta){
  $rx = '\d+\.\r?\n.*?\d\d\:\d\d'
  $pasta = get-content -raw "$PathToPasta"
  $entries = [regex]::Matches($pasta, $rx, "multiline")
  $trackList = @()
  foreach($entry in $entries){
    $entry = $entry.Value -replace '\r?\n',''
    $currentTrack = [Track]::new()

    $entry -match '\d+(?=\.)' | Out-Null
    $currentTrack.Number = $Matches[0]

    $entry -match '(?<=\d+\.).+(?=\d\d\:)' | Out-Null
    $currentTrack.Title = $Matches[0]

    $entry -match '\d\d\:\d\d' | Out-Null
    $currentTrack.Length = [timespan]"00:$($Matches[0])"

    $trackList += $currentTrack
  }
  Write-Output $trackList
}

if($BandcampPastaMode){
  $trackList = getTracklistFromBandcampPasta $Path
}
# TODO: switch($mode){$SomeOtherMode}{ ...

$totalLen = New-TimeSpan
foreach($track in $trackList){
  Write-Output ("{0:mm}:{0:ss} $($track.Number). $($track.Title)" -f $totalLen)
  $totalLen += $track.Length
}
