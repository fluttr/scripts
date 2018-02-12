param(
  [parameter(Mandatory=$true)][string]$Path,
  [switch]$BandcampPastaMode  # TODO : переделать параметр в $Mode с ValidateSet
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
  $tracklist = @()
  foreach($entry in $entries){
    $entry = $entry.Value -replace '\r?\n',''
    $currentTrack = [Track]::new()

    $entry -match '\d+(?=\.)' | Out-Null
    $currentTrack.Number = $Matches[0]

    $entry -match '(?<=\d+\.)[\w\s\-,\.\!\:\#]+(?=\d\d\:)' | Out-Null
    $currentTrack.Title = $Matches[0]

    $entry -match '\d\d\:\d\d' | Out-Null
    $currentTrack.Length = [timespan]"00:$($Matches[0])"

    $tracklist += $currentTrack
  }
  Write-Output $tracklist
}

if($BandcampPastaMode){
  $trackList = getTracklistFromBandcampPasta $Path
}
# TODO: elseif($SomeOtherMode){ ...

# напишет в stdout отформатированный для ютуба список песен в альбоме
$totalLen = New-TimeSpan
foreach($track in $trackList){
  Write-Output ("{0:mm}:{0:ss} $($track.Number). $($track.Title)" -f $totalLen)
  $totalLen += $track.Length
}
