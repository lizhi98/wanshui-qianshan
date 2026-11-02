# Original six-cue score. Usage: python compose_memorial_score.py /path/GeneralUser-GS.sf2
from pathlib import Path
import numpy as np,tinysoundfont,wave,json,sys
r=Path(__file__).resolve().parents[1];out=r/'assets/memorial/audio';out.mkdir(parents=True,exist_ok=True)
rate=24000;font=Path(sys.argv[1]) if len(sys.argv)>1 else r/'assets/music/GeneralUser-GS.sf2';rng=np.random.default_rng(410)
cues=[('m_camp',64,12,[50,55,48,50],[24,73,42]),('m_march',70,12,[50,48,46,50],[48,73,42]),('m_storm',78,10,[50,49,46,48],[48,45,43]),('m_search',48,10,[50,46,49,50],[48,11,42]),('m_memorial',48,12,[50,46,43,50],[48,0,42]),('m_continue',58,16,[50,55,46,50],[48,60,42])]
for name,bpm,bars,roots,programs in cues:
 beat=60/bpm;events=[];seconds=bars*4*beat
 def note(ch,t,d,p,v):events.extend([(int(t*beat*rate),1,ch,p,v),(int((t+d)*beat*rate),0,ch,p,0)])
 for bar in range(bars):
  base=roots[bar%4]
  for p in [base,base+7,base+15]:note(0,bar*4,3.85,p+12,28 if name in ['m_search','m_memorial'] else 40)
  note(2,bar*4,3.7,base,30)
  if name=='m_search':
   if bar%3==0:note(1,bar*4+1,1.5,base+19,28)
  elif name=='m_memorial':
   if bar%2==0:
    for k,p in enumerate([base+19,base+22]):note(1,bar*4+k*2,1.7,p,32)
  else:
   for k,p in enumerate([base+19,base+22,base+24,base+19]):note(1,bar*4+k,.85,p,32+(bar//4 if name=='m_continue' else 0)*2)
 s=tinysoundfont.Synth(gain=-9,samplerate=rate);bank=s.sfload(str(font))
 for ch,program in enumerate(programs):s.program_select(ch,bank,0,program)
 total=int((seconds+2)*rate);data=np.zeros((total,2),np.float32);cursor=0
 for at,on,ch,p,v in sorted(events):
  at=min(total,at)
  if at>cursor:data[cursor:at]=np.frombuffer(s.generate_simple(at-cursor),np.float32).reshape(-1,2);cursor=at
  s.noteon(ch,p,v) if on else s.noteoff(ch,p)
 if cursor<total:data[cursor:]=np.frombuffer(s.generate_simple(total-cursor),np.float32).reshape(-1,2)
 n=int(seconds*rate);data[:total-n]+=data[n:];data=data[:n];data*=.7/max(.001,float(np.max(abs(data))))
 with wave.open(str(out/(name+'.wav')),'wb') as f:f.setnchannels(2);f.setsampwidth(2);f.setframerate(rate);f.writeframes((data.clip(-1,1)*32767).astype('<i2').tobytes())
 print(name,seconds,flush=True)
(out/'score_manifest.json').write_text(json.dumps({'original_composition':True,'soundfont':'GeneralUser GS','no_commercial_samples':True,'cues':[x[0] for x in cues]},indent=2),encoding='utf-8')
