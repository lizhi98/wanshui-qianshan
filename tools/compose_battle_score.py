"""Original march/battle cues, rendered through GeneralUser GS instruments.
No film melodies or film audio samples. Requires tinysoundfont, numpy.
Pass --soundfont to a separately downloaded GeneralUser-GS.sf2 (not in the game).
"""
from pathlib import Path
import argparse,json,wave,hashlib
import numpy as np
import tinysoundfont

ap=argparse.ArgumentParser();ap.add_argument('--soundfont',required=True);ap.add_argument('--root',default=str(Path(__file__).resolve().parents[1]));args=ap.parse_args()
root=Path(args.root);out=root/'assets/remaster/audio';out.mkdir(exist_ok=True)
RATE=24000
rng=np.random.default_rng(19350529)
PROGRAMS={0:60,1:61,2:48,3:42,4:45,5:58,6:56,7:47}

def render(name,bpm,energy,bars=24):
 beat=60/bpm;length=bars*4*beat;events=[]
 def note(chan,start,duration,pitch,velocity):
  start=max(0,start*beat+float(rng.uniform(-.009,.009)));duration=max(.04,duration*beat)
  events.extend([(int(start*RATE),1,chan,pitch,int(np.clip(velocity+rng.integers(-4,5),1,127))),(int((start+duration)*RATE),0,chan,pitch,0)])
 # Original six-note call, developed and answered over an eight-bar minor cadence.
 roots=[38,38,46,43,38,41,45,38]
 phrase=[[74,69,74,77,76,72],[72,67,70,74,72,69],[74,77,81,79,77,76],[69,72,74,77,76,74]]
 for bar in range(bars):
  start=bar*4;key=roots[bar%8];major=bar%8 in [2,3,5]
  chord=[key,key+7,key+(16 if major else 15)]
  dynamic=.82+.18*np.sin((bar%8)/7*np.pi)
  for pitch in chord:note(2,start,3.9,pitch+12,int(48+energy*21))
  for k in range(8):
   note(3,start+k*.5,.37,key+(12 if k%2 else 0),int(52+energy*25))
   if energy>.5:note(4,start+k*.5,.22,chord[(k+bar)%3]+24,int(50+energy*22))
  motif=phrase[(bar//2)%4]
  if bar%2==0:
   for j,pitch in enumerate(motif):
    t=[0,.75,1.0,2.0,2.75,3.25][j]
    note(0,start+t,.6 if j<5 else 1.15,pitch-12,int((64+energy*29)*dynamic))
    if energy>.6 and bar%8 in [0,4]:note(6,start+t,.56,pitch,int(60+energy*16))
  elif energy>.55:
   for k,pitch in enumerate([key+19,key+22,key+24,key+19]):note(1,start+k,.72,pitch,int(60+energy*25))
  for k in [0,2]:
   note(5,start+k,.6,key,int(65+energy*26));note(9,start+k,.24,36,int(60+energy*36))
  for k in [1,3]:note(9,start+k,.24,38,int(55+energy*35))
  if energy>.5:
   for k in range(8):note(9,start+k*.5,.1,42,int(29+energy*16))
   if bar%4==3:
    for k in range(8):note(9,start+3+k*.125,.09,38,45+k*5)
  if bar%4==0:note(9,start,.7,49,int(53+energy*31));note(7,start,1.8,key+12,int(64+energy*27))
  if name=='chain_battle' and bar%4==2:
   for k in range(8):note(2,start+k*.5,.3,81+(k%3)*2,40)
 events.sort(key=lambda e:(e[0],e[1]))
 synth=tinysoundfont.Synth(gain=-4,samplerate=RATE);bank=synth.sfload(args.soundfont)
 for chan,preset in PROGRAMS.items():synth.program_select(chan,bank,0,preset)
 synth.program_select(9,bank,128,0,is_drums=True)
 total=int((length+2)*RATE);data=np.zeros((total,2),np.float32);cursor=0
 for at,on,chan,pitch,velocity in events:
  at=min(at,total)
  if at>cursor:data[cursor:at]=np.frombuffer(synth.generate_simple(at-cursor),np.float32).reshape(-1,2);cursor=at
  if on:synth.noteon(chan,pitch,velocity)
  else:synth.noteoff(chan,pitch)
 if cursor<total:data[cursor:]=np.frombuffer(synth.generate_simple(total-cursor),np.float32).reshape(-1,2)
 # Fold the instrument release into the loop start, preserving the downbeat.
 n=int(length*RATE);data[:len(data)-n]+=data[n:];data=data[:n]
 delay=int(.13*RATE);data[delay:,1]+=data[:-delay,0]*.11
 peak=np.max(np.abs(data));data*=.86/max(.001,float(peak))
 write(name,data)
 (out/f'{name}_score.json').write_text(json.dumps({'original_composition':True,'bpm':bpm,'bars':bars,'events':len(events),'soundfont':'GeneralUser GS 2.0.3','programs':PROGRAMS,'seconds':len(data)/RATE}),encoding='utf-8')
 print(name,round(len(data)/RATE,2),'seconds',flush=True)

def write(name,data):
 with wave.open(str(out/(name+'.wav')),'wb') as f:f.setnchannels(2);f.setsampwidth(2);f.setframerate(RATE);f.writeframes((np.clip(data,-1,1)*32767).astype('<i2').tobytes())

for name,bpm,energy,bars in [('advance',108,.35,16),('assault',124,1.0,32),('chain_battle',114,.78,24),('victory',96,.65,16)]:render(name,bpm,energy,bars)

for name,length,bass in [('cannon_fire',2.5,51),('shell_impact',3.3,39)]:
 t=np.arange(int(RATE*length))/RATE;noise=rng.standard_normal(len(t))
 low=np.convolve(noise,np.ones(95)/95,'same');mid=np.convolve(noise,np.ones(13)/13,'same')
 signal=np.sin(2*np.pi*(bass*t+7*(1-np.exp(-t*16))))*np.exp(-t*3.7)*.8
 signal+=noise*np.exp(-t*55)*.38+mid*np.exp(-t*6)*.55+low*np.exp(-t*1.35)*1.5
 if name=='shell_impact':
  for at in [.18,.34,.55,.71]:signal+=np.roll(mid,int(at*RATE))*np.exp(-np.maximum(0,t-at)*12)*(t>at)*.10
 signal=np.tanh(signal*1.4);signal*=.86/np.max(np.abs(signal))
 write(name,np.column_stack([signal,np.roll(signal,73)*.92]))
print('Battle score and original artillery effects ready',flush=True)
