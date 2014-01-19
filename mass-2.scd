~voiceCount = 40;
~chordSequence = {
	| base |
	~voiceCount.collect({
		| i |
		[
			Scale.dorian.degreeToFreq(7.rand, base.midicps, 2.rand),
			Scale.dorian.degreeToFreq([1, 4, 6][i % 3], base.midicps, 2.rand),
			Scale.dorian.degreeToFreq([3, 5, 8][i % 3], base.midicps, 2.rand),
			Scale.dorian.degreeToFreq([2, 7, 11][i % 3], base.midicps, 2.3.rand.floor),
			Scale.dorian.degreeToFreq([1, 5, 10][i % 3], base.midicps, 1 + 2.rand.floor),
			Scale.dorian.degreeToFreq([2, 6, 13][i % 3], base.midicps, 1 + 2.rand),
			Scale.dorian.degreeToFreq([2, 4, 6, 13][i % 4], base.midicps, 3.rand),
		]
	});
};

~chordSequenceLow = ~chordSequence.(30);
~chordSequenceHigh = ~chordSequence.(30 + 24);

~kill_bus = Bus.audio(s, 1);

{

}.play(outbus: ~kill_bus);

~less = NodeProxy(s, \audio, 2);
~less.clear;

(
~less.source = {
	var pulse, pulse2, phase, noise, noise2, jumps, phases, density,
	pulseAmt, freqFade, sig, freqs, freqMult, fx, clip, filtSig, volume,
	bSig, a, b, c, d, e, f, g, h,
	killEnv, killSig, kill, good;

	density = \density.kr(0).lag(5);
	fx = \fx.kr(0).lag(5);
	clip = \clip.kr(5).lag(8);
	kill = InFeedback.ar(~kill_bus.index);
	kill = MouseX.kr(0.01, 1);
	//kill = EnvGen.kr(Env.perc(0.01, 10), gate: \t_kill.tr(0)).poll;
	killEnv = kill;
	killSig = RLPF.ar(LFSaw.ar(80) * WhiteNoise.ar, 180, 8) * 2;
	killSig = (1 / killSig) * 0.01;
	killSig = Mirror.ar(killSig, -0.9, 0.9);
	killSig = LPF.ar(killSig, 250);
	killSig = killEnv * killSig;
	good = BinaryOpUGen('==', CheckBadValues.kr(killSig, 0, 0), 0);
	killSig = Gate.ar(killSig, good).poll;

	phase = LFNoise2.kr(0.1).range(0.06, 0.09);
	pulse = (Impulse.ar(3) * WhiteNoise.ar(2)) +
	(Impulse.ar(1, phase) * WhiteNoise.ar(2)) +
	(Impulse.ar(6, phase) * WhiteNoise.ar(1));

	jumps = 2.collect({
		PanAz.ar(
			~voiceCount, pulse,
			pos: LFNoise2.kr(0.06).range(-1,1),
			width: LFNoise2.kr(0.07).range(2 + (density), 2 + (density * 4))
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
			(fx.pow(Rand(1, 5)) * 6) + Rand(-0.25, 0.25), ~chordSequenceLow[i]
		);
	});

	noise = phases.collect({
		| phase, i |
		var sig, degree, freq, freq1, freq2, saw, hpEnv, scale, bump;
		hpEnv = max(0, SinOsc.kr(0.007, phase).abs - density.linlin(0, 1, 0.55, 0.42)).lag(0.2);
		freq = freqs[i];
		if (i < 35) {
			freq = freq * (density.linlin(0, 1, 1.0, 1.06) + [0.03.rand, 0.02.rand, 0.04.rand]);
			saw = LFSaw.ar(freq + (50 * killSig)).sum * density.range(0.4, 1.0);
		} {
			freq = freq * (density.range(1, 1) + [0.015.rand, 0.01.rand, 0.021.rand]);
			saw = LFPulse.ar(freq + (50 * killSig), 0, density.range(0, 0.99)).sum * max(density - 0.5, 0) * 1;
		};

		sig = saw;
		sig = (sig + (BrownNoise.ar(0.5 + density.linlin(0, 1, 0, 0.5)) * sig)) * hpEnv;
		sig = LPF.ar(sig, max(density.exprange(10, 14000) * hpEnv, 10));
		filtSig = HPF.ar(sig, clip.range(500, 18000), mul: clip.range(1, 4.0)) +
		LPF.ar(sig, clip.range(20000, 40), mul:0);

		sig = XFade2.ar(sig, filtSig, clip.range(-1, 1));

		sig * LPF.ar(
			LFPulse.ar(
				[20, 30, 60].choose,
				(i % 2) * 0.5,
				LFNoise2.kr(0.1).exprange(density.range(0.9, 0.3) * clip.range(1, 0.01), clip.range(1, 0.001))
			).range(0.6 - clip.exprange(0.01, 0.6), 1),
			20 + (density.range(40, 600) * clip.range(1, 0.01))
		);
	});

	volume = \volume.kr(0.7).lag(0.5);
	sig = noise.clump(2).collect({
		| s, i |
		var leftSide, rightSide, pan;
		pan = i / (noise.size / 2);
		leftSide = PanArray.ar(4, s[0], pos: pan, width: density.linlin(0, 1, 2, 3));
		rightSide = PanArray.ar(4, s[1], pos: pan, width: density.linlin(0, 1, 2, 3));
		[leftSide, rightSide].flop.flatten;
	});

	sig = Mix(sig);
	sig = [sig[0] + sig[2], sig[1] + sig[3]];
	sig = Compander.ar(sig, sig.sum / 8, 0.6, 1/6, 1/8, 1, 5);
	sig = -16.dbamp * sig * volume * EnvGen.kr(Env([0, 1, 1, 0], [10, 5, 20], releaseNode: 2),
		gate: \gate.kr(1),
		doneAction: 2
	);

	Out.ar(\out.ir(0), sig);
};
)

~less.set(\density, 0.7);
~less.set(\fx, 0.7);
~less.set(\volume, 0.8);
~less.set(\clip, 0.1);
~less.set(\t_kill, 1);

~less.play
