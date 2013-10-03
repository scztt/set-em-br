


///////////////////////////////////////////////////////////////
// SynthDef
State(\gliz).clear();
State(\gliz).autoEnvirWindow = true;

Require("GLIZ-samples", always: true);
Require("GLIZ-hum-patterns", always: true);
Require("GLIZ-hit-patterns", always: true);

State(\gliz).initActions.put(0, {

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
		arg in, out, t_dust = 0, bulk = 0, hard = 0, amp = 1, gate = 1;
		var sig, inSig, inSigLow, inFeed, noise, noiseMod, dust, dustEnv, env;

		noise = PlayBuf.ar(4, ~sf.bufnum, 1, startPos: 0, loop: 1)  * 5000;
		sig = (noise);
		sig = XFade2.ar(sig, HardCompress2.ar(sig + BrownNoise.ar(0.1), 0.02, 0.1), hard * 2 - 1);
		sig = XFade2.ar(sig, sig.collect({ |s| ~bulkSynth.value(s) }), bulk * 2 - 1);
		sig = sig * 0.3;
		sig = HPF.ar(sig, 7000);

		sig = (sig) * amp * 0.01;
		sig.postln;
		sig = [
			sig[0], sig[1],
			sig[0], sig[1],
			sig[2], sig[3],
			sig[2], sig[3]
		].postln;

		env = EnvGen.ar(Env([0, 1, 1, 0], [10, 1, 15], releaseNode: 2), gate: gate, doneAction: 2);

		Out.ar(out, sig * env);
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
	~resources.add(~lc);
	~lc.postln;

	// Play button
	~playButton = ~lc.buttons[4].default;
	~playButton.toggle = true;
	~playButton.buttonOnActions.add({
		State(\gliz).doStart();
	});

	~playButton.buttonOffActions.add({
		State(\gliz).doStop();
	});

	~controls = [
		~humAmp = CV(ControlSpec(0, 2, \db, default: 1)),
		~hitAmp = CV(ControlSpec(0.1, 2, \db, default: 1)),
		~surfaceAmp = CV(ControlSpec(0, 0.5, \db, default: 0.01)),
		~rotationSpeed = CV(ControlSpec(-0.5, 0.5, default: 0)),
		~pitchBend = CV(ControlSpec(-10, 10, default: 0)),
		~hitSpeed = CV(ControlSpec(0.5, 20, \exp, default: 1)),
		~bulk = CV(ControlSpec(0, 1, default: 0)),
		~hard = CV(ControlSpec(0, 1, default: 0)),
	];
	~bellBus = Bus.audio(s, 2);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Controls
	~buttons = ~lc.buttons[5..12];
	~buttons.do({ |b| b.default().toggle_(true) });
});


State(\gliz).startActions.add({
	var lastNote, triggers;

	~patterns = [
		nil,
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
		\bulk, ~bulk,
		\hard, ~hard,
		\amp, ~surfaceAmp
	], addAction: \addAfter);

	~controls.do({
		|cv, i|
		~lc.knobs[3 + (i * 4)].lightWhenActive_(true).cv = cv;
	});

});

State(\gliz).stopActions.add({
	"Bell1 off".postln;

	~bellBus.free;
	~surfaceSynth.release();
});

State(\gliz).doInit();

