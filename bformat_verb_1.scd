(
SynthDef(\BFormatReverb, {
	arg in_bus, mix, predelay, cutoff, t60low, t60high, diffusion, diffusionLR, diffusionFB, mod, out_bus, gate = 1, insert;
	var local, in, sum, delays, delayMod, allpassDelays, lateAllpassDelays;
	var allpassCoefEarly, allpassCoefLate;
	var g0late, g1late, a1late, b0late;
	var matrix, temp;
	var minDelay, maxDelay, numDelays, foo;
	var minAllpassDelay, maxAllpassDelay, numAllpassDelays;
	var minLateAllpassDelay, maxLateAllpassDelay, numLateAllpassDelays;
	var earlyVec, outVec;
	var diffusionLRcos, diffusionLRsin, diffusionFBcos, diffusionFBsin, globenv;

	diffusionLR = diffusionLR * 0.25pi;
	diffusionFB = diffusionFB * 0.25pi;

	diffusionLRcos = diffusionLR.cos;
	diffusionLRsin = diffusionLR.sin;
	diffusionFBcos = diffusionFB.cos;
	diffusionFBsin = diffusionFB.sin;

	minDelay = 0.04402;
	maxDelay = 0.115905;
	numDelays = 16;
	foo = (maxDelay/minDelay)**(1.0/numDelays);

	delays = Array.newClear(numDelays);
	for(0, 3, {arg j;
		for(0, 3, {arg i;
			delays[(4*j) + i] = minDelay*(foo**((4*i) + j));
		});
	});

	minAllpassDelay = 0.00617;
	maxAllpassDelay = 0.0211;
	numAllpassDelays = 16;
	foo = (maxAllpassDelay/minAllpassDelay)**(1.0/numAllpassDelays);

	allpassDelays = Array.newClear(numAllpassDelays);
	for(0, 3, {arg j;
		for(0, 3, {arg i;
			allpassDelays[(4*j) + i] = minAllpassDelay*(foo**((4*i) + j));
		});
	});

	g0late = exp(-6.90775527898214*(delays)/t60low);
	g1late = exp(-6.90775527898214*(delays)/t60high);
	a1late = (g1late-g0late)/(g1late+g0late);
	b0late = (1.0+a1late)*g0late;

	allpassCoefEarly = -3.0*(allpassDelays/log10(0.6*diffusion));

	mod = LFTri.kr([0.41, 0.47, 0.53, 0.552], 0.0, mod*0.0012);
	delayMod = delays + (mod *.x [1, -1] +++ [0, 0, 0, 0]).flatten;
	in = In.ar(in_bus, 4);
	matrix = [
			[1, 1, 1, 1],
			[1, 1, 1.neg, 1.neg],
			[1, 1.neg, 1, 1.neg],
			[1, 1.neg, 1.neg, 1]
			] * 0.5;
	earlyVec = matrix.collect({ arg mat;
				Mix(in * mat);
			});
	earlyVec = OnePole.ar(DelayN.ar(earlyVec, 1.0, predelay), exp(-2.0pi*cutoff/SampleRate.ir));
	for(0, 3, {arg j;
		for(0, 3, {arg i;
			earlyVec[j] = AllpassN.ar(earlyVec[j], allpassDelays[(4*i)+j], allpassDelays[(4*i)+j], allpassCoefEarly[(4*i)+j]);
		});
	});
	local = LocalIn.ar(16) +	[earlyVec[0], 0.0, 0.0, 0.0,
								earlyVec[1], 0.0, 0.0, 0.0,
								earlyVec[2], 0.0, 0.0, 0.0,
								earlyVec[3], 0.0, 0.0, 0.0];
	local = local.collect({
		|sig|
		var base, amp, adjust, phase;
		base = \base.kr(200);
		amp = Amplitude.kr(BPF.ar(sig, base, 13 / base)) - 0.0001;
		amp = max(amp, 0);
		amp = Latch.ar(amp, Dust.ar(5));
		adjust = (2.3 - (amp * 1000)).lagud(4, 0.001).max(-90);
		phase = { 1.0.rand + Latch.kr(LFNoise2.kr(1), Dust.kr(5)) };
		\notes.kr([1, 4/3, 5/3, 7/3]).do({
			|f|
			sig = MidEQ.ar(
				sig,
				((f * base) + SinOsc.ar(0.1, 0.1 + phase, 5)),
				(13 - adjust) / base,
				adjust
			);
		});
		sig;
	});

	for(0, 3, {arg j;
		sum = 0.0;

		for(0, 3, {arg i;
			sum = sum + local[(4*j)+i];
		});
		for(0, 3, {arg i;
			local[(4*j)+i] = local[(4*j)+i] - (0.5*sum);
		});
	});
	outVec = [local[0], local[4], local[8], local[12]];
	matrix = [
			[1, 1, 1, 1],
			[1, 1, 1.neg, 1.neg],
			[1, 1.neg, 1, 1.neg],
			[1, 1.neg, 1.neg, 1]
			] * 0.5;
	outVec = matrix.collect({ arg mat;
				Mix(outVec * mat);
			});
	globenv = EnvGen.kr(
					Env([0, 1, 0], [3, 4], \sin, 1), gate, doneAction: 2);
	TraceBadValues(outVec);
	Out.ar(out_bus, (In.ar(in_bus, 4)*(1.0-mix)) + (outVec*mix) * globenv);
	local = LeakDC.ar(local);
	forBy(0, 14, 2, {arg i;
		local[i] = FOS.ar(
				DelayC.ar(local[i], delays[i]+0.005, delayMod[i]),
		   b0late[i], 0.0, a1late[i].neg);
		local[i+1] = FOS.ar(
				DelayN.ar(local[i+1], delays[i+1], delayMod[i+1]),
		   b0late[i], 0.0, a1late[i].neg);
	});
	for(0, 3, {arg i;
		temp = [local[i], local[i+4]];
		local[i] = (diffusionLRcos*temp[0]) - (diffusionLRsin*temp[1]);
		local[i+4] = (diffusionLRsin*temp[0]) + (diffusionLRcos*temp[1]);
	});
	for(8, 11, {arg i;
		temp = [local[i], local[i+4]];
		local[i] = (diffusionLRcos*temp[0]) - (diffusionLRsin*temp[1]);
		local[i+4] = (diffusionLRsin*temp[0]) + (diffusionLRcos*temp[1]);
	});
	for(0, 7, {arg i;
		temp = [local[i], local[i+8]];
		local[i] = (diffusionFBcos*temp[0]) - (diffusionFBsin*temp[1]);
		local[i+8] = (diffusionFBsin*temp[0]) + (diffusionFBcos*temp[1]);
	});
	LocalOut.ar(local);
}).add;
)

