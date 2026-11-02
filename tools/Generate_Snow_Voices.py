"""Offline Qwen3-TTS 1.7B CustomVoice generation, with per-line dramatic direction.

pip install qwen-tts torch soundfile
Download Qwen/Qwen3-TTS-12Hz-1.7B-CustomVoice separately (Apache-2.0).
No recordings or cloned voices are used. A GPU with about 6 GB free is needed.
"""
from pathlib import Path
import argparse, hashlib, json, os, time

ap = argparse.ArgumentParser()
ap.add_argument('--model-dir', required=True)
ap.add_argument('--project-root', default=str(Path(__file__).resolve().parents[1]))
ap.add_argument('--limit', type=int, default=0)
ap.add_argument('--force', action='store_true')
args = ap.parse_args()
os.environ['HF_HUB_OFFLINE'] = '1'
os.environ['TOKENIZERS_PARALLELISM'] = 'false'
import numpy as np
import soundfile as sf
import torch
from qwen_tts import Qwen3TTSModel

root = Path(args.project_root)
path = root / 'assets/snow/voices/manifest.json'
manifest = json.loads(path.read_text(encoding='utf-8'))

def direction(e):
    if e.get('direction'): return e['direction']
    text, who = e['text'], e['who']
    base = '中文自然对白，按句意重音和呼吸停顿，短停顿与长停顿有变化，不要逐字念稿，不要每句同样的升降调。'
    if '不能辜负' in text:
        return base + '年轻男战士亲眼看到掩护自己的同志牺牲，先压住悲痛，不能辜负同志的牺牲说得低沉坚定，停半拍，再奋力喊冲啊。不要笑，不要朗诵腔。'
    if '突击组' in text:
        return base + '男班长在激烈枪火中果断指挥，突击组、火力掩护、铺板组三个分工要有层次，短促有力，自然换气。'
    if '同志！' in text:
        return base + '年轻男战士看到战友坠桥，先震惊悲痛喊出同志，哽住半拍，再强忍悲伤坚定喊掩护。克制真实，不要夸张哭腔。'
    if '中弹' in text:
        return base + '正在枪火中，突然看到同伴中弹，紧张急促地警告身边战友，后半句提高力度催促掩护。'
    if '对岸还有' in text:
        return base + '沉稳但急切的男班长在战斗中发出短促口令，强调铺板与掩护，两句之间用自然换气。'
    if any(s in text for s in ['压住','火力','偏向','风将','歪了','先停']):
        return base + '危险就在眼前，急切而清楚地提醒同伴，声音紧绷有力度，关键动作加重，避免平铺直叙。'
    if any(s in text for s in ['通了','干得好','稳住了','合格','拉住了','到位','安全']):
        return base + '刚完成艰难协作，先松一口气，带着克制的喜悦和鼓励，把好消息告诉身边人。'
    if any(s in text for s in ['来了','抓稳','搭把手','一齐','一起抬','抬过去','走！']):
        return base + '和近处同伴协作用力，像现场互相应答，起句有回应感，发力词短而坚定，后句自然加快。'
    if who in ['数字记录','判断提示','装配提示']:
        return base + '清晰温和的男声讲解，像面对面解释结构，有耐心，按意义分组表达，不要机械播报。'
    if who == '周班长':
        return base + '经验丰富的男班长，沉稳可靠，有关切也有行动决心，像当面对战士交代任务。'
    return base + '年轻男战士和身边同伴自然交谈，有呼吸和语气变化，轻微紧张但坚定。'

print('Loading expressive model', flush=True)
torch.set_num_threads(4)
model = Qwen3TTSModel.from_pretrained(args.model_dir, device_map='cuda:0',
    dtype=torch.bfloat16, attn_implementation='sdpa', low_cpu_mem_usage=True)
made = 0
items = sorted(manifest.items(), key=lambda item: 0 if 'voice' not in item[1] else 1)
for i, (key, entry) in enumerate(items):
    speaker = {'周班长': 'Uncle_Fu', '阿木': 'Eric', '林川': 'Dylan'}.get(entry['who'], 'Uncle_Fu')
    instruct = direction(entry)
    signature = hashlib.sha256((speaker + instruct + entry['text'] + 'v4.0-snow').encode()).hexdigest()
    target = root / entry['file'].removeprefix('res://')
    if (not args.force and entry.get('generation_signature') == signature and target.exists()
        and hashlib.sha256(target.read_bytes()).hexdigest() == entry.get('sha256')):
        continue
    torch.manual_seed(3100 + i)
    start = time.monotonic()
    with torch.inference_mode():
        waves, sr = model.generate_custom_voice(text=entry.get('spoken_text', entry['text']),
            language='Chinese', speaker=speaker, instruct=instruct,
            max_new_tokens=650, do_sample=True, temperature=.8, top_p=.95,
            repetition_penalty=1.1)
    data = np.asarray(waves[0], dtype=np.float32).reshape(-1)
    # Retain natural internal pauses; trim only excessive outer silence.
    audible = np.where(np.abs(data) > .007)[0]
    if len(audible):
        data = data[max(0, audible[0]-int(sr*.08)):min(len(data),audible[-1]+int(sr*.20))]
    peak = float(np.max(np.abs(data)))
    if not .2 < len(data)/sr < 45 or peak < .01:
        raise RuntimeError(f'Invalid generated speech: {entry["text"]}')
    data *= .89 / peak
    temporary = target.with_suffix('.new.wav')
    sf.write(temporary, data, sr, subtype='PCM_16')
    temporary.replace(target)
    entry.update(engine='Qwen3-TTS', voice='Qwen3-TTS-1.7B-CustomVoice/'+speaker,
        speaker=speaker, gender='male', model_license='Apache-2.0', instruct=instruct,
        generation_signature=signature, sample_rate=sr,
        duration_seconds=round(len(data)/sr, 3), sha256=hashlib.sha256(target.read_bytes()).hexdigest())
    for obsolete in ['speaker_id','speed']: entry.pop(obsolete, None)
    path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f'{i+1}/{len(manifest)} {entry["who"]} {speaker} {len(data)/sr:.2f}s generated in {time.monotonic()-start:.1f}s', flush=True)
    made += 1
    if args.limit and made >= args.limit: break
print('Generation finished', made, flush=True)
