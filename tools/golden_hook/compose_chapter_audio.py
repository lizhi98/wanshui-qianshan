from pathlib import Path
import numpy as np, wave

ROOT=Path(__file__).resolve().parents[2]/'assets/golden_hook/audio'
ROOT.mkdir(parents=True,exist_ok=True)
SR=24000
rng=np.random.default_rng(10631)
def write(name,data):
    data=np.clip(data,-.95,.95)
    with wave.open(str(ROOT/(name+'.wav')),'wb') as f:
        f.setnchannels(1); f.setsampwidth(2); f.setframerate(SR); f.writeframes((data*32767).astype('<i2').tobytes())
def tone(hz,t): return np.sin(t*2*np.pi*hz)
themes={
    'shortage': [[146.832,174.614,220.0],[130.813,164.814,196.0],[116.541,146.832,174.614],[110.0,146.832,164.814]],
    'hope': [[146.832,220.,293.665],[174.614,220.,261.626],[130.813,196.,261.626],[146.832,220.,293.665]],
    'warm': [[174.614,220.,261.626],[146.832,174.614,220.],[130.813,164.814,196.],[146.832,196.,220.]],
    'urgent': [[110.,146.832,155.563],[116.541,146.832,174.614],[110.,138.591,164.814],[110.,146.832,174.614]],
    'memory': [[146.832,220.,293.665],[130.813,196.,261.626],[174.614,220.,293.665],[146.832,220.,293.665]],
}
for name,chords in themes.items():
    size=SR*48; result=np.zeros(size)
    for i,chord in enumerate(chords):
        start=i*12*SR; t=np.arange(12*SR)/SR
        env=np.sin(np.pi*np.clip(t/12,0,1))**.8
        pad=sum((tone(hz,t)+.19*tone(hz*2.002,t)+.05*tone(hz*3,t)) for hz in chord)/len(chord)
        result[start:start+len(t)]+=pad*env*.20
        for k in range(3):
            delay=2.0+k*3.2; j=int((i*12+delay)*SR)
            note=chord[(k+i)%3]*2
            nt=np.arange(int(4.0*SR))/SR
            pluck=(tone(note,nt)+.16*tone(note*2.004,nt))*(1-np.exp(-nt*5))*np.exp(-nt*.85)*.065
            end=min(size,j+len(pluck)); result[j:end]+=pluck[:end-j]
    if name=='urgent':
        t=np.arange(size)/SR
        result+=tone(73.416,t)*(.5+.5*np.sin(t*np.pi*1.1))**5*.055
    fade=np.minimum(np.arange(size)/SR/2,1)*np.minimum((size-np.arange(size))/SR/2,1)
    write(name,result*fade)
t=np.arange(SR*24)/SR
noise=rng.standard_normal(len(t))
smooth=np.convolve(noise,np.ones(140)/140,'same')
wind=smooth*.9*(.65+.2*np.sin(t*.43)+.15*np.sin(t*.17))
wind*=np.minimum(t/1.5,1)*np.minimum((24-t)/1.5,1)
write('wind',wind)
for name,duration in [('cast',.45),('bite',.22),('splash',.65),('pull',.35),('slip',.30),('pickup',.18),('fire',.7)]:
    t=np.arange(int(SR*duration))/SR
    noise=rng.standard_normal(len(t))
    env=np.sin(np.pi*t/duration)**1.4
    if name=='bite': data=(tone(530,t)+.5*tone(740,t))*env*.16
    elif name=='pickup': data=tone(280+800*t,t)*env*.10
    elif name=='pull': data=tone(160+400*t,t)*env*.12
    elif name=='slip': data=tone(540-800*t,t)*env*.1
    else:
        data=np.convolve(noise,np.ones(8)/8,'same')*env*(.35 if name=='splash' else .12)
    write(name,data)
print('13 original music/ambient/effect WAV assets generated')
