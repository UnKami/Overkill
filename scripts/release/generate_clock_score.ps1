# Original deterministic 32-second stereo score. No sampled third-party recordings.
param([string]$Output = "assets/audio/clockwork_nocturne.wav")
Add-Type -TypeDefinition @'
using System;
using System.IO;
public static class ClockScore {
  static double S(double f, double t) { return Math.Sin(2*Math.PI*f*t); }
  public static void Write(string path) {
    const int rate=22050, seconds=32;
    int samples=rate*seconds;
    double[,] chords={{73.416,110,174.614},{58.270,87.307,146.832},{65.406,98,155.563},{55,82.407,138.591}};
    double[] melody={293.665,349.228,329.628,220,261.626,293.665,220,0};
    var random=new Random(941);
    using(var f=new BinaryWriter(File.Create(path))) {
      f.Write(System.Text.Encoding.ASCII.GetBytes("RIFF")); f.Write(36+samples*4);
      f.Write(System.Text.Encoding.ASCII.GetBytes("WAVEfmt ")); f.Write(16);
      f.Write((short)1); f.Write((short)2); f.Write(rate); f.Write(rate*4);
      f.Write((short)4); f.Write((short)16);
      f.Write(System.Text.Encoding.ASCII.GetBytes("data")); f.Write(samples*4);
      for(int i=0;i<samples;i++) {
        double t=(double)i/rate, bar=t%8, beat=t%0.5;
        int chord=(int)(t/8)%4;
        double envelope=Math.Min(1,bar/1.4)*Math.Min(1,(8-bar)/1.4);
        double edge=Math.Min(1,t/0.8)*Math.Min(1,(seconds-t)/0.8);
        for(int ch=0;ch<2;ch++) {
          double pad=0;
          for(int n=0;n<3;n++) {
            double freq=chords[chord,n]*(ch==0?0.9985:1.0015);
            pad+=(S(freq,t)*0.55+S(freq*2,t)*0.22+S(freq*3,t)*0.08)*(0.85+0.15*S(0.13+n*0.03,t));
          }
          pad*=0.085*envelope;
          double note=melody[(int)(t/2)%8], nt=t%2;
          double bell=note==0?0:(S(note,t)+0.3*S(note*2.76,t))*Math.Exp(-nt*2.7)*Math.Min(1,nt*35)*0.048;
          double bass=S(chords[chord,0]/2,t)*Math.Exp(-beat*10)*0.045;
          double tick=(random.NextDouble()*2-1)*Math.Exp(-beat*125)*0.02;
          double outp=(pad+bell+bass+tick)*edge;
          f.Write((short)(Math.Max(-1,Math.Min(1,outp))*32767));
        }
      }
    }
  }
}
'@
$destination = [IO.Path]::GetFullPath($Output)
[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination)) | Out-Null
[ClockScore]::Write($destination)
