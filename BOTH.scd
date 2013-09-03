(
var chordSequence, chordSequenceLow, chordSequenceHigh, mirror, voiceCount;

voiceCount = 40;

~chordSequence = {
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

mirror = {
	| sig, min=(-1), max=1 |
	var width, middle;
	width = (0.5*(max-min));
	middle = min + width;
	(sig-middle).fold2( width ) + middle
};

SynthDef(\lesser, {
	var pulse, pulse2, phase, noise, noise2, jumps, phases,
	pulseAmt, freqFade, density, sig, freqs, freqMult, fx, clip, filtSig;

	density = \density.kr(0, 1);

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
			(fx.pow(Rand(1, 5)) * 5) + Rand(-0.25, 0.25), chordSequence.(30)
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

	sig = Splay.ar(noise, density.range(0.1, 1));
	sig = LeakDC.ar(sig);
	sig = Compander.ar(sig, sig, \volume.kr(0.7), 1/4, 1/4, 1, 5);

	Out.ar(\out.ir(0), sig);
}).add;

SynthDef(\greater, {
	var pulse, pulse2, phase, noise, noise2, jumps, phases, pulseAmt, freqFade, density, sig, freqs, fx;

	density = \density.kr(0, 1);
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
			(fx.pow(Rand(1, 5)) * 5) + Rand(-0.25, 0.25), chordSequence.(30 + 24)
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
			).range(0.6, 1)
			, density.range(400, 700)
		);
	});
	sig = Splay.ar(noise, density.range(0.1, 1));

	Out.ar(\out.ir, sig);
});
)

(
n.free;
n = Synth(\lesser, [
	\out: 0,
	\density: 0.4
]);

n.set(\density, 0.0);
n.set(\fx, 0.0);
n.set(\clip, 0.99);

)
	// {
	// 	var sig, clip;
	// 	sig = SinOsc.ar(200);
	// 	clip = MouseX.kr(0, 2);
	// 	sig = (
	// 		((sig > 0) * max(sig - clip, 0))
	// 		+ ((sig < 0) * min(sig + clip, 0))
	// 	);
	//
	// }.play;
	//