(
n = {
	arg hardMix = 0.4, impDur=3.1, impDurChaos=3, klankDecay=1, envFix=0,
	octLow = -3, octHigh = 3, combOct=0, octSpeed=3, octChaos=1, lowpass=400;

	var sig, trig, env, envDecay, envDelay, dur, freqA, freqB, durN;

	impDur = LFNoise2.kr(0.8, impDurChaos, impDur).round() * 0.7;
	sig = Impulse.ar(impDur) * 0.8;

	dur = TRand.ar(
		0.8,
		1.25,
		sig
	);
	durN = TRand.ar(0.2, 0.8, sig).pow(TRand.ar(1, 3, sig));

	freqA = (TRand.ar(0, 2, sig) * 4 + 65).round();
	freqB = (freqA + (TRand.ar(-1, 0, sig).round() * 5));

	// freqA = (TRand.ar(0, 1, sig) + 95).round();
	// freqB = (freqA + (TRand.ar(-4, 0, sig).round() * 3));

	freqA = freqA.midicps; freqB = freqB.midicps;
	trig = Trig1.ar(sig, 0.1);
	env = EnvGen.ar(Env.perc(1), gate: trig, timeScale:dur);
	envDecay = EnvGen.ar(Env([1, 0.4, 1, envFix * 0.0001], [0.2, 0.7, 0.1]), gate: trig, timeScale:dur);
	envDelay = EnvGen.ar(Env(
		[	freqA, 	freqA, 	freqA, 	freqB, 	freqB, 	TRand.kr(5, 22, sig)],
		[	0.0001, durN, 	0.01, 	1-durN, 0.01 	]
	), gate: trig, timeScale:dur);
	envDelay = envDelay * (2.pow(LFDNoise3.ar(LFDNoise3.ar(1, octChaos, octSpeed)).range(octLow, octHigh).round().poll));
	sig = LPF.ar(sig, lowpass);
	sig = XFade2.ar(
		sig,
		CombC.ar(sig, 0.5, (envDelay * 2.pow(combOct)).reciprocal, envDecay * -10),
		hardMix * 2 - 1
	);
	sig = DynKlank.ar(
		`[[1, 2, 3, 4, 5], [1, 1, 1, 1, 1], [1, 0.5, 0.4, 0.2, 0.1]],
		sig,
		freqscale:envDelay,
		decayscale:envDecay * klankDecay
	);
	sig = sig + PitchShift.ar(sig, pitchRatio:2, mul: 0.25 * LFPulse.kr(1, 0, 0.5));
	sig = LeakDC.ar(sig);
	sig = Compander.ar(sig, sig, 0.7, 1, 1/2);
	sig = Mirror.ar(sig, -1, 1);
	sig = MoogFF.ar(sig, 5 + (env * 3000), 3.0);
	Out.ar(10,
		PanB.ar(sig, LFSaw.kr(0.1, 0, 2, -1))
	);
}.play;
r = Synth(\BFormatReverb, args: [
	\in_bus, 10,
	\mix, 0.65,
	\predelay, 0.15,
	\cutoff, 100,
	\t60low, 15.5,
	\t60high, 2.5,
//	\diffusion, 1.1,
	\diffusionLR, 1,
	\diffusionFB, 1,
	\out_bus, 5,
]);


{
	B2UHJ.ar(*InFeedback.ar(5, 3))
}.play;

{
	inf.do({
		r.set(\base, [100, 200, 300, 400, 500, 600].choose.postln);
		45.wait;
	})
}.fork;

{
	inf.do({
		r.set(\notes, [
			[1, 5/3, 7/3, 9/3 ],
			[1, 9/4, 7/4, 18/4 ]
		].choose.postln);
		35.wait;
	})
}.fork;

n.set(\lowpass, 1565);
n.set(\hardMix, 1);
n.set(\combOct, -3);
n.set(\octLow, 5);
n.set(\octHigh, 5);
n.set(\klankDecay, 3.9);

n.set(\octSpeed, 6);
n.set(\octChaos, 6);
n.set(\impDur, 16);
n.set(\impDurChaos, 2);

);

