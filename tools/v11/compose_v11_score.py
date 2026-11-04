"""Original Golden Hook score. Deterministic MIDI composition, rendered with
GeneralUser GS sampled instruments and FluidSynth; no borrowed melodies."""
from pathlib import Path
import struct,subprocess,wave,json,math,random,argparse,tempfile
import numpy as np
S=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--fluidsynth',required=True,type=Path);p.add_argument('--soundfont',required=True,type=Path);p.add_argument('--cache',type=Path,default=Path(tempfile.gettempdir())/'golden_hook_score');args=p.parse_args();args.cache.mkdir(parents=True,exist_ok=True)
MID=S/'art_source/V1_1_score';MID.mkdir(exist_ok=True)
AUDIO=S/'assets/golden_hook/audio'
SYNTH=args.fluidsynth
SF=args.soundfont
manifest=[]
def variable(n):
    b=[n&127];n>>=7
    while n:b.insert(0,(n&127)|128);n>>=7
    return bytes(b)
def midi(name,bpm,bars,programs,progression,melody,quiet=False):
    events=[];rng=random.Random(1935+bpm)
    def event(t,data):events.append((max(0,int(t*480)),bytes(data)))
    def note(ch,p,t,d,v):
        jitter=rng.uniform(-.025,.025);event(t+jitter,[0x90+ch,p,max(1,min(110,v+rng.randint(-3,3)))]);event(t+d+jitter,[0x80+ch,p,0])
    for ch,program in enumerate(programs):
        event(0,[0xC0+ch,program]);event(0,[0xB0+ch,7,88]);event(0,[0xB0+ch,10,[44,76,61,52][ch]]);event(0,[0xB0+ch,91,38])
    for bar in range(bars):
        chord=progression[(bar//2)%len(progression)];t=bar*4
        arc=.75+.23*math.sin(math.pi*bar/max(1,bars-1))
        if name=='memory':arc=.55+.45*bar/(bars-1)
        for ch in range(len(programs)):
            event(t,[0xB0+ch,11,int((58 if quiet else 79)*arc)])
        # Low cello: long bow, breathing at phrase boundaries.
        if bar%2==0:note(0,chord[0]-12,t+.04,7.45,44 if quiet else 53)
        # Piano/nylon strings: asymmetric, voiced around the common motif.
        offsets=[.18,2.1] if name=='shortage' else [.08,1.48,2.55,3.15]
        if quiet:offsets=[.15] if bar%2==0 else []
        for k,off in enumerate(offsets):note(1,chord[k%len(chord)]+12,t+off,1.7,38 if quiet else 49)
        # Warm string layer enters gradually and changes inversions.
        if len(programs)>2 and bar>=4 and bar%2==0:
            for p in chord[1:]:note(2,p+12,t+.12,7.3,int(33*arc))
        # The four-note hook motif returns with variation and space.
        if len(programs)>3 and bar>=4 and bar%8 in [0,1,2,4,5,6]:
            phrase=(bar//8)%3
            pitches=melody[(bar%8)*2%len(melody):]+melody[:(bar%8)*2%len(melody)]
            for k,(off,d) in enumerate([(0.12,1.35),(1.75,1.1),(3.05,.75)]):
                if k==2 and bar%4==2:continue
                pitch=pitches[k%len(pitches)]+(0 if phrase!=2 else (2 if k==1 else 0))
                note(3,pitch,t+off,d,int((39 if name=='memory' else 43)*arc))
        if name=='urgent':
            for off in [0,.75,2,2.75]:note(0,chord[0],t+off,.42,44)
    tempo=bytes([0xff,0x51,3])+int(60000000/bpm).to_bytes(3,'big')
    events.append((0,tempo));events.sort(key=lambda x:x[0]);data=b'';previous=0
    for tick,ev in events:data+=variable(tick-previous)+ev;previous=tick
    end=bars*4*480;data+=variable(max(0,end-previous))+b'\xff\x2f\x00'
    path=MID/(name+'.mid');path.write_bytes(b'MThd'+struct.pack('>IHHH',6,0,1,480)+b'MTrk'+struct.pack('>I',len(data))+data)
    output=args.cache/(name+'_score.wav')
    subprocess.run([str(SYNTH),'-n','-i','-C','0','-R','1','-g','.65','-r','32000','-F',str(output),str(SF),str(path)],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.PIPE,timeout=100)
    with wave.open(str(output),'rb') as f:channels=f.getnchannels();rate=f.getframerate();samples=np.frombuffer(f.readframes(f.getnframes()),np.int16).reshape(-1,channels).astype(np.float64)/32768
    frames=int(bars*4*60/bpm*rate);samples=samples[:frames]
    rms=float(np.sqrt(np.mean(samples*samples)));target=.10 if quiet else .145
    samples*=min(target/max(.0001,rms),.88/max(.001,np.abs(samples).max()))
    fade=min(rate*3,len(samples)//8);samples[:fade]*=np.linspace(0,1,fade)[:,None];samples[-fade:]*=np.linspace(1,0,fade)[:,None]
    dest=AUDIO/(name+'.wav')
    with wave.open(str(dest),'wb') as f:f.setnchannels(channels);f.setsampwidth(2);f.setframerate(rate);f.writeframes((np.clip(samples,-.98,.98)*32767).astype(np.int16).tobytes())
    manifest.append({'cue':name,'seconds':round(len(samples)/rate,2),'bars':bars,'bpm':bpm,'GM_programs_zero_based':programs,'source_midi':str(path.relative_to(S)),'composition':'original for this project','render':'FluidSynth 2.6.1 / GeneralUser GS 2.0.3','human_listening':'pending; technical rendering is not emotional approval'})
    print('COMPOSED',name,manifest[-1]['seconds'],flush=True)
chords_minor=[[40,47,55,59],[36,43,52,55],[43,50,55,59],[38,45,54,57]]
chords_hope=[[43,50,55,59],[40,47,55,59],[36,43,52,55],[38,45,54,57]]
motif=[67,69,71,74,71,69,67,64,66,67,69,67]
midi('shortage',58,24,[42,0,48],chords_minor,motif)
midi('hope',69,24,[42,24,48,73],chords_hope,motif)
midi('warm',64,24,[42,24,48,71],chords_hope,motif)
midi('urgent',76,28,[42,0,45,73],chords_minor,[64,66,67,71,69,67,66,64])
midi('memory',54,28,[42,0,48,60],chords_hope,motif)
midi('fishing',60,24,[42,24],chords_minor,motif,True)
(S/'docs/golden_hook/V1_1_MUSIC_MANIFEST.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print('SCORE COMPLETE',sum(x['seconds'] for x in manifest),flush=True)
