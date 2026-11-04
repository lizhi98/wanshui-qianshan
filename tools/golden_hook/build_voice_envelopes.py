from pathlib import Path
import wave,json
import numpy as np
S=Path(__file__).resolve().parents[2]
result={}
for p in sorted((S/'assets/golden_hook/audio/voice').glob('*.wav')):
    with wave.open(str(p),'rb') as f:
        sr=f.getframerate(); channels=f.getnchannels(); data=np.frombuffer(f.readframes(f.getnframes()),np.int16).astype(float)/32768
        if channels>1: data=data.reshape(-1,channels).mean(axis=1)
    size=sr//25
    result[p.stem]=[round(min(1.,float(np.sqrt(np.mean(data[i:i+size]**2)))*9),3) for i in range(0,len(data),size)]
(S/'game/golden_hook/voice_envelopes.gd').write_text('extends RefCounted\n## 25Hz RMS measured from each offline voice WAV.\nconst HZ=25.0\nconst LINES='+json.dumps(result,separators=(',',':'))+'\n',encoding='utf-8')
print('ENVELOPES',len(result))
