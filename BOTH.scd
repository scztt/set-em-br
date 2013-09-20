////////////////////////////////////////////////////////////////////////////////
// SYNTHDEFS
State(\mass).clear;

State(\mass).initActions.add({
	var chordSequence, chordSequenceLow, chordSequenceHigh, mirror, voiceCount;

	voiceCount = 40;
	chordSequence = {
		| base |
		voiceCount.collect({
			| i |
			[
				Scale.dorian.degreeToFreq(7.rand, base.midicps, 2.rand),
				Scale.dorian.degreeToFreq([1, 4, 5][i % 3], base.midicps, 2.rand),
				Scale.dorian.degreeToFreq([4, 7, 8][i % 3], base.midicps, 2),
				Scale.dorian.degreeToFreq([2, 4, 10][i % 3], base.midicps, 2),
				Scale.dorian.degreeToFreq([2, 4, 10][i % 3], base.midicps, 3.rand),
			]
		});
	};
	chordSequenceLow = chordSequence.(30);
	chordSequenceHigh = chordSequence.(30 + 24);

	SynthDef(\lesser, {
		var pulse, pulse2, phase, noise, noise2, jumps, phases, density,
		pulseAmt, freqFade, sig, freqs, freqMult, fx, clip, filtSig, volume;

		density = \density.kr(0).lag(1);
		fx = \fx.kr(0);
		clip = \clip.kr(1);

		phase = LFNoise2.kr(0.1).range(0.06, 0.09);
		pulse = (Impulse.ar(3) * WhiteNoise.ar(2)) +
		(Impulse.ar(1, phase) * WhiteNoise.ar(2)) +
		(Impulse.ar(6, phase) * WhiteNoise.ar(1)) ;

		jumps = 2.collect({
			PanAz.ar(
				voiceCount, pulse,
				pos: LFNoise2.kr(0.06).range(-1,1),
				width: LFNoise2.kr(0.07).range(2,3)
			)
		}).sum;

		jumps = jumps * EnvGen.kr(Env([0, 0, 1, 1], [4, 4, 20]), timeScale:5);
		phases = jumps.collect({
			| jump |
			(2.0.rand + Integrator.ar(jump.abs.neg * 0.2, 1)) % (2 * pi);
		});

		pulseAmt = LFNoise2.kr(LFNoise2.kr(0.1).range(0.05, 0.2)).exprange(0.5, 1.0);

		freqs = phases.collect({
			| p, i |
			Select.kr(
				(fx.pow(Rand(1, 5)) * 5) + Rand(-0.25, 0.25), chordSequenceLow[i]
			);
		});

		noise = phases.collect({
			| phase, i |
			var sig, degree, freq, freq1, freq2, saw, hpEnv, scale, bump;
			hpEnv = max(0, SinOsc.kr(0.007, phase).abs - density.exprange(0.9, 0.42)).lag(0.2);
			freq = freqs[i];
			if (i < 35) {
				freq = freq * (density.range(1.0, 1.04) + [0.03.rand, 0.02.rand, 0.04.rand]);
				saw = LFSaw.ar(freq).sum * density.range(0.2, 1.0);
			} {
				freq = freq * (density.range(1, 1) + [0.015.rand, 0.01.rand, 0.021.rand]);
				saw = LFPulse.ar(freq, 0, density.range(0, 0.99)).sum * max(density - 0.5, 0) * 2;
			};

			sig = saw;
			sig = (BrownNoise.ar(1) + sig) * hpEnv;
			sig = LPF.ar(sig, max(density.exprange(10, 14000) * hpEnv, 10));
			filtSig = HPF.ar(sig, clip.range(500, 18000), mul: clip.range(1, 4.0)) +
			LPF.ar(sig, clip.range(20000, 40), mul:0);
			sig = XFade2.ar(sig, filtSig, clip.range(-1, 1));

			sig = sig * LPF.ar(
				LFPulse.ar(
					[20,30,60].choose,
					0,
					LFNoise2.kr(0.1).exprange(density.range(0.9, 0.3) * clip.range(1, 0.01), clip.range(1, 0.001))
				).range(0.6 - clip.exprange(0.01, 0.6), 1),
				20 + (density.range(40, 600) * clip.range(1, 0.01))
			);
		});

		volume = \volume.kr(0.7).lag(0.5);
		sig = Splay.ar(noise, density.range(0.1, 1));
		sig = LeakDC.ar(sig);
		sig = Compander.ar(sig, sig, 0.6, 1/6, 1/8, 1, 5);
		sig = -6.dbamp * sig * volume * EnvGen.kr(Env([0, 1, 1, 0], [10, 5, 10], releaseNode: 2),
			gate: \gate.kr(1),
			doneAction: 2
		);

		Out.ar(\out.ir(0), sig);
	}).add;

	SynthDef(\greater, {
		var pulse, pulse2, phase, noise, noise2, jumps, phases, pulseAmt, freqFade, density, sig, freqs, fx, volume;

		density = \density.kr(0).lag(1);
		fx = \fx.kr(0);

		phase = LFNoise2.kr(0.1).range(0.06, 0.09);
		pulse = ((Impulse.ar(3) * WhiteNoise.ar(2)) +
			(Impulse.ar(1, phase) * WhiteNoise.ar(2)) +
			(Impulse.ar(6, phase) * WhiteNoise.ar(1))
		);

		jumps = 2.collect({
			PanAz.ar(
				voiceCount, pulse,
				pos: LFNoise2.kr(0.06).range(-1, 1),
				width: LFNoise2.kr(0.07).range(2, 3)
			)
		}).sum;

		jumps = jumps * EnvGen.kr(Env([0, 0, 1, 1], [4, 4, 20]), timeScale:5);
		phases = jumps.collect({
			| jump |
			(2.0.rand + Integrator.ar(jump.abs.neg * 0.2, 1)) % (2 * pi);
		});

		pulseAmt = LFNoise2.kr(LFNoise2.kr(0.4).range(0.1, 0.5)).exprange(0.5, 2.0);

		freqs = phases.collect({
			| p, i |
			Select.kr(
				(fx.pow(Rand(1, 5)) * 5) + Rand(-0.25, 0.25), chordSequenceHigh[i]
			);
		});

		noise = phases.collect({
			| phase, i |
			var sig, degree, freq, freq1, freq2, saw, hpEnv, scale;
			hpEnv = max(0, SinOsc.kr(0.007, phase).abs - density.exprange(0.9, 0.22));
			freq = freqs[i];

			if (i < 35) {
				freq = freq * (density.range(1.0, 1.01) + [0.03.rand, 0.02.rand, 0.04.rand]);
				saw = LFSaw.ar(freq).sum * density.range(0.2, 1.0);
			} {
				freq = freq * (density.range(1, 1) + [0.03.rand, 0.01.rand, 0.02.rand]);
				saw = LFSaw.ar(freq).sum * max(density - 0.5, 0);
			};

			sig = saw;

			sig = (WhiteNoise.ar(1) + sig) * hpEnv;
			sig = sig + (jumps[i] * pulseAmt * density.range(0.3, 2));
			sig = HPF.ar(sig, 20000 - (density.range(9000, 20000) * hpEnv));
			sig = sig * LPF.ar(
				LFPulse.ar(
					[20, 30, 60].choose,
					0,
					LFNoise2.kr(0.1).exprange(density.range(0.9, 0.5), 1)
				).range(\cut.kr(0.6), 1)
				, density.range(400, 1300)
			);
		});

		volume = \volume.kr(0.7).lag(0.5);
		sig = Splay.ar(noise, density.range(0.1, 1));
		sig = Compander.ar(sig, sig, 0.6, 1/6, 1/8, 1, 5);
		sig = -6.dbamp * sig * volume * EnvGen.kr(Env([0, 1, 1, 0], [10, 5, 10], releaseNode: 2),
			gate: \gate.kr(1),
			doneAction: 2
		);

		Out.ar(\out.ir(0), sig);
	}).add;

	SynthDef(\let, {
		var env, sig;
		env = EnvGen.kr(Env.perc(0.01, 20, curve: -16), doneAction:2);
		sig = RLPF.ar(LFSaw.ar(env.range(30, 44) + Rand(0, [2.0, 3.0])), 40,  0.01) * env * 0.1;
		//sig = sig.fold2(0.6);
		sig = sig.tanh;
		sig = RLPF.ar(sig, 260);
		sig = HPF.ar(sig, 17);
		sig = sig.tanh * 1.4;
		Out.ar(\out.ir([0, 1]), sig);
	}).add;

	Event.parentEvents[\cvSynth] = CVEvent.synthEvent;

	~lc.notNil.if({ ~lc.free });
	~lc = LCDevice();
	~lc.knobs.do(_.ringStyle_(\fill));

	// Play button
	~playButton = ~lc.buttons[4].default;
	~playButton.toggle = true;
	~playButton.buttonOnActions.add({
		State(\mass).doStart();
	});

	~playButton.buttonOffActions.add({
		State(\mass).doStop();
	});

	~controls = [
		~lowVolume = CV(ControlSpec(0, 1, default: 0.7)),
		~lowDensity = CV(ControlSpec(0, 1, default: 0.0)),
		~lowFx = CV(ControlSpec(0, 1, default: 0.0)),
		~lowClip = CV(ControlSpec(0, 1, default: 0.0)),

		~highVolume = CV(ControlSpec(0, 1, default: 0.1)),
		~highDensity = CV(ControlSpec(0, 1, default: 0.0)),
		~highFx = CV(ControlSpec(0, 1, default: 0.0)),
		~highCut = CV(ControlSpec(0, 1, default: 0.0)),
	];

/*	~lowEvent = (
		\instrument:	\lesser,
		\type:	 		\cvSynth,

	).cvSynth;*/

	~highEvent = (
		\instrument: 	\greater,
		\type: 			\cvSynth,

	).cvSynth;

	~letEvent = (
		\instrument: \let
	).cvSynth;

	{ EnvirWindow.update(currentEnvironment) }.defer;
});



