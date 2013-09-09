Server.default = Server.local;
s.makeGui;
(
var cymbal;
SynthDef(\cymbal, {
	arg out = 0, amp = 0.1, loDecay = 8, hiDecay = 15;
	var env, lodriver, locutoffenv, hidriver, hicutoffenv, freqs, res, thwack, gdrive, sig, drive;

	drive = Decay.ar(Impulse.ar(0), 5) * 10;
	env = EnvGen.kr(Env.perc(0.1, 15, curve:-16), gate: drive, doneAction:2);
	sig = WhiteNoise.ar(1);
	sig = HPF.ar(sig, 15000) * env * amp;

	Out.ar(out, sig);
}).add;

SynthDef( \peng, {
	arg amp = 0.3, gate = 1, bassFreq = 15, bellFreq = 600, input = 10,
	noiseLPF = 50, decayAmt = 3, lpf = 40, dur = 8, noiseAmt = 0.9, delayAmt = 0.1,
	whiteAmt = 0.1;
	var in, impulse, decay, noise, freq, freqs, amps, decays, sig, delayTimes, delayAmts, delaySpike, env;

	env = EnvGen.kr(Env([0, 1, 1, 0], [0.01, 0.1, 8], releaseNode:2), gate:gate, doneAction:2);
	freq = bellFreq;

	in = In.ar(input) * env;

	in = LeakDC.ar(in + Mix(CombC.ar(LeakDC.ar(in), 0.1, 1 / [0.3,2,4,8,12,20], 2, 0.001)));
	// in = (in * FreqShift.ar( in, 300, 0.5 ))*30;
	in = in * (0.4 + HardCompress.ar(
		((FreqShift.ar(in, -40) * LPF.ar(PinkNoise.ar(noiseAmt), 380))),
		speed: 0.1
	));
	in = LeakDC.ar(in + LPF.ar(in.pow(2), noiseLPF, 10));

	//decay = Decay.ar(in * 0.01, decayAmt);
	decay = in;
	noise = in + (decay * WhiteNoise.ar(whiteAmt));
	noise = LeakDC.ar(decay + (decay * noise));

	freqs = [0.56, 0.56, 0.92, 0.92, 1.19, 1.7, 2.0, 2.74, 3, 3.76, 4.07, 5.3] * freq;
	freqs[1] = freqs[1] + 1; freqs[3] = freqs[3] + 1.7;
	amps = [1, 0.67, 1.35, 1.8, 2.67, 1.67, 1.46, 1.33, 1.33, 1.0, 1.33, 0.3];
	decays = [1, 0.9, 0.65, 0.55, 0.325, 0.35, 0.25, 0.2, 0.15, 0.1, 0.075, 0.2];

	sig = DynKlank.ar(`[freqs, amps, decays], in + noise, decayscale:decayAmt, freqscale:1) * 0.001;
	sig = Limiter.ar(sig, -12.dbamp);
	sig = Compander.ar(sig, sig, 0.75, 1/2, 1/8);
	sig = LeakDC.ar(sig);
	sig = [sig, sig];
	sig = sig + [
		CombC.ar(in * sig[0], 0.4, (bellFreq * [1, 2, 3]).reciprocal, 0.4).sum,
		CombC.ar(in * sig[1], 0.4, (bellFreq * [1.001, 2.0032, 3.0104]).reciprocal, 0.61).sum;
	];
	sig = sig + [
		CombC.ar(sig[0], 0.4, [0.1,0.2,0.3], 0.2).sum / 3,
		CombC.ar(sig[1], 0.4, [0.11,0.18,0.26], 0.2).sum / 3;
	];
	sig = LeakDC.ar(sig);

	// in = in + Mix(CombC.ar(sig, 0.1, 1 / [0.3,2,4,8,12,20], 2, 0.1));
	// in = LeakDC.ar(in);
	//
	// in = (in * FreqShift.ar( in, 300, 0.5 )) * 30;
	// in = HardCompress.ar( ((sig * 0.01) + (FreqShift.ar( in, -400 ))) );
	in = sig + HardCompress.ar((sig * LPF.ar(PinkNoise.ar(noiseAmt * 0.5), lpf)) + (in * LPF.ar( PinkNoise.ar(noiseAmt * 0.5), lpf)));
	in = in + LPF.ar(in * in, 50, 1);

	sig = FreeVerb.ar(sig * 0.1, 0.8, 0.4, mul: 0.3);
	sig = sig + HardCompress.ar(sig + (in * LPF.ar( PinkNoise.ar(0.25), lpf)));
	sig = sig * 0.2;

	delaySpike = LagUD.ar(Trig1.ar(LFNoise2.ar(6).range(0, 1) - delayAmt, 0.1), 0.01, 1.7);
	delayTimes = [0, 1, 2, 3, 4, 5] * (4.02 / bellFreq);
	delayAmts = [delaySpike.range(1, 0.15)] ++ (delaySpike.range(0, 0.65) ! 5);
	sig = sig + (0.4 * [
		Mix(CombC.ar(sig[0] * delaySpike, 0.1, delayTimes, delayAmts)),
		Mix(CombC.ar(sig[1] * delaySpike, 0.1, delayTimes, delayAmts)),
	]);
	Out.ar(0, sig);

	sig = sig * env;
	sig = LeakDC.ar(sig * amp);
	//Out.ar(0, sig);
}).add;

SynthDef(\driver, {
	arg out=0, pengOut = 0, cymbalIn, gate = 0, amp = 1, freq = 6300, rate = 8, decay = 0.9, double = 0, noiseAmt = 0.2;
	var sig, imp, cymbalGate;

	noiseAmt = noiseAmt * LFNoise2.kr(0.6).range(0.95, 1.05);

	imp = Impulse.ar(rate, LFNoise2.kr(8).pow(8) * 0.2) + (double * Impulse.ar(rate));
	imp = imp;

	imp = Decay.ar(imp, LFNoise2.kr(1).range(decay * 0.2, decay));
	imp = RLPF.ar(imp, freq, 1000 / freq);

	sig = SinOsc.ar(imp.range(80, 40), mul: imp);
	sig = Compander.ar(sig, sig, 0.75, 1/4, 1/4);
	sig = sig + (InFeedback.ar(cymbalIn) * 0.05);
	sig = sig + (imp * (
		LPF.ar(
			WhiteNoise.ar(IEnvGen.kr(Env([-20, -10, -10, -10], [0.25, 0.25, 0.5]), noiseAmt).dbamp),
			noiseAmt.forceRange(5, 300)
		)
		+ HPF.ar(
			WhiteNoise.ar(IEnvGen.kr(Env([-100, -70, -50], [0.5, 0.5]), noiseAmt).dbamp),
			noiseAmt.forceRange(800, 9000)
		)
	));

	sig = sig + HPF.ar(CombC.ar(sig * LFNoise2.kr(0.1).pow(4), 3, 2.1, 12), 400);

	//	sig = sig * EnvGen.kr(Env([0, 1, 1, 0], [0.1, 1, 3], releaseNode:2), gate:gate, doneAction:2);

	Out.ar(out, sig * [1, 1] * amp);
	Out.ar(pengOut, sig * [1, 1]);
}).add();
)

(
l = LCDevice();
l.knobs.do({
	|k|
	k.ringStyle_(\fill)
	.cv_(nil)
	.lightWhenActive_(true);
});

m = MultiStateManager();

State(\peng).clear;
State(\peng).use({
	~bus = ~bus ? Bus.audio(s, 2);
	~cymbalBus = ~cymbalBus ? Bus.audio(s, 2);

	~driverControls = [
		~driverAmp = 		CV(\amp.asSpec),
		~driverFreq = 		CV(ControlSpec(20, 5000, warp: \exp, default: 1000)),
		~driverDecay = 		CV(ControlSpec(0.05, 1.5, warp: \exp, default: 0.9)),
		~driverNoiseAmt = 	CV(ControlSpec(0, 1, default: 0)),
		~driverDouble = 	CV(ControlSpec(0, 1, default: 0)),
	];

	~pengControls = [
		~pengAmp = 			CV(\amp.asSpec),
		~pengNoiseLPF = 	CV(ControlSpec(10, 1000, warp:\exp, default: 100)),
		~pengLPF = 			CV(ControlSpec(10, 300, warp: \exp, default: 50)),
		~pengDecayAmt = 	CV(ControlSpec(0.1, 10, default: 1)),
		~pengNoiseAmt = 	CV(ControlSpec(0.01, 3, default:0.9)),
		~pengDelayAmt = 	CV(ControlSpec(0, 1, default: 0.1))
	];

	~driverEvent = (
		\instrument: \driver,
		\pengOut: ~bus.index,
		\cymbalIn: ~cymbalBus.index,
		\rate: 8,
		\amp: ~driverAmp,
		\freq: ~driverFreq,
		\decay: ~driverDecay,
		\double: ~driverDouble,
		\noiseAmt: ~driverNoiseAmt
	).cvSynth;

	~cymbalEvent = (
		\instrument: \cymbal,
		\out: ~cymbalBus.index,
		\amp: 0.8,
	).cvSynth;

	Pdef(\peng, Pbind(
		\instrument, \peng,
		\input, ~bus.index,
		\bellFreq, Pseq([0, 0, 4, 9, 0, [0, 8], 5, 7, 9, 9].collect(Scale.partch_o3.degreeToFreq(_ , 98, 0)), inf),
		\dur, 4,
		\amp, ~pengAmp,
		\noiseLPF, ~pengNoiseLPF,
		\lpf, ~pengLPF,
		\decayAmt, ~pengDecayAmt,
		\noiseAmt, ~pengNoiseAmt,
		\delayAmt, ~pengDelayAmt,
	));

	Pdef(\noteTest, Pbind(
		\bassFreq, Pseq([20, 40, 400, 6], inf),
		\bellFreq, Ptrace(Pseq([
			0, 0, 0, -1, -2, -2,
			[0, 24], 0, [0, 22], -2, -3, -3
		].collect(Scale.partch_o2.degreeToFreq(_ , 98, 0)), inf))
	));

});

State(\peng).startActions.add({
	// CV mappings to peng
	~pengGroup = Group(s);
	Pdef(\pengGroup, (\group: ~pengGroup));

	[
		\amp, ~pengAmp,
		\decayAmt, ~pengDecayAmt,
		\noiseLPF, ~pengNoiseLPF,
		\lpf, ~pengLPF,
		\noiseAmt, ~pengNoiseAmt,
		\delayAmt, ~pengDelayAmt
	].connectToNode(Server.default, ~pengGroup.nodeID);

	~knobs = List();
	~knobs.addAll(
		~driverControls.collect({
			|cv, i|
			l.knobs[(i * 4) + 3].cv = cv;
		})
	);

	~knobs.addAll(
		~pengControls.collect({
			|cv, i|
			l.knobs[(i * 4) + 2].cv = cv;
		})
	);

	~driverEvent.play;
	~pattern = (Pdef(\noteTest) <> Pdef(\pengGroup) <> Pdef(\peng)).play;
});

State(\peng).stopActions.add({
	~driverEvent.free;
	~pattern.stop;
	~knobs.do(_.cv_(nil));
	~pengMappings.do(_.remove);
});
)

Pdef(\peng).free

m.switch(nil);
m.switch(State(\peng));
