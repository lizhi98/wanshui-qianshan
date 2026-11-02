"""Original, reproducible instrumental sketches; no sampled commercial music.
Outputs CC0 PCM loops. They are deliberately quiet under the river and dialogue.
"""
import numpy as np,wave,pathlib
P=pathlib.Path(__file__).resolve().parents[1]
OUT=P/'assets/remaster/audio';OUT.mkdir(parents=True,exist_ok=True)
RATE=24000; LENGTH=40.0
rng=np.random.default_rng(19350529)
def note(buffer,start,duration,midi,gain,kind='flute',pan=0):
    offset=int(start*RATE);n=min(int(duration*RATE),len(buffer)-offset)
    if n<=0:return
    t=np.arange(n)/RATE;frequency=440*2**((midi-69)/12)
    attack=.45 if kind=='strings' else .14
    envelope=np.minimum(1,t/attack)*np.minimum(1,(duration-t)/(.9 if kind=='strings' else .4))
    phase=2*np.pi*frequency*t+.025*np.sin(2*np.pi*4.7*t)
    if kind=='strings':
        signal=sum(np.sin(phase*h+rng.random())/h**1.7 for h in range(1,7))*.6
    else:
        signal=np.sin(phase)+.16*np.sin(phase*2)+.04*np.sin(phase*3)
        signal*=.85+.15*np.sin(np.pi*np.minimum(t/duration,1))
    signal=signal*envelope*gain
    buffer[offset:offset+n,0]+=signal*(.7-pan*.25)
    buffer[offset:offset+n,1]+=signal*(.7+pan*.25)
def write(name,data):
    # Short fade at loop joins; keep moderate headroom.
    fade=int(RATE*.25)
    data[:fade]*=np.linspace(0,1,fade)[:,None];data[-fade:]*=np.linspace(1,0,fade)[:,None]
    data=np.tanh(data)*.72
    with wave.open(str(OUT/(name+'.wav')),'wb') as f:
        f.setnchannels(2);f.setsampwidth(2);f.setframerate(RATE);f.writeframes((data*32767).astype('<i2').tobytes())
for name,progression,melody in [
 ('explore',[[50,57,62],[48,55,60],[46,53,60],[50,57,65]],[74,72,69,67,69,74,77,74]),
 ('tension',[[38,45,50],[38,48,53],[36,43,48],[38,45,53]],[62,65,67,69,67,65,62,60]),
 ('chain',[[38,45,57],[41,48,60],[38,45,57],[36,43,55]],[69,67,65,62,65,67,69,72]),
 ('ending',[[50,57,65],[48,55,64],[46,53,62],[50,57,66]],[74,77,79,81,79,77,74,72]),
 ('modern',[[50,57,66],[52,59,67],[48,55,64],[50,57,66]],[74,78,81,78,76,74,71,74])]:
    data=np.zeros((int(RATE*LENGTH),2),dtype=np.float64)
    for bar,chord in enumerate(progression):
        for i,pitch in enumerate(chord): note(data,bar*10,10,pitch,.045,'strings',(i-1)*.6)
    for i,pitch in enumerate(melody): note(data,1.8+i*4.6,3.2,pitch,.05 if name!='tension' else .025,'flute',(-1)**i*.4)
    if name in ['tension','chain']:
        for pulse in np.arange(0,LENGTH,.8 if name=='tension' else 1.6):
            at=int(pulse*RATE);n=min(int(.28*RATE),len(data)-at);t=np.arange(n)/RATE
            sound=np.sin(2*np.pi*(58*t+12*(1-np.exp(-t*25))))*np.exp(-t*17)*.04
            data[at:at+n]+=sound[:,None]
    # Subtle stereo delay gives space without a sampled reverb dependency.
    delay=int(.21*RATE);data[delay:,1]+=data[:-delay,0]*.14
    write(name,data)
wind=rng.standard_normal(int(RATE*12))
wind=np.convolve(wind,np.ones(90)/90,mode='same')*.2
wind*=.6+.4*np.sin(np.arange(len(wind))/RATE*.6)**2
write('wind',np.column_stack([wind,np.roll(wind,300)]))
print('ORIGINAL SCORE',len(list(OUT.glob('*.wav'))),'loops')
