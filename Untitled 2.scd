(
SynthDef( \big, {
	arg amp = 0.3, gate = 1, bassFreq = 15, bellFreq = 600, input = 10, noiseLPF = 50, decayAmt = 3, lpf = 40, dur = 8;
	var in, impulse, decay, noise, freq, freqs, amps, decays, sig, delayTimes, delayAmts, delaySpike;

	freq = bellFreq;
	in = InFeedback.ar(input);

	in = LeakDC.ar(in + Mix(CombC.ar(LeakDC.ar(in), 0.1, 1 / [0.3,2,4,8,12,20], 2, 0.05)));
	// in = (in * FreqShift.ar( in, 300, 0.5 ))*30;
	in = in * HardCompress.ar((FreqShift.ar(in, -200) * LPF.ar(PinkNoise.ar(0.9), 200)));
	in = in + LPF.ar(in.pow(2), noiseLPF, 1);

	//decay = Decay.ar(in * 0.01, decayAmt);
	decay = in;
	//noise = Dust.ar(Line.kr(0,10,decayAmt+20)) * EnvGen.ar( Env( [0,1,0], [0.6,0.4] ), timeScale:decayAmt );
	noise = in + (decay * WhiteNoise.ar(0.01));
	noise = LeakDC.ar(decay + (decay * noise));

	freqs = [0.56, 0.56, 0.92, 0.92, 1.19, 1.7, 2.0, 2.74, 3, 3.76, 4.07, 53] * freq;
	freqs[1] = freqs[1] + 1; freqs[3] = freqs[3] + 1.7;
	amps = [1, 0.67, 1.35, 1.8, 2.67, 1.67, 1.46, 1.33, 1.33, 1.0, 1.33, 0.3];
	decays = [1, 0.9, 0.65, 0.55, 0.325, 0.35, 0.25, 0.2, 0.15, 0.1, 0.075, 0.2];
	sig = DynKlank.ar(`[freqs, amps, decays], in + noise, decayscale:12, freqscale:1) * 0.001;
	sig = Limiter.ar(sig, -12.dbamp);
	sig = LeakDC.ar(sig);
	sig = [sig, sig];
	sig = sig + [
		CombC.ar(in * sig[0], 0.4, (bellFreq * [1, 2, 3]).reciprocal, 0.4).sum,
		CombC.ar(in * sig[1], 0.4, (bellFreq * [1.001, 2.0032, 3.0104]).reciprocal, 0.61).sum;
	];
	sig = sig + [
		CombC.ar(sig[0], 0.4, [0.1,0.2,0.3], 1).sum / 3,
		CombC.ar(sig[1], 0.4, [0.11,0.18,0.26], 1).sum / 3;
	];

	in = in + Mix(CombC.ar(sig, 0.1, 1/[0.3,2,4,8,12,20], 2, 0.1));
	in = LeakDC.ar(in);

	// in = (in * FreqShift.ar( in, 300, 0.5 )) * 30;
	// in = HardCompress.ar( ((sig * 0.01) + (FreqShift.ar( in, -400 ))) );
	in = HardCompress.ar((sig * LPF.ar(PinkNoise.ar(0.5), lpf)) + (in * LPF.ar( PinkNoise.ar(0.5), lpf)));
	in = in + LPF.ar(in * in, 50, 1);

	sig = sig + FreeVerb.ar(sig * 0.1, 0.8, 0.4);
//	sig = HardCompress.ar(sig + (in * LPF.ar( PinkNoise.ar(0.25), lpf)));
	sig = sig * 0.2;

	delaySpike = LagUD.ar(LFNoise2.ar(6) > 0.9, 0.1, 1.7);
	delayTimes = [0, 1, 2, 3, 4, 5] * (4.02 / bellFreq);
	delayAmts = [delaySpike.range(1, 0.25)] ++ (delaySpike.range(0, 0.25) ! 5);
	sig = sig + [
		Mix(CombC.ar(sig[0], 0.1, delayTimes, delaySpike.neg)),
		Mix(CombC.ar(sig[1], 0.1, delayTimes, delaySpike.neg)),
	];

	sig = sig * EnvGen.ar(Env([0, 1, 1, 0], [2, 0.1, 8], releaseNode:2), gate:gate, doneAction:2);
	sig = LeakDC.ar(sig * amp);
	Out.ar(0, sig);
}).add;

SynthDef(\driver, {
	arg out = 0, gate = 0, amp = 1, freq = 6300, rate = 8, double = 0, noiseAmt = 0.2;
	var sig, imp;

	noiseAmt = LFNoise2.kr(0.5).range(0, 1);

	imp = Impulse.ar(rate, LFNoise2.kr(8).pow(8) * 0.2) + (double * Impulse.ar(rate));
	imp = Decay.ar(imp, LFNoise2.kr(1).range(0.2, 0.9));
	imp = RLPF.ar(imp, freq, 1000/freq);

	sig = SinOsc.ar(imp.range(80, 40), mul: imp);
	sig = sig + LPF.ar(WhiteNoise.ar(), noiseAmt.range(5, 90), mul: imp);
	sig = sig + HPF.ar(CombC.ar(sig * LFNoise2.kr(0.1).pow(4), 3, 2.1, 12), 400);
	sig = sig * amp;

	Out.ar(0, sig * [1, 1]);
	Out.ar(out, sig * [1, 1]);
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

State(\big).clear;
State(\big).use({

	~bus = ~bus ? Bus.audio(s, 2);

	~controls = [
		~driverAmp = CV(\amp.asSpec),
		~driverFreq = CV(ControlSpec(20, 2000, default: 1000)),
		~driverNoiseAmt = CV(ControlSpec(0, 1, default: 0))
		~driverDouble = CV(ControlSpec(0, 1, default: 0)),
	];

	~driverEvent = (
		\instrument: \driver,
		\out: ~bus.index,
		\rate: 8,
		\freq: ~driverFreq,
		\amp: ~driverAmp,
		\double: ~driverDouble,
		\noiseAmt: ~driverNoiseAmt
	).cvSynth;

	Pdef(\base, Pbind(
		\instrument, \big,
		\input, ~bus.index,
		\bellFreq, Ptrace(Pseq([0, 0, 4, 9, 0, [0, 8], 5, 7, 9, 9].collect(Scale.partch_o3.degreeToFreq(_ , 98, 0)), inf)),
		\noiseLPF, Pseq([1000, 1000, 500, 100], inf),
		\lpf, Pfunc({ rrand(20.0, 300.0) }),
		\decayAmt, Pseq([0.1, 2, 1, 4], inf),
		\dur, 8,
		\amp, 0.05
	));

	Pdef(\noteTest, Pbind(
		\bassFreq, Pseq([20, 40, 400, 6], inf),
		\bellFreq, Ptrace(Pseq([
			0, 0, 0, -1, -2, -2,
			[0, 24], 0, [0, 25], -2, -3, -3
		].collect(Scale.partch_o2.degreeToFreq(_ , 98, 0)), inf))
	));

});

State(\big).startActions.add({
	~knobs = ~controls.collect({
		|cv, i|
		l.knobs[(i * 4) + 3].cv = cv;
	});

	~driverEvent.play;
	~pattern = (Pdef(\noteTest) <> Pdef(\base)).play;
});

State(\big).stopActions.add({
	~driverEvent.free;
	~pattern.stop;
	~knobs.do(_.cv_(nil));
});
)

m.switch(State(\big));
m.switch(nil);
