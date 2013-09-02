~mirror = {
	| sig, min=(-1), max=1 |
	var width, middle;
	width = (0.5*(max-min));
	middle = min + width;
	(sig-middle).fold2( width ) + middle
};

SynthDef(\lower, {

	var pulse, pulse2, phase, noise, noise2, jumps, phases,
	pulseAmt, freqFade, density, sig, freqs, freqMult, fx, clip;

	density = \density.kr(0);
	fx = \fx.kr(0);

	// density = EnvGen.kr(
	// 	Env(	[0.0, 0.1, 0.5, 0.3, 0.9, 0.4, 1.1, 1, 1.3, 0.1, 0.4, 0],
	// 	[1, 3,    7,     7,    4,    10,  12,   6, 10, 15,  15]),
	// 	timeScale:5
	// );
	// density.poll(1);

	phase = LFNoise2.kr(0.1).range(0.06, 0.09);
	pulse = (Impulse.ar(3) * WhiteNoise.ar(2)) +
	(Impulse.ar(1, phase) * WhiteNoise.ar(2)) +
	(Impulse.ar(6, phase) * WhiteNoise.ar(1)) ;

	jumps = 2.collect({
		PanAz.ar(
			40, pulse,
			pos: LFNoise2.kr(0.06).range(-1,1),
			width: LFNoise2.kr(0.07).range(2,3)
		)
	});

	jumps = jumps * EnvGen.kr(Env([0, 0, 1, 1], [4, 4, 20]), timeScale:5);
	phases = jumps.collect({
		| jump |
		(2.0.rand + Integrator.ar(jump.abs.neg * 0.2, 1)) % (2 * pi);
	});

	pulseAmt = LFNoise2.kr(LFNoise2.kr(0.1).range(0.05, 0.2)).exprange(0.5, 1.0);

	freqs = phases.collect({
		| p, i |
		Select.kr(
			(fx.pow(Rand(1, 5)) * 5) + Rand(-0.25, 0.25),
			[
				Scale.dorian.degreeToFreq(7.rand, 30.midicps, 2.rand),
				Scale.dorian.degreeToFreq([1, 4, 5][i % 3], 30.midicps, 2.rand),
				Scale.dorian.degreeToFreq([4, 7, 8][i % 3], 30.midicps, 2),
				Scale.dorian.degreeToFreq([2, 4, 10][i % 3], 30.midicps, 2),
				Scale.dorian.degreeToFreq([2, 4, 10][i % 3], 30.midicps, 3.rand),
			]
		);
	});

	noise = phases.collect({
		| phase, i |
		var sig, degree, freq, freq1, freq2, saw, hpEnv, scale, bump;
		hpEnv = max(0, SinOsc.kr(0.007, phase).abs - density.exprange(0.9,0.62) ).lag(0.2);

		if(i < 35, {
			// freq = Scale.dorian.degreeToFreq(7.rand, 30.midicps, 2.rand) *
			freq = freqs[i] * (density.range(1.0,1.01) + [0.03.rand, 0.02.rand, 0.04.rand]);
			saw = LFSaw.ar(freq).sum * density.range(0.2,1.0);
			},{
				// freq = Scale.dorian.degreeToFreq([1, 4, 5][i % 3], 30.midicps, 2) *

				freq = freqs[i] * (density.range(1,1) + [0.015.rand, 0.01.rand, 0.021.rand]);
				saw = LFPulse.ar(freq, 0, density.range(0,0.9)).sum * max(density-0.5,0) * 2;
		});

		sig = (BrownNoise.ar(1) + saw) * hpEnv;
		sig = LPF.ar( sig, max( density.exprange(10,12000)*hpEnv, 10) );
		sig = sig*LPF.ar(
			LFPulse.ar(
				[20,30,60].choose,
				0,
				LFNoise2.kr(0.1).exprange(density.range(0.9, 0.5),1)
			).range(0.6,1)
			, density.range(40,700)
		);
		//sig = sig + (TwoTube.ar(sig, 0.5, loss: 0.3, d1length: 800, d2length: 1640) * MouseX.kr(0, 1));
	});
	sig = Splay.ar( noise, density.range(0.1,1) );
	sig = LeakDC.ar(sig);
	SendTrig.ar( sig-1, 0 );
	SendTrig.ar( sig.neg-1, 0 );
	sig + GVerb.ar( sig, 3, density.exprange(1,20) ) ;
	sig;
}.play;
)