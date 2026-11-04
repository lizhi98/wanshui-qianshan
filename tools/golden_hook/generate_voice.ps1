Add-Type -AssemblyName System.Speech
$records=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'voice_records.json') -Raw | ConvertFrom-Json
$voiceFolder=Join-Path $PSScriptRoot '../../assets/golden_hook/audio/voice'
$synth=New-Object System.Speech.Synthesis.SpeechSynthesizer
$format=New-Object System.Speech.AudioFormat.SpeechAudioFormatInfo(24000,[System.Speech.AudioFormat.AudioBitsPerSample]::Sixteen,[System.Speech.AudioFormat.AudioChannel]::Mono)
foreach($row in $records) {
    $dest=Join-Path $voiceFolder ($row.id+'.wav')
    if(Test-Path -LiteralPath $dest) {continue}
    if($row.speaker -eq '旁白') { $synth.SelectVoice('Microsoft Huihui'); $synth.Rate=-1 }
    else {
        $synth.SelectVoice('Microsoft Kangkang')
        $synth.Rate=switch($row.speaker) {'老班长' {-2} '小梁' {0} '小石' {1} '阿青' {-1} default {0}}
    }
    $synth.SetOutputToWaveFile($dest,$format)
    $synth.Speak([string]$row.text)
    $synth.SetOutputToNull()
    Write-Output $row.id
}
$synth.Dispose()
