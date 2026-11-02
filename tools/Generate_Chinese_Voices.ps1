# Legacy SAPI reference only. V3.0 uses Generate_Expressive_Voices.py.
param([string]$ProjectRoot)
Add-Type -AssemblyName System.Speech
$taskManifest=Get-Content -LiteralPath (Join-Path $ProjectRoot 'assets\voices\manifest.json') -Raw | ConvertFrom-Json -AsHashtable
$taskSynth=[System.Speech.Synthesis.SpeechSynthesizer]::new()
$taskSynth.SelectVoice('Microsoft Kangkang')
try {
 foreach($taskEntry in $taskManifest.GetEnumerator()) {
  $taskData=$taskEntry.Value
  $taskOutput=Join-Path $ProjectRoot ('assets\voices\'+$taskEntry.Key+'.wav')
  $taskSynth.SetOutputToWaveFile($taskOutput)
  $taskEscaped=[System.Security.SecurityElement]::Escape($taskData.text)
  $taskSsml='<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="zh-CN"><prosody pitch="'+$taskData.pitch+'" rate="'+$taskData.rate+'">'+$taskEscaped+'</prosody></speak>'
  $taskSynth.SpeakSsml($taskSsml)
  $taskSynth.SetOutputToNull()
 }
} finally {$taskSynth.Dispose()}
Write-Output ('Generated '+$taskManifest.Count+' WAV files')
