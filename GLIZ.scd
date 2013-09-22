


///////////////////////////////////////////////////////////////
// SynthDef
State(\gliz).clear();
State(\gliz).autoEnvirWindow = true;


State(\gliz).initActions.add({
	Require("GLIZ-samples", always: true);

	~resources.add(
		~sf = Buffer.read(s, "/Users/fsc/Desktop/SET EM BR/sounds/whidbey-pond.wav"));

	~bulkSynth = {
		arg in, out=0, amp=1, freq=60, width=0.2, thresh=0.5, drown=0.2, pitchAmt=0.5, rev=20;
		var monoIn, sig, inAmp, ampThresh, amount, freqs, widths, maxAmp, localIn;
		freqs = ([ 1, 2, 3, 4, 5, 0.5, 0.333, 0.125, 3.333, 6.666, 4.3452 ]*freq).wrap( 0, 19000 - width );
		//monoIn = ~in.ar(1) ;
		monoIn = in;
		inAmp = Amplitude.kr( BPF.ar( monoIn, freqs, 1/freqs) );
		ampThresh = Slew.kr( DelayL.kr( inAmp, 0.1, 0.1), 10000, thresh );
		amount = drown*Slew.kr( inAmp>ampThresh, 50, 20 );
		sig = Mix.new(
			CombC.ar(
				BPF.ar( monoIn, freqs, (width+( (freq-width)*(drown-amount) ) )/freqs ),
				2, LFNoise2.kr( Lag.kr(inAmp*4, 0.2), 15.0, 40.5 ).reciprocal, 0.5 ) );
		localIn = LocalIn.ar(1);
		in = CombC.ar( monoIn +
			FreqShift.ar( LPF.ar(localIn, freq), 0, 2 ) +
				FreqShift.ar( HPF.ar(localIn, freq), 0, -1 ),
			0.1, freqs.reciprocal, pitchAmt);
		in = LPF.ar( in, freqs*4 );
		maxAmp = (Slew.kr( Amplitude.kr( sig*in, 0.01 ), 90000, 2.3 ).max(0.001));
		LocalOut.ar( Mix.new( (sig*in).tanh*0.2) );
		Pan2.ar(
			FreeVerb.ar( Mix.new( amp*sig*in*(maxAmp.reciprocal)), 0.4, Lag.kr( inAmp*rev, 0.3 ) ),
			LFNoise2.ar( LFNoise2.ar( 1, 1, 1 ))) ;
	};

	SynthDef(\lichenSurface, {
		arg in, out, t_dust = 0, bulk = 0, amp = 0.01;
		var sig, inSig, inSigLow, inFeed, noise, noiseMod, dust, dustEnv;

		dustEnv = EnvGen.kr(Env.perc(0.01, 12), gate: t_dust);
		dust = Dust.ar(dustEnv * 10 + 118) * dustEnv;
		dust = dust + CombC.ar(Decay.ar(Dust.ar(6), 0.001), 0.1, 1/7, 0.2);

		noiseMod = LFNoise2.ar(50);
		noiseMod = noiseMod + (
			sin([1.2, 3, 8, 9] * noiseMod * pi)
		).sum * 0.2;

		inFeed = LocalIn.ar(4) * 0.01;
		inFeed = APF.ar(inFeed, 25, 0.99);
		inFeed = LPF.ar(inFeed, 5000);
		inFeed = BRF.ar(inFeed, 3500);
		inFeed = LeakDC.ar(inFeed);

		inSig = In.ar(in, 2) * noiseMod.range(0.95, 1.0);
		inSig = inSig + inFeed/* + (dust * 0.01)*/;
		inSigLow = LPF.ar(inSig, 100);

		sig = GVerb.ar(inSig, 20.1, 8);
		sig = HPF.ar(sig, 6000);

		noise = (WhiteNoise.ar(0.2) + (BrownNoise.ar() * BrownNoise.ar()) * 0.3) * noiseMod.range(0.75, 1.0);
		noise = noise + dust;
		noise = APF.ar(noise, 101.4, 0.8);

		noise = HPF.ar(noise, 2000) * (1 + sig);
		noise = noise + HPF.ar(WhiteNoise.ar(0.005), 10000);
		noise = PlayBuf.ar(4, ~sf.bufnum, 1, startPos: 0, loop: 1)  * 5000;
		noise = HPF.ar(noise, 12000);
		sig = (noise);
			sig = sig + (0.1 * HardCompress.ar(sig, 0.1, 0.05));
			sig = XFade2.ar(sig, ~bulkSynth.value(sig), bulk * 2 - 1);
		sig = sig * 0.1;
		LocalOut.ar(sig);
		Out.ar(out, (sig + inSig + inSigLow) * amp);
	}).add;


	~cymbal = {
		arg drive;
		var lodriver, locutoffenv, hidriver, hicutoffenv, freqs, res, thwack, gdrive;

		drive = drive.abs;
		gdrive = Gate.ar(drive, drive);

		locutoffenv = EnvGen.ar(Env.perc(gdrive, 5), gate:drive, levelScale:gdrive) * 20000 + 10;
		lodriver = LPF.ar(WhiteNoise.ar(0.1), locutoffenv);

		hicutoffenv = 10001 - (EnvGen.ar(Env.perc(1, 3), gate:drive, levelScale:gdrive) * 10000);
		hidriver = HPF.ar(WhiteNoise.ar(0.1), hicutoffenv);
		hidriver = hidriver * EnvGen.ar(Env.perc(1, 2, 0.25), gate:drive, levelScale:gdrive);

		thwack = EnvGen.ar(Env.perc(0.001,0.001,1), gate:drive, levelScale:gdrive);

		thisThread.randSeed = 6345;
		freqs  = {exprand(300, 20000)}.dup(30);
		res    = Ringz.ar(lodriver + hidriver + thwack, freqs).mean;

		((res * 1) + (lodriver * 2) + thwack);
	};

	~taylorTones = [292.8, 586.1, 693.0, 882.1, 1171.4, 1560.4, 1764.2, 1949.7,  2158.6, 2441.4, /*2619.2, 3184.6*/ ] / 1171.4;

	SynthDef(\lichen1, {
		arg out = 0, freq = 100, combDelay = 0.2, combDecay = 1, klankDecay = 1, pan = 0,
		impulseFreq = 0, impulseDecay = 0.5, ring = 0, amp=0, impulseFilt=50, bend=0.3
		;
		var sig, panned, klank, impulse, cymbal,
		env, harm, comb, saw, bendEnv, debug
		;

		env = Env([0, 0.8, 0.01, 0], [0.001, 20, 0.01], [-5, -5, -5]);

		harm = ~taylorTones;
		amp = ~taylorTones.size.collect({
			|i|
			i = i / ~taylorTones.size;
			1 - i.pow(2.pow(amp));
		});
		ring = ~taylorTones.size.collect({
			|i|
			i = i / ~taylorTones.size;
			1 - (0.9 * i.pow(2.pow(ring)));
		});

		impulseFreq = LFNoise2.kr(8, impulseFreq * 0.05, impulseFreq);
		impulseDecay = LFNoise2.kr(8, impulseDecay * 0.9, impulseDecay);

		impulse = Impulse.ar(impulseFreq)
		* LFNoise2.kr(35).range(0.05, 1);
		cymbal = ~cymbal.(impulse);

		impulse = Decay.ar(impulse, impulseDecay.max(0), 0.010);
		impulse = LPF.ar(impulse, impulseFilt) + HPF.ar(impulse * WhiteNoise.ar() * GrayNoise.ar() * 0.01, 15000);
		impulse = (impulse * 0.6) + (cymbal * 0.00001);

		bendEnv = EnvGen.ar(Env.perc(0.01, klankDecay / 6, 1, bend.range(-16, 0))) * bend;
		klank = DynKlank.ar(`[harm, amp, ring],
			input: impulse,
			freqscale: freq,
			freqoffset: LFDNoise3.ar(0.5 * bendEnv.pow(2), bendEnv.range(6, 10)),
			decayscale: (klankDecay * EnvGen.kr(env)).max(0)
		);
		klank = klank * EnvGen.kr(env);
		comb = klank + APF.ar(klank, 0.2, combDelay, combDecay);
		panned = Pan2.ar(comb, pan);

		DetectSilence.ar(comb, time:0.4, doneAction:2);
		Out.ar(out, panned);
	}).add;

	SynthDef(\lichenthump, {
		arg out = 0, freq = 100, dur;
		var sig, env;

		env = EnvGen.ar(Env.perc(0.4, dur, 1, -8), doneAction:2);
		sig = SinOsc.ar(env.range(7, 40), 0, env) * 0.3;
		sig = VarSaw.ar(env.range(freq, freq + 5), 0, env, env) * 0.3;
		sig = LPF.ar(sig, 100);
		sig = LeakDC.ar(sig);

		Out.ar(out, [sig, sig]);
	}).add;

	SynthDef(\lichenhiss, {
		arg out = 0, freq = 600, pfreq = 20, dur;
		var pulse, sig, sig2, env, formantfreqs, formantamps, formantbandwidths;

		env = EnvGen.ar(Env.sine(dur), doneAction:2);

		formantfreqs = [800,1150,2900,3900,4950]; //centre frequencies of formants
		formantamps = ([0 ,-6,-32,-20,-50]-6).dbamp; //peaks of formants
		formantbandwidths = [80,90,120,130,140];  //bandwidths

		pulse = LFPulse.ar(env.range(pfreq - 5, pfreq + 5), 0, env.range(0, 0.2), env);
		sig = LPF.ar(pulse, 900);
		sig = HPF.ar(WhiteNoise.ar(0.5), 3000) * sig * 0.1;

		sig2 = 3.collect({
			|i|
			VarSaw.ar(freq * (i+1.0001), mul:0.05/(i+1))
		}).sum;
		sig = Ringz.ar(sig, TRand.ar(freq, freq + 5, Impulse.ar(10)), 40);

		Out.ar(0, [sig, sig] * env);
	}).add;

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Livid
	~lc.notNil.if({ ~lc.clear });
	~lc = LCDevice();
	~lc.knobs.do(_.ringStyle_(\fill));

	// Play button
	~playButton = ~lc.buttons[4].default;
	~playButton.toggle = true;
	~playButton.buttonOnActions.add({
		State(\gliz).doStart();
	});

	~playButton.buttonOffActions.add({
		State(\gliz).doStop();
	});

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Controls
	~notes = 8.collect(Scale.partch_o3().degreeToFreq(_, 96.midicps, 0));
	~notes = 8.collect(Scale.bartok().degreeToFreq(_, 90.midicps, 0));

	~bellSynth = \lichen1;

	~controls = [
		~harmRingCV = CV(ControlSpec(-10, 10)),
		~harmAmpCV = CV(ControlSpec(-10, 10)),
		~impulseFreqCV = CV(ControlSpec(0.001, 68)),
		~impulseFiltCV = CV(ControlSpec(50, 4000, \exp, default: 500)),
		~bendCV = CV(ControlSpec(0, 1, default: 0.2)),
		~bulk = CV(ControlSpec(0, 1, default: 0.0)),
	];
	~bellBus = Bus.audio(s, 2);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Patterns
	Pdef(\b_base, Pbind(
		\instrument, \glassHit,
		\glassName, Prand([\B], inf),
		\glass, Pfunc({ |e| e.postln; e.putAll(~glassHits[e[\glassName]].choose()) }),
		\buffer, Pfunc({ |e| e[\buffer].bufnum }),
		\dur, Pseq([1], inf),
		\amp, Prand([0.03, 0.02, 0.021, 0.01], inf),
		\out, State(\gliz)[\bellBus].index,
		\scale, Scale.partch_o2(),
		//\scale, Scale.bartok(),
		\root, 0,
		\octave, 6,
		\degree, 0,
		\impulseFreq, 0,
		\impulseDecay, 10,
		\combDelay, 0.4,
		\combDecay, 5,
		\klankDecay, 20,
		\ring, State(\gliz)[\harmRingCV],
		\amp, State(\gliz)[\harmAmpCV],
		\impulseFilt, State(\gliz)[\impulseFiltCV],
		\bend, State(\gliz)[\bendCV],
	));


	Pdef(\b_notes1, Pbind(
		\degree, Pseq([
			[0, 4], 0, 0,
			[0, 5], 0, 0, 0,
			[0, 4], 0, 0, 0, 0,
			[-2, 6], [-3, 5], [-6, 3], 1,
			[-1, 4, 7], [-3, 4, 8], [4, 8]
		], inf)
	));

	Pdef(\b_notes2, Pbind(
		\degree, Pseq([9, 9, 9, 8], inf)
	));


	Pdef(\b_imp1, Pbind(
		\impulseFreq, Prand([4], inf),
		\impulseDecay, Prand([0.1], inf),
		\klankDecay, Prand([1], inf)
	));

	Pdef(\b_imp2, Pbind(
		\impulseFreq, Prand([0, 0, 0, 0, 4, 6], inf),
		\impulseDecay, Prand([2, 3, 3, 3, 5, 5, 10, 1] / 10, inf),
		\klankDecay, Prand([5], inf)
	));

	Pdef(\b_imp3, Pbind(
		\impulseFreq, Prand([0, 0, 0, 0, 4, 6], inf),
		\impulseDecay, Prand([0.5], inf),
		\klankDecay, Prand([5], inf)
	));

	Pdef(\slow, Pbind(
		\dur, 12,
		\degree, Pseq([0, 0, 6, 9 ,3], inf),
		\impulseFreq, 10
	));

	Pdef(\stutter, Pbind(

	));

	Pdef(\durpat1, Pbind(
		\impulseFreq, Prand([0, 0, 16, 1, 4, 6], inf),
		\dur, Pseq([4, 4, 0.5, 0.5, 0.5, 8, 4, 4, 4, 4, 0.1, 0.1, 0.1, 8], inf),
		\impulseDecay, Prand([2, 3, 3, 3, 5, 5, 10, 1] * 3, inf),
	));

	Pdef(\durpat2, Pbind(
		\impulseFreq, Prand([0, 0, 16, 1, 4, 6], inf),
		\dur, Pseq([0.5, 0.5, 8], inf),
		\impulseDecay, Prand([2, 3, 3, 3, 5, 5, 10, 1] * 3, inf),
	));

	Pdef(\durpat3, Pbind(
		\impulseFreq, Prand([0, 0, 0, 0], inf),
		\dur, Pseq([1, 1, 1, 4], inf),
		\impulseDecay, Prand([2, 3, 3, 3, 5, 5, 10, 1] * 3, inf),
	));

	Pdef(\scale, Pbind(
		\degree, Pseq([8, 9, 10, 11, 12], inf)
	));

	Pdef(\stutter, Pbind(
		\dur, PdurStutter(
			Pseq((1!7) ++ [6], inf),
			Pseq((Pkey(\dur) ! 7) ++ [12])
		),
		\degree, Ptrace(Pkey(\degree) + Pseq((0!7) ++ [[0, -12]], inf))
	));

	Pdef(\lichenhiss, Pbind(
		\instrument, \lichenhiss,
		\scale, Scale.bartok(),
		\pfreq, 20,
		\freq, 440,
		\dur, 8,
		\out, State(\gliz)[\bellBus].index,
	));

	Pdef(\high1, Pbind(
		\dur, Prand([12, 12, 16, 24], inf),
		\amp, 0.1,
		\octave, 7,
		\degree, [6, 6.76]
	));

	Pdef(\main);


	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Controls
	~buttons = ~lc.buttons[5..12];
	~buttons.do({ |b| b.default().toggle_(true) });
});


State(\gliz).startActions.add({
	var lastNote, triggers;
	"Bell1 on".postln;

	~patterns = [
		nil,
		Pdef(\durpat3) <> Pdef(\b_imp1) <> Pdef(\b_notes1) <> Pdef(\b_base),
		Pdef(\stutter) <> Pdef(\durpat3) <> Pdef(\b_notes1) <> Pdef(\b_base),
		Pdef(\durpat3) <> Pdef(\b_notes1) <> Pdef(\b_base),
		Pdef(\durpat2) <> Pdef(\slow) <> Pdef(\b_notes1) <> Pdef(\b_base)
	];

	~patterns.do({
		|pat, i|
		~buttons[i].buttonOnActions.add({
			Pdef(\b_base, pat);
		})
	});

	~surfaceSynth = Synth.controls(\lichenSurface, [
		\out, 0,
		\in, ~bellBus.index,
		\bulk, ~bulk
	], addAction: \addAfter);

	~controls.do({
		|cv, i|
		~lc.knobs[3 + (i * 4)].lightWhenActive_(true).cv = cv;
	});

	Pdef(\main).stop;
	Pdef(\main, Pdef(\durpat2) <> Pdef(\slow) <> Pdef(\b_notes1) <> Pdef(\b_base)).stop;

	Pdef(\high, Pdef(\high1) <> Pdef(\b_base)).stop;
});

State(\gliz).stopActions.add({
	"Bell1 off".postln;

	~controls.do({
		|cv, i|
		~lc.knobs[7 + (i * 4)].cv = nil;
	});

	~bellBus.free;
	~surfaceSynth.free;
});

State(\gliz).doInit();

