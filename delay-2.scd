~delayTime = 12;

~inputChannel = 0;

//~lc.free;
~lc = ~lc ?? { LCDevice() };
~lc.connect;
~lc.knobs.do(_.ringStyle_(\fill));

~controls = [
	~inputAmp = CV(ControlSpec(0, 2, warp:\db, 		default: -3.dbamp)),
	~feedbackAmp = CV(ControlSpec(0, 0.dbamp, 		warp:\db,default: -12.dbamp)),
	~reverbMix = CV(ControlSpec(0, 1,				default: 0.33)),

	~delay = CV(ControlSpec(0.2, 10.0, 	default: 1.0)),

	~cutoff = CV(ControlSpec(40, 2000, warp:\exp, 		default: 300)),
	~highLowMix = CV(ControlSpec(-1, 1,  				default: 1)),
	~amp = CV(ControlSpec(0, 3, warp:\db, 			default: -3.dbamp)),
];

((0..6) * 4).do({
	|i, n|
	~lc.knobs[i].cv = ~controls[n];
});


Server.default = s = Server.local;
Server.default.options.device = "MOTU UltraLite mk3 Hybrid";
Server.default.options.numOutputBusChannels = 16;
Server.default.options.numInputBusChannels = 16;
s.options.sampleRate = 48000;

s.waitForBoot({

	SynthDef(\andreasdelay, {
		arg out = 0, in, delay = 0.5,
		amp=0, inAmp = 1, feedAmp = -12.dbamp,
		verbMix = 0.33, cutoff = 100, highLowMix = 0.5;

		var feedIn, feedSig, inSig, sig, depth;

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

		sig = feedSig + inSig;
		LocalOut.ar(sig);

		sig = 4.collect({
			depth = SinOsc.kr(Rand(0.06, 0.12), Rand(0, 1)).range(0, 1);
			[
				PanArray.ar(4, sig[0], depth, width: 3),
				PanArray.ar(4, sig[1], depth, width: 3)
			].flop.flatten;
		}).sum;

		Out.ar(out, sig * amp);
	}).add;


	~synth = Synth.controls(\andreasdelay, args: [
		out: 2,
		in: 0,
		inAmp: ~inputAmp,
		amp: ~amp,
		feedAmp: ~feedbackAmp,
		verbMix: ~reverbMix,
		cutoff: ~cutoff,
		highLowMix: ~highLowMix,
		delay: ~delay,
	]);

	if (~window.notNil) { ~window.close() };
	~window = Window();

	~views = List();
	~controls.do({
		| item |
		var key, view, knob, text, number;
		key = currentEnvironment.findKeyForValue(item);
		if (item.isKindOf(CV)) {
			text = StaticText().string_(key.asString).font_(Font.sansSerif(10));
			knob = Knob().mode_(\horiz);
			number = NumberBox().font_(Font.sansSerif(10)).maxWidth_(50).maxHeight_(18);
			item.connect(knob);
			item.connect(number);
			view = View().layout_(VLayout(
				nil,
				[knob, align:\bottom],
				[number, align:\bottom],
				[text, align:\bottom]
			).spacing_(2));
			~views.add(view);
		}
	});
	~window.layout_(VLayout());

	~views.clump(4).do({
		|vs|
		~window.layout.add(HLayout(*vs));
	});

	~window.front();
	~window.onClose_({~synth.free});

});


