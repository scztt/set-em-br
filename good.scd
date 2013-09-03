
s.doWhenBooted({
	var mirror;
	mirror = {
		| sig, min=(-1), max=1 |
		var width, middle;
		width = (0.5*(max-min));
		middle = min + width;
		(sig-middle).fold2( width ) + middle
	};

	{
		var 	pulse, pulse2, phase,
			noise, noise2, jumps, phases,
			pulseAmt, freqFade, density, sig;
		density = EnvGen.kr(
			Env(	[0, 0.1, 0.1, 0.5, 0.8, 0.4, 0.9, 1, 1, 0.1, 0.4, 0],
				[1, 3,    7,     7,    4,    10,  12,   6, 10,15,  15]),
			timeScale:2
		);

		phase = LFNoise2.kr(0.1).range(0.06, 0.09);
		pulse = 	(Impulse.ar(3) * WhiteNoise.ar(2)) +
		 		(Impulse.ar(1, phase) * WhiteNoise.ar(2)) +
		 		(Impulse.ar(6, phase) * WhiteNoise.ar(1)) ;

		jumps = 2.collect({
					PanAz.ar(
						40, pulse,
						pos: LFNoise2.kr(0.06).range(-1,1),
						width: LFNoise2.kr(0.07).range(2,3)
					)
				}).postln.sum.postln;

		jumps = jumps * EnvGen.kr(Env([0,0,1,1],[4,4,20]), timeScale:5);
		phases = jumps.collect({
			| jump |
			(2.0.rand + Integrator.ar(jump.abs.neg*0.2, 1)) % (2*pi);
		});

		pulseAmt = LFNoise2.kr( LFNoise2.kr(0.4).range(0.1,0.5) ).exprange(0.5,2.0);
		Out.kr(10, density);

		noise = phases.collect({
			| phase, i |
			var sig, degree, freq, freq1, freq2, saw, hpEnv, scale;
			hpEnv = max(0, SinOsc.kr(0.007, phase).abs - density.exprange(0.9,0.22) );

			if( i<35, {
				freq = Scale.dorian.degreeToFreq(7.rand, 50.midicps, 2.rand) *
					(density.range(1.0,1.01) + [0.03.rand, 0.02.rand, 0.04.rand]);
				saw = LFSaw.ar(freq).sum * density.range(0.2,1.0);
			},{
				freq = Scale.dorian.degreeToFreq([1,4,5][i%3], 50.midicps, 3) *
					(density.range(1,1) + [0.03.rand, 0.01.rand, 0.02.rand]);
				saw = LFSaw.ar(freq).sum * max(density-0.5,0);
			});

			sig = (WhiteNoise.ar(1) + saw) * hpEnv;
			sig = sig + (jumps[i]*pulseAmt*density.range(0.3,2));
			sig = HPF.ar( sig, 20000 - (density.range(9000,20000)*hpEnv) );
			sig = sig*LPF.ar(
					LFPulse.ar(
						[20,30,60].choose,
						0,
						LFNoise2.kr(0.1).exprange(density.range(0.9, 0.5),1)
					).range(0.6,1)
				, density.range(400,700)
			);
		});
		sig = Splay.ar( noise, density.range(0.1,1) );
		//sig + GVerb.ar( sig, 3, density.exprange(1,10) ) ;
	}.play;

});


{
	var env, sig;
	env = EnvGen.kr(Env.perc(0.01, 22, curve: -8), doneAction:2);
	sig = RLPF.ar(LFSaw.ar(env.range(10, 24) + Rand(0, [2.0, 3.0])), 40,  0.01) * env * 0.1;
	sig = sig.fold2(0.6);
	sig = RLPF.ar(sig, 60);
	sig = HPF.ar(sig, 17);
}.play;