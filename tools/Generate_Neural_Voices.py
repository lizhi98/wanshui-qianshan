"""Generate real local neural speech. pip install sherpa-onnx soundfile"""
from pathlib import Path
import argparse,json,hashlib
ap=argparse.ArgumentParser();ap.add_argument('--model-dir',required=True);ap.add_argument('--project-root',default=str(Path(__file__).resolve().parents[1]));args=ap.parse_args()
import sherpa_onnx,soundfile as sf
m=Path(args.model_dir);root=Path(args.project_root)
c=sherpa_onnx.OfflineTtsConfig(model=sherpa_onnx.OfflineTtsModelConfig(kokoro=sherpa_onnx.OfflineTtsKokoroModelConfig(model=str(m/'model.int8.onnx'),voices=str(m/'voices.bin'),tokens=str(m/'tokens.txt'),lexicon=str(m/'lexicon-us-en.txt')+','+str(m/'lexicon-zh.txt')),num_threads=4),rule_fsts=','.join(str(m/n) for n in ['date-zh.fst','number-zh.fst','phone-zh.fst']))
assert c.validate(); t=sherpa_onnx.OfflineTts(c)
manifest=json.loads((root/'assets/voices/manifest.json').read_text(encoding='utf-8'))
for i,(key,entry) in enumerate(manifest.items()):
 assert entry['gender']=='male' and 58<=entry['speaker_id']<=102
 a=t.generate(text=entry.get('spoken_text',entry['text']),sid=entry['speaker_id'],speed=entry['speed'])
 sf.write(root/entry['file'].removeprefix('res://'),a.samples,a.sample_rate,subtype='PCM_16')
 entry['duration_seconds']=round(len(a.samples)/a.sample_rate,3)
 entry['sha256']=hashlib.sha256((root/entry['file'].removeprefix('res://')).read_bytes()).hexdigest()
 print(i+1,len(manifest),entry['who'],entry['voice'],round(len(a.samples)/a.sample_rate,2),flush=True)
(root/'assets/voices/manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
print('Neural generation complete',flush=True)
