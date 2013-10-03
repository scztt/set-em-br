State(\adelay).clear;
State(\adelay).autoEnvirWindow = true;

State(\adelay).initActions.add({

	~delayTime = 12;

	~inputChannel = 0;

	~lc.notNil.if({ ~lc.clear });
	~lc = LCDevice();
	~lc.knobs.do(_.ringStyle_(\fill));

	~controls = [
		~inputAmp = CV(ControlSpec(0, 2, warp:\db, 			default: -3.dbamp)),
		~feedbackAmp = CV(ControlSpec(0, 0.dbamp, warp:\db,	default: 0.63)),
		~reverbMix = CV(ControlSpec(0, 1,					default: 0.33)),

		~delay = CV(ControlSpec(0.2, 10.0, 					default: 3.5)),

		~cutoff = CV(ControlSpec(40, 2000, warp:\exp, 		default: 400)),
		~highLowMix = CV(ControlSpec(-1, 1,  				default: 1)),
		~amp = CV(ControlSpec(0, 3, warp:\db, 				default: 0)),
	];

	((0..6) * 4).do({
		|i, n|
		~lc.knobs[i].cv = ~controls[n];
	});

	// Play button
	~playButton = ~lc.buttons[4].default;
	~playButton.toggle = true;
	~playButton.buttonOnActions.add({
		State(\adelay).doStart();
	});

	~playButton.buttonOffActions.add({
		State(\adelay).doStop();
	});

	SynthDef(\andreasdelay, {
		arg out = 0, in, delay = 0.5,
		amp=0, inAmp = 1, feedAmp = -12.dbamp,
		verbMix = 0.33, cutoff = 100, highLowMix = 0.5, gate = 1;

		var feedIn, feedSig, inSig, sig, depth, env;

		delay = delay.lag(10);

		inSig = Limiter.ar(SoundIn.ar([0, 1]).sum * inAmp, 0.dbamp);
		inSig = LeakDC.ar(inSig);
		inSig = FreeVerb.ar(inSig, mix: verbMix, room: 0.9, damp: 0.7) * [1, 1];

		feedSig = LocalIn.ar(2) * feedAmp;
		feedSig = Compander.ar(feedSig, feedSig, 0.5, 1, 1/8);
		feedSig = XFade2.ar(
			(feedSig * -3.dbamp),
			XFade2.ar(
				LPF.ar(feedSig, cutoff),
				HPF.ar(feedSig, cutoff),
				highLowMix
			),
			(highLowMix.abs * 2 - 1)
		);

		feedSig = DelayC.ar(feedSig, 10, delay.max(0.5));
		feedSig = LeakDC.ar(feedSig);
		feedSig = Rotate2.ar(feedSig[0], feedSig[1], LFNoise2.ar(0.08));

		env = EnvGen.kr(Env([0, 1, 1, 0], [5, 1, 15], releaseNode: 2), gate: gate, doneAction: 2);

		sig = feedSig + inSig;
		LocalOut.ar(sig);

		sig = 4.collect({
			depth = SinOsc.kr(Rand(0.06, 0.12), Rand(0, 1)).range(0, 1);
			[
				PanArray.ar(4, sig[0], depth, width: 3),
				PanArray.ar(4, sig[1], depth, width: 3)
			].flop.flatten;
		}).sum;

		Out.ar(out, sig * amp * env);
	}).add;
});

State(\adelay).startActions.add({
	~synth.notNil.if({ ~synth.free });
	~synth = Synth.controls(\andreasdelay, args: [
		out: 0,
		in: 0,
		inAmp: ~inputAmp,
		amp: ~amp,
		feedAmp: ~feedbackAmp,
		verbMix: ~reverbMix,
		cutoff: ~cutoff,
		highLowMix: ~highLowMix,
		delay: ~delay,
	]);
});


State(\adelay).stopActions.add({
	~synth.release();
});

