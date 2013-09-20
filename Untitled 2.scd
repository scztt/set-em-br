//MultiStateManager(\perf).switch(State(\peng));

(
State(\peng).clear;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// INIT
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
State(\peng).initActions.add({
	~eventWindow = Window().layout_(VLayout(nil)).front();

	~eventList = List();

	~eventUpdate = {
		var toRemove = List();
		~eventList.do({
			|e|
			if (e[\view].isNil) {
				e[\view] = UserView().maxHeight_(40).layout_(VLayout(
					StaticText().string_("% [%]".format(e[\instrument], e[\node]))
				));
				e[\view].drawFunc_({
					|v|
					var rect, time, amt, width = v.bounds.width - 1.5;
					time = AppClock.seconds;
					amt = min(1, (time - e[\start]) / (e[\end] - e[\start]));
					rect = v.bounds.moveTo(0, 0).width_(amt * width);
					Pen.fillColor = if (amt < 1) { Color.green.alpha_(0.4) } { Color.green.alpha_(0.1) };
					Pen.strokeColor = Color.grey(0.5);
					Pen.fillRect(rect);
					Pen.strokeRect(rect);
				});
				~eventWindow.layout.insert(e[\view], 0);
			};

			if (AppClock.seconds > (e[\end] + 5)) {
				toRemove.add(e);
				e[\view].remove();
			};
		});

		~eventList.removeAll(toRemove);
		~eventWindow.refresh();
	};

	r = Routine({
		inf.do({
			~eventUpdate.();
			(1/60).wait;
		});
	}).play(AppClock);

	~eventWindow.onClose_({ r.stop });


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
		arg amp = 0.3, gate = 1, bellFreq = 600, input = 10,
		noiseLPF = 50, decayAmt = 3, lpf = 40, dur = 8, noiseAmt = 0.9, delayAmt = 0.1,
		whiteAmt = 0.1;
		var in, impulse, decay, noise, freq, freqs, amps, decays, verbSig, sig, delayTimes, delayAmts, delaySpike, env, sigForComb;

		env = EnvGen.kr(Env([0, 1, 1, 0], [1, 0.1, 8], releaseNode:2), gate:gate, doneAction:2);
		freq = bellFreq;

		in = In.ar(input) * env;

		// in = LeakDC.ar(in + Mix(CombC.ar(LeakDC.ar(in), 0.1, 1 / [0.3,2,4,8,12,20], 2, 0.001)));

		in = in * (0.4 + HardCompress.ar(
			((FreqShift.ar(in * env, -60) * LPF.ar(PinkNoise.ar(noiseAmt), lpf * 4))),
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

		sig = DynKlank.ar(`[freqs, amps, decays], in + noise, decayscale: decayAmt, freqscale:1) * 0.001;
		sig = Limiter.ar(sig, -12.dbamp);
		sig = Compander.ar(sig * env, sig, 1, 1/2, 1/8) * 0.5;
		sig = LeakDC.ar(sig);

		sigForComb = sig * env;
		sig = sig + [
			CombC.ar(in * sigForComb, 0.4, (bellFreq * [1, 2, 3]).reciprocal, 0.4).sum,
			CombC.ar(in * sigForComb, 0.4, (bellFreq * [1.001, 2.0032, 3.0104]).reciprocal, 0.61).sum;
		];
		sig = sig + [
			CombC.ar(sigForComb, 0.4, [0.1,0.2,0.3], 0.2).sum / 3,
			CombC.ar(sigForComb, 0.4, [0.11,0.18,0.26], 0.2).sum / 3;
		];
		sig = LeakDC.ar(sig);

		in = (in * FreqShift.ar(in, 15, 0.2)) * 1;
		in = HardCompress.ar(
			HPF.ar(sig * 0.4, 1500), speed: 5
		);

		in = in + sig
		+ HardCompress.ar((sig * LPF.ar(PinkNoise.ar(noiseAmt * 0.5), lpf))
			+ (in * LPF.ar( PinkNoise.ar(noiseAmt * 0.5), lpf)));

		in = in + LPF.ar(in * in, 50, 1);
		in = in * Line.kr(0, 1, 4);

		verbSig = FreeVerb.ar(sig * 0.5, 0.8, 0.4);
		sig = (1 * sig)
		+ (0.9 * verbSig)
		+ (0.9 * HardCompress.ar((verbSig * 0.3) + (in * LPF.ar( PinkNoise.ar(0.25), lpf))));
		sig = sig * 0.2;

		delaySpike = LagUD.ar(Trig1.ar(LFNoise2.ar(6).range(0, 1) - delayAmt, 0.1), 0.01, 1.7);
		delayTimes = [0, 1, 2, 3, 4, 5] * (4.02 / bellFreq);
		delayAmts = [delaySpike.range(1, 0.15)] ++ (delaySpike.range(0, 0.65) ! 5);

		sig = sig + (0.4 * [
			Mix(CombC.ar(sig[0] * delaySpike, 0.1, delayTimes, delayAmts)),
			Mix(CombC.ar(sig[1] * delaySpike, 0.1, delayTimes, delayAmts)),
		]);

		sig = sig * env;
		sig = LeakDC.ar(sig * amp);

		Out.ar(0, sig);
	}).add;

	SynthDef(\driver, {
		arg out = 0, pengOut = 0, cymbalIn, gate = 0, amp = 1, freq = 6300, rate = 8, decay = 0.9, double = 0, noiseAmt = 0.2;
		var sig, imp, multiImp, cymbalGate, multiAmt;

		noiseAmt = noiseAmt * LFNoise2.kr(0.6).range(0.95, 1.05);

		imp = Impulse.ar(rate, LFNoise2.kr(8).pow(8) * 0.3) + (double * Impulse.ar(rate));
		imp =

		imp = Decay.ar(imp, LFNoise2.kr(1).range(decay * 0.2, decay));
		imp = RLPF.ar(imp, freq, 1000 / freq);

		multiAmt = max(0, double - 0.5) * 2;
		multiImp = Mix(DelayN.ar(imp, 0.3, 1 / [2, 3, 5, 8, 9, 12, 14, 22, 25] * multiAmt)) * (1 / 9);
		imp = XFade2.ar(imp, multiImp, multiAmt * 2 - 1);

		sig = SinOsc.ar(imp.range(80, 40), mul: imp);
		sig = Compander.ar(sig, sig, 0.75, 1/4, 1/4, clampTime: 0.2, relaxTime: 1);
		sig = sig + (InFeedback.ar(cymbalIn) * 0.05);
		sig = sig + (imp * (
			LPF.ar(
				WhiteNoise.ar(IEnvGen.kr(Env([-30, -29, -15, -15], [0.25, 0.25, 0.5]), noiseAmt).dbamp),
				noiseAmt.forceRange(5, 300)
			)
			+ HPF.ar(
				WhiteNoise.ar(IEnvGen.kr(Env([-100, -70, -50], [0.5, 0.5]), noiseAmt).dbamp),
				noiseAmt.forceRange(800, 9000)
			)
		));

		sig = sig + HPF.ar(CombC.ar(sig * LFNoise2.kr(0.1).pow(4), 3, 2.1, 12), 400);
		sig = sig * EnvGen.kr(Env([0, 1, 1, 0], [0.1, 1, 3], releaseNode:2), gate:gate, doneAction:2);

		Out.ar(out, sig * [1, 1] * amp.lag(0.5));
		Out.ar(pengOut, sig * [1, 1]);
	}).add();

	~lc.notNil.if({ ~lc.free });

	~resources = SparseArray();
	~resources.addAll([
		~lc = LCDevice(),
		~bus = Bus.audio(s, 2),
		~cymbalBus = Bus.audio(s, 2),
		~pengGroup = Group(s),
	]);

	// Play button
	~playButton = ~lc.buttons[4].default;
	~playButton.toggle = true;
	~playButton.buttonOnActions.add({
		State(\peng).doStart();
	});

	~playButton.buttonOffActions.add({
		State(\peng).doStop();
	});

	// CV's
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
		~pengDecayAmt = 	CV(ControlSpec(0.1, 10, default: 1)),
		~pengNoiseAmt = 	CV(ControlSpec(0.01, 3, default:0.9)),
		~pengLPF = 			CV(ControlSpec(10, 200, warp: \exp, default: 50)),
		~pengDelayAmt = 	CV(ControlSpec(0, 1, default: 0.1))
	];

	Pdef(\guitrace, Pbind(
		\gui, Pfunc({
			| e |
			var now = AppClock.seconds;
			~eventList.add((
				\start: now,
				\end: now + e.delta,
				\instrument: e[\instrument].asString,
				\node: e[\bellFreq].round(0.1);
			));
			{ ~eventWindow.refresh() }.e.defer();
		})
	));

	Pdef(\peng, Pbind(
		\instrument, \peng,
		\input, ~bus.index,
		\bellFreq, Pseq([0, 0, 4, 9, 0, [0, 8], 5, 7, 9, 9].collect(Scale.partch_o3.degreeToFreq(_ , 98, 0)), inf),
		\dur, 4,
		\legato, 2,
		\amp, ~pengAmp,
		\noiseLPF, ~pengNoiseLPF,
		\lpf, ~pengLPF,
		\decayAmt, ~pengDecayAmt,
		\noiseAmt, ~pengNoiseAmt,
		\delayAmt, ~pengDelayAmt,
	));

	Pdef(\note1, Pbind(
		\bellFreq, Pseq([
			-8, -8, -8, -8, -8, -6, -6,
		].collect(Scale.partch_o2.degreeToFreq(_ , 98, 0)), inf)
	));

	Pdef(\note2, Pbind(
		\bellFreq, Pseq([
			0, 0, -0, -0, -1, -6, -6, -6, -6, -6, -6,
		].collect(Scale.partch_o2.degreeToFreq(_ , 98, 0)), inf)
	));

	Pdef(\noteMain, Pbind(
		\bellFreq, Pseq([
			0, 0, 0, -1, -2, -2,
			0, 0, 0, -2, -3, -3
		].collect(Scale.partch_o2.degreeToFreq(_ , 98, 0)), inf)
	));

	Pdef(\pengGroup, (\group: ~pengGroup));

	~patterns = [
		Pdef(\guitrace) <> Pdef(\note1) <> Pdef(\pengGroup) <> Pdef(\peng),
		Pdef(\guitrace) <> Pdef(\note2) <> Pdef(\pengGroup) <> Pdef(\peng),
		Pdef(\guitrace) <> Pdef(\noteMain) <> Pdef(\pengGroup) <> Pdef(\peng),
	];

	Pdef(\mainPat).clear();
	//Pdef(\mainPat, ~patterns[0])
	{ EnvirWindow.update(currentEnvironment) }.defer;
});


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// FREE
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
State(\peng).freeActions.add({
	~eventWindow.close();
	~lc.free;
});

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// START
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
State(\peng).startActions.add({

	[
		\amp, ~pengAmp,
		\decayAmt, ~pengDecayAmt,
		\noiseLPF, ~pengNoiseLPF,
		\lpf, ~pengLPF,
		\noiseAmt, ~pengNoiseAmt,
		\delayAmt, ~pengDelayAmt,
	].connectToNode(Server.default, ~pengGroup.nodeID);

	~patternButtons = ~lc.buttons[5..12];
	~resources.add(
		~patternGroup = CVModalGroup(*~patternButtons)
	);

	~patterns.do({
		| pat, i |
		~patternButtons[i].default();
		~patternButtons[i].toggle = true;
		~patternButtons[i].cv.action_({ |cv| "%: %".format(i, cv.item) });
		~patternButtons[i].buttonOnActions.add({
			|cv|
			"pattern on %: %".format(i, cv.value).postln;
			Pdef(\mainPat, pat);
		});
		~patternButtons[i].buttonOffActions.add({
			|cv|
			"pattern off %: %".format(i, cv.value).postln;
		});
	});

	~knobs = List().addAll(
		~driverControls.collect({
			|cv, i|
			~lc.knobs[(i * 4) + 3].cv = cv;
		})
		++ ~pengControls.collect({
			|cv, i|
			~lc.knobs[(i * 4) + 2].cv = cv;
		})
	);

	~driverSynth.notNil.if({ ~driverSynth.release() });
	~driverSynth = Synth.controls(\driver, args: [
		\pengOut: ~bus.index,
		\cymbalIn: ~cymbalBus.index,
		\gate: 1,
		\rate: 8,
		\amp: ~driverAmp,
		\freq: ~driverFreq,
		\decay: ~driverDecay,
		\double: ~driverDouble,
		\noiseAmt: ~driverNoiseAmt
	]);

	~cymbalEvent = (
		\instrument: \cymbal,
		\out: ~cymbalBus.index,
		\amp: 0.8,
	).cvSynth;

	~pattern = Pdef(\mainPat);
	~pattern.play;

	{ EnvirWindow.update(currentEnvironment) }.defer;
});


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// STOP
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

State(\peng).stopActions.add({
	~driverSynth.release;
	~driverSynth = nil;
	~pattern.stop;
	~patternButtons.do(_.cv_(nil));
	~knobs.do(_.cv_(nil));
	~pengMappings.do(_.remove);
});


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

State(\peng).doInit();
EnvirWindow.show()
)


