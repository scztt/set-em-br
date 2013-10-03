//MultiStateManager(\perf).switch(State(\peng));
EnvirWindow.update(currentEnvironment);

(
State(\peng).clear;
State(\peng).autoEnvirWindow = true;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// INIT
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
State(\peng).initActions.add({
	/*~eventWindow = Window().layout_(VLayout(nil)).front();

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
		//~eventWindow.refresh();
	};

	r = Routine({
		inf.do({
			~eventUpdate.();
			(1/60).wait;
		});
	}).play(AppClock);

	~eventWindow.onClose_({ r.stop });
*/

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
		whiteAmt = 0.1, forward = 0;

		var in, impulse, decay, noise, freq, freqs, amps, decays, verbSig, sig,
		delayTimes, delayAmts, delaySpike, env, sigForComb, noiseLPFadjust, positionEnv, positionWidth;

		env = EnvGen.kr(Env([0, 1, 1, 0], [1, 0.1, 8], releaseNode:2), gate:gate, doneAction:2);
		freq = bellFreq;

		in = In.ar(input) * env;

		// in = LeakDC.ar(in + Mix(CombC.ar(LeakDC.ar(in), 0.1, 1 / [0.3,2,4,8,12,20], 2, 0.001)));

		in = in * (0.4 + HardCompress.ar(
			((FreqShift.ar(in * env, -60) * LPF.ar(PinkNoise.ar(noiseAmt), lpf * 6))),
			speed: 0.1
		));
		noiseLPFadjust = noiseLPF.linlin(10, 1000, 0.dbamp, -6.dbamp);

		in = LeakDC.ar(in + LPF.ar(in.pow(2), noiseLPF, 5)).tanh;
		Amplitude.ar(in).round(0.1);
		in = noiseLPFadjust * env * in;
		in = Compander.ar(in, in, 0.6, 1, 1/6, 0.01);

		//decay = Decay.ar(in * 0.01, decayAmt);
		decay = in;
		noise = in + (decay * WhiteNoise.ar(whiteAmt));
		noise = LeakDC.ar(decay + (decay * noise));

		freqs = [0.56, 0.56, 0.92, 0.92, 1.19, 1.7, 2.0, 2.74, 3, 3.76, 4.07, 5.3] * freq;
		freqs[1] = freqs[1] + 1; freqs[3] = freqs[3] + 1.7;
		amps = [1, 0.67, 1.35, 1.8, 2.67, 1.67, 1.46, 1.33, 1.33, 1.0, 1.33, 0.3];
		decays = [1, 0.9, 0.65, 0.55, 0.325, 0.35, 0.25, 0.2, 0.15, 0.1, 0.075, 0.2];

		sig = DynKlank.ar(`[freqs, amps, decays], in.tanh + noise, decayscale: decayAmt, freqscale:1) * 0.001;
		sig = Limiter.ar(sig, -12.dbamp);
		sig = Compander.ar(sig * env, sig, 1, 1, 1/8) * 0.5;
		sig = LeakDC.ar(sig);

		sigForComb = sig * env;
		sig = sig + [
			CombC.ar(in * sigForComb, 0.4, (bellFreq * [1, 2, 3]).reciprocal, 0.3).sum,
			CombC.ar(in * sigForComb, 0.4, (bellFreq * [1.001, 2.0032, 3.0104]).reciprocal, 0.31).sum;
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
		in = in.tanh;
		verbSig = FreeVerb.ar(sig * 0.5, 0.8, 0.4);
		sig = (1 * sig)
		+ (0.9 * verbSig)
		+ (0.9 * HardCompress.ar((verbSig * 0.3) + (in * LPF.ar( PinkNoise.ar(0.25), lpf))));
		sig = sig * 0.2;
		sig = sig * IEnvGen.kr(Env([0.dbamp, -4.dbamp, -12.dbamp], [700, 2000]), bellFreq).min(1).max(0);

		// delaySpike
		delaySpike = LagUD.ar(Trig1.ar(LFNoise2.ar(6).range(0, 1) - delayAmt, 0.1), 0.01, 1.7);
		delayTimes = [0.497, 1, 2, 3, 4, 5] * (4 / bellFreq);
		delayAmts = [delaySpike.linlin(0, 1, 1, 0.15)] ++ (delaySpike.linlin(0, 1, 0, 0.65) ! 5);

		sig = sig + (0.4 * [
			Mix(CombC.ar(sig[0] * delaySpike, 0.1, delayTimes, delayAmts)),
			Mix(CombC.ar(sig[1] * delaySpike, 0.1, delayTimes, delayAmts)),
		]);

		// Final env and amp
		sig = sig * env;
		sig = LeakDC.ar(sig * amp);

		// Panning
		positionEnv = EnvGen.kr(Env([1, 0.4, 0.4 - (forward * 0.4)], [0.35, 0.65]), timeScale: dur);
		positionWidth = forward + 2.5;

		sig = [
			PanArray.ar(4, sig[0], positionEnv, 1, positionWidth),
			PanArray.ar(4, sig[1], positionEnv, 1, positionWidth)
		].flop.flatten;

		Out.ar(0, sig);
	}).add;

	SynthDef(\driver, {
		arg out = 0, pengOut = 0, cymbalIn, gate = 0, amp = 1, freq = 6300, rate = 8, decay = 0.9, double = 0, noiseAmt = 0.2,
		feedAmt = 0.7, delayLevel = 0, hiss = 0, hissVol = 0;
		var sig, imp, multiImp, cymbalGate, multiAmt, delayLevels, delaySig, delayIn, mixedSig, hissEnv, hissSig, driverEnv, hissAmpEnv;

		noiseAmt = noiseAmt * LFNoise2.kr(0.6).range(0.95, 1.05);
		freq = freq.lag(0.2);

		imp = Impulse.ar(rate, LFNoise2.kr(8).pow(8) * 0.15) + (double * Impulse.ar(rate));

		imp = Decay.ar(imp, LFNoise2.kr(1).range(decay * 0.2, decay));
		//imp = RLPF.ar(imp, freq, 1000 / freq);
		imp = BLowPass4.ar(imp, freq, 1000 / freq);
		multiAmt = max(0, double - 0.5) * 2;
		multiImp = Mix(DelayN.ar(imp, 0.3, 1 / [2, 3, 5, 8, 9, 12, 14, 22, 25] * multiAmt)) * (1 / 9);
		imp = XFade2.ar(imp, multiImp, multiAmt * 2 - 1);

		sig = SinOsc.ar(imp.range(80, 40), mul: imp);
		sig = Compander.ar(sig, sig, 0.75, 1/4, 1/4, clampTime: 0.2, relaxTime: 1);
		sig = sig + (imp * (
			LPF.ar(
				WhiteNoise.ar(IEnvGen.kr(Env([-30, -29, -15, -15], [0.25, 0.25, 0.5]), noiseAmt).dbamp),
				noiseAmt.forceRange(5, 100)
			)
			+ HPF.ar(
				WhiteNoise.ar(IEnvGen.kr(Env([-100, -70, -40], [0.5, 0.5]), noiseAmt).dbamp),
				noiseAmt.forceRange(3000, 12000)
			)
		));

		sig = sig + HPF.ar(CombC.ar(sig * LFNoise2.kr(0.1).pow(4), 3, 2.1, 3), 700);

		hissEnv = EnvGen.kr(Env([0, 1, 1, 0], [0.03, 0.01, 0.001], curve: \sin, releaseNode: 2), gate: hiss > 0);
		hissAmpEnv = EnvGen.kr(Env([0.0001, 0.05,  1, 0.00001], [0.1, 1], \exp, releaseNode: 2), gate: hiss > 0, timeScale: 5 + (hissVol * 30));
		driverEnv = EnvGen.kr(Env([1, 0.05, 0.05, 1], [0.3, 0.3, 0.001], curve: \sin), gate: (1 - hiss) > 0);

		hiss = WhiteNoise.ar(0.8) + (WhiteNoise.ar(0.2) * PinkNoise.ar(0.2));

		//hiss = hiss * 20.collect({ LPF.ar(LFPulse.ar(LFNoise2.ar(Rand(1, 3)).range(8, 15)), 800) });
		hiss = Mix(hiss);
		hiss = HPF.ar(hiss, 10000 - (hissAmpEnv * 6000)) * (1 + (0.5 * Decay.ar(Dust.ar(hissAmpEnv * 30), 0.06)));
		hiss = hiss + LPF.ar(LFSaw.ar(45 + [-20, 0, 20, 40, 60] - 8).sum, 100 + (hissAmpEnv * 400));
		hiss = hiss * (hissVol + 0.5) * hissAmpEnv;

		sig = XFade2.ar(sig * driverEnv, hiss, hissEnv.linlin(0, 1, -1, 1));

		Out.ar(pengOut, sig * [1, 1]);

		delayLevels = delayLevel ! 8;
		delayIn = LocalIn.ar(8);
		delaySig = [0.5, 0.51, 1.01, 1.51, 2.332, 3.1, 3.333, 4.5].collect({
			| delayTime, i |
			var a, b, c, d, e, f, g, h, n, depth, l, r, dsig;
			dsig = DelayC.ar((delayIn[i] * feedAmt), delayTime, delayTime);
			dsig = LeakDC.ar(dsig);
			dsig = HPF.ar(dsig, 400);
			depth = LFNoise2.kr(Rand(0.14, 0.2)).range(0, 1);
			#l, r = Pan2.ar(dsig, Rand(0.2, 0.1));

			[
				PanArray.ar(4, l, depth),
				PanArray.ar(4, r, depth)
			].flop.flatten;
		}).sum;

		LocalOut.ar(delaySig.collect(_ + (sig)) * delayLevels);

		mixedSig = (amp.lag(0.05) * 0.25 * (sig ! 8)) + delaySig;
		mixedSig = mixedSig * EnvGen.kr(Env([0, 1, 1, 0], [0.1, 1, 3], releaseNode:2), gate:gate, doneAction:2);

		Out.ar(out, mixedSig);
	}).add();

	~lc.notNil.if({ ~lc.free });

	~resources = SparseArray();
	~resources.addAll([
		~lc = LCDevice(),
		~lc.knobs.do(_.ringStyle_(\fill));
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
		~driverDouble = 	CV(ControlSpec(0, 1, default: 0)),
		~driverDelayLevel = CV(ControlSpec(0, 0.5, default: 0)),
		~driverFeedAmt = 	CV(ControlSpec(0, 0.75, default: 0.5)),
	];

	~pengControls = [
		~pengAmp = 			CV(\amp.asSpec),
		~pengNoiseLPF = 	CV(ControlSpec(10, 1000, warp:\exp, default: 100)),
		~pengDecayAmt = 	CV(ControlSpec(0.1, 10, default: 1)),
		~pengNoiseAmt = 	CV(ControlSpec(0.01, 3, default:0.9)),
		~pengLPF = 			CV(ControlSpec(10, 200, warp: \exp, default: 50)),
		~pengDelayAmt = 	CV(ControlSpec(0, 1, default: 0.1)),
		~pengForward = 		CV(ControlSpec(0, 1, default: 0.1)),
	];

	~hissVol = CV(ControlSpec(0, 1, \db));
	~hissTrig = CV(ControlSpec(0, 1));

	Pdef(\peng, Pbind(
		\instrument, \peng,
		\input, ~bus.index,
		\bellFreq, Pseq([0, 0, 4, 9, 0, [0, 8], 5, 7, 9, 9].collect(Scale.partch_o3.degreeToFreq(_ , 98, 0)), inf),
		\dur, 16,
		\legato, 1.5,
		\amp, ~pengAmp,
		\noiseLPF, ~pengNoiseLPF,
		\lpf, ~pengLPF,
		\decayAmt, ~pengDecayAmt,
		\noiseAmt, ~pengNoiseAmt,
		\delayAmt, ~pengDelayAmt,
		\forward, ~pengForward,
	));

	~patterns = [
		nil,

		Pdef(\noteA, Pbind(
			\bellFreq, Pseq([
				4, 4, 4, 4, 4, 4, 2, 2,
			].collect(Scale.partch_o2.degreeToFreq(_ , 98, -1)), inf)
		)),

		Pdef(\noteB, Pbind(
			\bellFreq, Pseq([
				[4, 6.3], 4, 4, [4, 8], 4, 4, [2, 8], 2, 2,   // 2,8 is off?
			].collect(Scale.partch_o2.degreeToFreq(_ , 98, -1)), inf)
		)),

		Pdef(\noteC, Pbind(
			\bellFreq, Pseq([
				[4, 8], 4, [4, 10], 4, [2, 10], 2, 2, [2, 8], 8,
			].collect(Scale.partch_o2.degreeToFreq(_ , 98, -1)), inf)
		)),

		Pdef(\noteD, Pbind(
			\bellFreq, Pseq([
				[0, 6, 11], [6, 11], 11, [-2, 11], [-2, 11], [-3, 11], [-3, 11]  // bad at end?
			].collect(Scale.partch_o2.degreeToFreq(_ , 98, -1)), inf)
		)),


		Pdef(\noteE, Pbind(
			\bellFreq, Pseq([
				[-3, 11], [11, 16, 22], [11, 16]   // ???
			].collect(Scale.partch_o2.degreeToFreq(_ , 98, -2)), inf)
		)),

		Pdef(\noteF, Pbind(
			\bellFreq, Pseq([
				11, 11, 11, 11
			].collect(Scale.partch_o2.degreeToFreq(_ , 98, -2)).post, inf)
		)),

		Pdef(\noteG, Pbind(
			\bellFreq, Pseq([
				[11, 35], [11, 34.96], [11, 34.93], [11, 34.8], [11, 34], [11, 33.8], [11, 31.78]  // high too loud
			].collect(Scale.partch_o2.degreeToFreq(_ , 98, -2)).post, inf)
		)),

		Pdef(\noteH, Pbind(
			\bellFreq, Pseq([
				[11, 35, 29], 	 [11, 34.96, 29.1], [11, 34.91, 29.13], [11, 34.8, 29.5],
				[11, 34, 29.53], [11, 33.8, 29.8],  [11, 33.78, 30.1],  [11, 33.5, 30.5]
			].collect(Scale.partch_o2.degreeToFreq(_ , 98, -2)).post, inf)
		)),

		Pdef(\noteI, Pbind(
			\bellFreq, Pseq([
				[15, 34, 28], [15, 34, 28], [16, 34, 27], [15, 34, 27], [15, 34, 27], [15, 34, 27],
			].collect(Scale.partch_o2.degreeToFreq(_ , 98, -2)).post, inf)
		)),

		Pdef(\noteJ, Pbind(
			\bellFreq, Pseq([
				[11, 35], [11, 34.96]
			].collect(Scale.partch_o2.degreeToFreq(_ , 98, -2)).post, inf)
		)),
	];

	Pdef(\pengGroup, (\group: ~pengGroup));

	/////////////////////////////
	// States
	~states = [

		// 1 ////////////////////////////
		e({
			Log(\peng, "peng stopped");
			Pdef(\mainPat).stop();
		}),

		// 2 ////////////////////////////
		e({
			Pdef(\mainPat, Pdef(\noteA) <> Pdef(\pengGroup) <> Pdef(\peng)).play;
		}),

		// 2 ////////////////////////////
		e({
			Pdef(\mainPat, Pdef(\noteB) <> Pdef(\pengGroup) <> Pdef(\peng)).play;
		}),

		// 3 ////////////////////////////
		e({
			Pdef(\mainPat, Pdef(\noteC) <> Pdef(\pengGroup) <> Pdef(\peng)).play;
		}),

		// 4 ////////////////////////////
		e({
			Pdef(\mainPat, Pdef(\noteD) <> Pdef(\pengGroup) <> Pdef(\peng)).play;
		}),

		// 5 ////////////////////////////
		e({
			Pdef(\mainPat, Pdef(\noteE) <> Pdef(\pengGroup) <> Pdef(\peng)).play;
		}),

		// 6 ////////////////////////////
		e({
			Pdef(\mainPat, Pdef(\noteF) <> Pdef(\pengGroup) <> Pdef(\peng)).play;
		}),

		// 7 ////////////////////////////
		e({
			Pdef(\mainPat, Pdef(\noteG) <> Pdef(\pengGroup) <> Pdef(\peng)).play;
		}),

		// 8 ////////////////////////////
		e({
			Pdef(\mainPat, Pdef(\noteH) <> Pdef(\pengGroup) <> Pdef(\peng)).play;
		}),

		// 9 ////////////////////////////
		e({
			Pdef(\mainPat, Pdef(\noteI) <> Pdef(\pengGroup) <> Pdef(\peng)).play;
		}),

		// 10 ////////////////////////////
		e({
			Pdef(\mainPat, Pdef(\noteJ) <> Pdef(\pengGroup) <> Pdef(\peng)).play;
		}),
	];

});


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// FREE
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
State(\peng).freeActions.add({
	~lc.free;
});

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// START
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
State(\peng).startActions.add({

	[
		\amp, ~pengAmp,
		\decayAmt, ~pengDecayAmt,
		\noiseLPF, ~pengNoiseLPF,
		\lpf, ~pengLPF,
		\noiseAmt, ~pengNoiseAmt,
		\delayAmt, ~pengDelayAmt,
	].connectToNode(Server.default, ~pengGroup.nodeID);

	~buttonsArray = ((((0..7) * [4]) +.t [0, 1, 2]).flop.flatten[0..11]);
	~buttonsArray.remove(20);
	~patternButtons = ~buttonsArray.collect({ |b| ~lc.knobs[b].button });

	~lc.knobs[30].cv = ~hissVol;
	~lc.knobs[30].button.cv = ~hissTrig;

	~states.do({
		| state, i |
		~patternButtons[i].default();
		~patternButtons[i].toggle = true;
		~patternButtons[i].buttonOnActions.add({
			Log(\peng, "state on %: %".format(i, state));
			state.value();
		});
	});

	~resources.add(
		~patternGroup = CVModalGroup(*~patternButtons).allowOff_(false)
	);

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
		\noiseAmt: ~driverNoiseAmt,
		\delayLevel: ~driverDelayLevel,
		\feedAmt: ~driverFeedAmt,
		\hiss: ~hissTrig,
		\hissVol: ~hissVol
	]);

	~cymbalEvent = (
		\instrument: \cymbal,
		\out: ~cymbalBus.index,
		\amp: 0.8,
	).cvSynth;

	~pattern = Pdef(\mainPat);
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
	~patternButtons.do({ |b| b.buttonOnActions.clear });
});


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

State(\peng).doInit();
)
