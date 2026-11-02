from pathlib import Path
import numpy as np, tinysoundfont, wave, json
root=Path(__file__).resolve().parents[1];out=root/'assets/remaster/audio';fx=root/'assets/snow/audio';fx.mkdir(parents=True,exist_ok=True)
RATE=24000;rng=np.random.default_rng(19350612)
font=Path(__import__('sys').argv[1])
def write(path,data):
    data=np.asarray(data,dtype=np.float32)
    if data.ndim==1:data=np.column_stack([data,np.roll(data,59)*.97])
    data*=.78/max(.001,float(np.max(np.abs(data))))
    with wave.open(str(path),'wb') as f:f.setnchannels(2);f.setsampwidth(2);f.setframerate(RATE);f.writeframes((data.clip(-1,1)*32767).astype('<i2').tobytes())
for name,bpm,bars in [('snow_walk',76,24),('snow_crisis',88,16),('snow_summit',66,16)]:
    beat=60/bpm;seconds=bars*4*beat;events=[]
    def note(ch,start,duration,pitch,vel):
        a=int(max(0,start*beat+float(rng.uniform(-.008,.008)))*RATE);b=int((start+duration)*beat*RATE)
        events.extend([(a,1,ch,pitch,vel),(b,0,ch,pitch,0)])
    for bar in range(bars):
        base=[50,46,53,48][bar%4] if name!='snow_summit' else [50,55,57,50][bar%4]
        chord=[base,base+7,base+(16 if name=='snow_summit' else 15)]
        for p in chord:note(0,bar*4,3.9,p+12,42 if name!='snow_crisis' else 54)
        note(2,bar*4,3.5,base,42)
        if name=='snow_crisis':
            for k in range(8):note(3,bar*4+k*.5,.35,chord[k%3]+12,36+k%2*6)
        else:
            for k in range(4):note(3,bar*4+k,.8,chord[k%3]+24,34)
        if bar%2==0:
            for k,p in enumerate(([69,72,74,77] if name!='snow_summit' else [69,74,78,81])):note(1,bar*4+k,.85 if k<3 else 1.8,p,49)
    events.sort();s=tinysoundfont.Synth(gain=-6,samplerate=RATE);bank=s.sfload(str(font))
    for ch,program in [(0,48),(1,73),(2,42),(3,45)]:s.program_select(ch,bank,0,program)
    total=int((seconds+2)*RATE);data=np.zeros((total,2),np.float32);cursor=0
    for at,on,ch,p,v in events:
        at=min(at,total)
        if at>cursor:data[cursor:at]=np.frombuffer(s.generate_simple(at-cursor),np.float32).reshape(-1,2);cursor=at
        s.noteon(ch,p,v) if on else s.noteoff(ch,p)
    if cursor<total:data[cursor:]=np.frombuffer(s.generate_simple(total-cursor),np.float32).reshape(-1,2)
    n=int(seconds*RATE);data[:total-n]+=data[n:];write(out/(name+'.wav'),data[:n]);print(name,round(seconds,2),flush=True)
for name,length in [('snow_step',.32),('snow_slide',5.7)]:
    t=np.arange(int(length*RATE))/RATE;noise=rng.standard_normal(len(t));low=np.convolve(noise,np.ones(95)/95,'same')
    if name=='snow_step':data=(noise*.16+low*2)*np.exp(-t*19)*(1-np.exp(-t*120))
    else:data=(low*3+np.convolve(noise,np.ones(13)/13,'same')*.4)*(np.sin(np.pi*t/length)**.7)+np.sin(2*np.pi*39*t)*np.exp(-t*.6)*.25
    write(fx/(name+'.wav'),data)
(out/'snow_score.json').write_text(json.dumps({'original_music':True,'instruments':'GeneralUser GS 2.0.3','cues':['snow_walk','snow_crisis','snow_summit'],'foley':['snow_step','snow_slide'],'no_film_audio':True},indent=2),encoding='utf-8')
