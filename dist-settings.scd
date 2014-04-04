// beat
~b[0] = [-1, -0.9, -0.1, -0.5, 0, 0.1, 0.0, 1];
~b[1] = Env([-1, -0.6, -0.2, 0.6, 0.2, 1], curve:\welch);
~b[2] = Env([-1, -0.2,  0.1, 0.1, 1], curve:\welch);
~b[3] = Env([-1, -0.9,  -0.5, -0.1, 0.9, 0.99, 1], curve:\sin);


var sig, in;
in = LocalIn.ar(2).sum;
//in = in[0] - in[1];
sig = (~sig * 8) + LPF.ar(HPF.ar(DelayC.ar(in * 0.8, 4, 0.3), 10), 200);
sig = DelayC.ar(sig, 0.1, { LFNoise2.ar(0.1.rand) * 0.1 } ! 16);
//sig = Decay.ar(Dust.ar(0.3), 3) + sig;
sig = (
	Decay.ar(Impulse.ar(0.65), 1.5)
	- Decay.ar(Impulse.ar(0.15, 0.50, 0.6), 4.1)
	- Decay.ar(Impulse.ar(0.0725, 0.25, 0.9), 8.1)
) + sig;
sig = Shaper.ar(~b[0], sig);
sig = AllpassN.ar(sig, 1, { 1.0.rand }, { 0.1.rand });
sig = sig + (sig * HPF.ar(WhiteNoise.ar(0.01), 16000));
sig = Shaper.ar(~b[3], sig);
sig = (sig * 0.99) +  LPF.ar(sig, 60) + HPF.ar(sig, 8000);
sig = Mirror.ar(sig * 0.3);
sig = Shaper.ar(~b[1], sig);
sig = sig * LPF.ar(sig, MouseX.kr(5, 1800));
sig = LeakDC.ar(sig);
sig = Splay.ar(sig);
LocalOut.ar(sig);
sig * 5;



// tear r ist
~b[0] = [-1, -0.9, -0.1, -0.5, 0, 0.1, 0.0, 1];
~b[1] = Env([-1, -0.6, -0.2, 0.6, 0.2, 1], curve:\sin);
~b[2] = Env([-1, -0.2,  0.1, 0.1, 1], curve:\welch);
~b[3] = Env([-1, -0.9,  -0.5, 0, 0.5, 0.99, 1], curve:\sin);

var sig, in;
in = LocalIn.ar(2).sum;
//in = in[0] - in[1];
sig = (~sig * 5) + LPF.ar(HPF.ar(DelayC.ar(in * 0.8, 0.5, 0.3), 1000), 2000);
sig = DelayC.ar(sig, 0.1, { LFNoise2.ar(0.1.rand) * 0.1 } ! 16);
//sig = Decay.ar(Dust.ar(0.3), 3) + sig;
//sig = Decay.ar(Impulse.ar(0.3), 3.1) * sig;
sig = Shaper.ar(~b[0], sig);
sig = AllpassN.ar(sig, 1, { 1.0.rand }, { 0.1.rand });
sig = sig + (sig * HPF.ar(WhiteNoise.ar(0.1), 16000));
sig = Shaper.ar(~b[3], sig);
sig = (sig * 0.99) +  LPF.ar(sig, 60) + HPF.ar(sig, 8000);
sig = Mirror.ar(sig * 1);
sig = Shaper.ar(~b[1], sig);
sig = sig * LPF.ar(sig, 20);
sig = LeakDC.ar(sig);
sig = Splay.ar(sig);
LocalOut.ar(sig);
sig;



// ripple
~b[0] = [-1, -0.9, -0.1, -0.5, 0, 0.1, 0.0, 1];
~b[1] = Env([-1, -0.6, -0.2, 0.6, 0.2, 1], curve:\sin);
~b[2] = Env([-1, -0.2,  0.1, 0.1, 1], curve:\welch);
~b[3] = Env([-1, -0.9,  -0.5, 0, 0.5, 0.99, 1], curve:\sin);

var sig, in;
in = LocalIn.ar(2).sum;
//in = in[0] - in[1];
sig = (~sig * 8) + LPF.ar(HPF.ar(DelayC.ar(in * 0.9, 0.5, 0.3), 1000), 2000);
sig = DelayC.ar(sig, 0.1, { LFNoise2.ar(0.1.rand) * 0.1 } ! 16);
//sig = Decay.ar(Dust.ar(0.3), 3) + sig;.
//sig = Decay.ar(Impulse.ar(0.3), 3.1) * sig;
sig = (
	Decay.ar(Impulse.ar(0.65), 1.5)
	- Decay.ar(Impulse.ar(0.15, 0.50, 0.6), 4.1)
	- Decay.ar(Impulse.ar(0.0725, 0.25, 0.9), 8.1)
) * sig;
//sig = sig + (LFSaw.ar([600, 1400, 400] - 3, 0, 0.001)).sum;
sig = Shaper.ar(~b[0], sig);
sig = AllpassN.ar(sig, 1, { 1.0.rand }, { 0.1.rand });
sig = sig + (sig * HPF.ar(WhiteNoise.ar(0.1), 16000));
sig = Shaper.ar(~b[3], sig);
sig = (sig * 0.29) +  LPF.ar(sig, 60) + HPF.ar(sig, 12000);
sig = Mirror.ar(sig * 5);
sig = Shaper.ar(~b[1], sig);
sig = sig * LPF.ar(sig, 20);
sig = LeakDC.ar(sig);
sig = Splay.ar(sig);
LocalOut.ar(sig);
sig;



// other tear
~b[0] = [-1, -0.9, -0.1, -0.5, 0, 0.1, 0.0, 1];
~b[1] = Env([-1, -0.6, -0.2, 0.6, 0.2, 1], curve:\sin);
~b[2] = Env([-1, -0.2,  0.1, 0.1, 1], curve:\welch);
~b[3] = Env([-1, -0.9,  -0.5, 0, 0.5, 0.99, 1], curve:\sin);

var sig, in;
in = LocalIn.ar(2).sum;
//in = in[0] - in[1];
sig = (~sig * 9) + LPF.ar(HPF.ar(DelayC.ar(in * 0.48, 0.5, 0.3), 2000), 5000);
sig = DelayC.ar(sig, 0.1, { LFNoise2.ar(0.1.rand) * 0.1 } ! 16);
//sig = Decay.ar(Dust.ar(0.3), 3) + sig;
//sig = Decay.ar(Impulse.ar(0.3), 3.1) * sig;
sig = Shaper.ar(~b[0], sig);
sig = AllpassN.ar(sig, 1, { 1.0.rand }, { 0.1.rand });
sig = sig + (sig * HPF.ar(WhiteNoise.ar(0.05), 16000));
sig = Shaper.ar(~b[3], sig);
sig = (sig * 0.99) +  LPF.ar(sig, 60) + HPF.ar(sig, 8000);
sig = Mirror.ar(sig * 1);
sig = Shaper.ar(~b[1], sig);
sig = sig * LPF.ar(sig, 50);
sig = LeakDC.ar(sig);
sig = Splay.ar(sig);
LocalOut.ar(sig);
sig;



