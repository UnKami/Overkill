"""Original deterministic synthesized combat Foley; no sampled third-party recordings.
Run with Python 3 + numpy. Emits peak-limited PCM WAV plus measurable QA metadata.
"""
from pathlib import Path
import json, wave
import numpy as np
RATE = 44100
OUT = Path(__file__).resolve().parents[2] / "assets/audio/combat"
OUT.mkdir(parents=True, exist_ok=True)
rng = np.random.default_rng(18018)

def noise(n, smoothing=1):
    x = rng.uniform(-1,1,n)
    if smoothing > 1: x = np.convolve(x,np.ones(smoothing)/smoothing,mode="same")
    return x

def bell(t, frequencies, decay):
    return sum(np.sin(2*np.pi*f*t)*np.exp(-t*(decay+i*1.6))/(i+1) for i,f in enumerate(frequencies))

def build(name,duration):
    t=np.arange(int(duration*RATE))/RATE
    attack=np.minimum(t/.004,1)
    if name == "swing":
        swell=np.sin(np.pi*np.minimum(t/duration,1))**2
        x=(noise(len(t),3)-noise(len(t),24)*.2)*swell*.8 + np.sin(2*np.pi*(90*t+170*t*t))*swell*.12
    elif name == "strike":
        x=bell(t,[310,793,1421,2780],9)*.24 + noise(len(t),2)*np.exp(-t*95)*.62 + np.sin(2*np.pi*(62*t+3*(1-np.exp(-t*22))))*np.exp(-t*16)*.7
    elif name == "guard":
        x=bell(t,[670,1427,2143,3860],4)*.48 + noise(len(t))*np.exp(-t*130)*.3 + np.sin(2*np.pi*130*t)*np.exp(-t*22)*.35
    elif name == "shatter":
        x=np.zeros(len(t))
        for i in range(7):
            at=i*.021; u=np.maximum(0,t-at); gate=(t>=at)
            x+=gate*(bell(u,[980+i*137,2371+i*71],19)*.17+noise(len(t))*np.exp(-u*160)*.12)
    elif name == "heal":
        x=bell(t,[440,554.365,659.255,880],3)*.4*(1-np.exp(-t*18))
    elif name == "reveal":
        x=bell(t,[240,643,1380],11)*.25
        for at in [0,.048,.09]:
            u=np.maximum(0,t-at)
            x+=(t>=at)*noise(len(t))*np.exp(-u*160)*.3
    elif name == "victory":
        x=bell(t,[293.665,349.228,440,587.33],1.7)*.4*(1-np.exp(-t*20))
        x+=noise(len(t),50)*np.sin(np.pi*t/duration)*.18
    else:
        phase=2*np.pi*(95*t-20*t*t)
        x=np.sin(phase)*np.exp(-t*3)*.45+noise(len(t),22)*np.exp(-t*4)*.3
    x*=attack*np.minimum((duration-t)/.025,1)
    x-=np.mean(x)
    x*=.79/max(.79,float(np.max(np.abs(x))))
    samples=(np.clip(x,-.99,.99)*32767).astype("<i2")
    with wave.open(str(OUT/(name+'.wav')),'wb') as f:
        f.setparams((1,2,RATE,len(samples),'NONE','not compressed'));f.writeframes(samples.tobytes())
    peak=float(np.max(np.abs(x))); rms=float(np.sqrt(np.mean(x*x)))
    assert peak < .8 and abs(float(x.mean())) < .00001 and rms > .01
    return {"seconds":duration,"peak_dbfs":round(20*np.log10(peak),2),"rms_dbfs":round(20*np.log10(rms),2),"clipped_samples":int(np.count_nonzero(np.abs(samples)>=32767))}

if __name__ == '__main__':
    results={name:build(name,duration) for name,duration in [('swing',.32),('strike',.65),('guard',.8),('shatter',.65),('heal',.9),('reveal',.45),('victory',1.8),('defeat',1.2)]}
    (OUT/'audio_qa.json').write_text(json.dumps(results,indent=2)+'\n')
    (OUT/'LICENSE.txt').write_text('Original Overkill procedural sound design. Generated from mathematical oscillators and deterministic noise by scripts/audio/build_combat_audio.py. No third-party recordings. Licensed under the same terms as the game source.\n')
    print(json.dumps(results,indent=2))