////////////////////////////////////////////////////////////////////////////////
// STATES
////////////////////////////////////////////////////////////////////////////////

State(\mass).startActions.add({
	~knobs = [];

	////////////////////////////////////////////////////////////////////////////////
	// low
	~controls[0..3].do({
		|cv, i|
		~knobs.add(
			~lc.knobs[3 + (i * 4)].cv_(cv)
		);
	});

	~lowTrigger = ~lc.buttons[6].default();
	~lowTrigger.toggle = true;
	~lowTrigger.buttonOnActions.add(e{
		"low".postln;
		if (~lowSynth.notNil) { ~lowSynth.release() };

		~lowSynth = Synth.controls(\lesser, [
			\volume: 		~lowVolume,
			\density: 		~lowDensity,
			\fx: 			~lowFx,
			\clip: 			~lowClip
		]);
	});
	~lowTrigger.buttonOffActions.add(e{
		"low off".postln;
		~lowSynth.release;
		~lowSynth = nil;
	});


	////////////////////////////////////////////////////////////////////////////////
	// high
	~controls[4..7].do({
		|cv, i|
		~knobs.add(
			~lc.knobs[2 + (i * 4)].cv_(cv)
		);
	});
	~highTrigger = ~lc.buttons[5].default();
	~highTrigger.toggle_(true);
	~highTrigger.buttonOnActions.add(e{
		"high".postln;
		if (~highSynth.notNil) { ~highSynth.release() };

		~highSynth = Synth.controls(\greater, [
			\volume: 		~highVolume,
			\density: 		~highDensity,
			\fx: 			~highFx,
			\cut: 			~highCut
		]);
	});
	~highTrigger.buttonOffActions.add(e{
		"high off".postln;
		~highSynth.release;
		~highSynth = nil;
	});

	////////////////////////////////////////////////////////////////////////////////
	// let
	~letTrigger = ~lc.buttons[7].default();
	~letTrigger.buttonOnActions.add(e{
		"let".postln;
		~letEvent.play;
	});

});

State(\mass).stopActions.add({
	~highTrigger.cv.value = 0;
	~lowTrigger.cv.value = 0;
	~knobs.do(_.cv_(nil));
});

State(\mass).doInit();

State(\mass).envir.push;


