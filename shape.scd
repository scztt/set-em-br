~synth = NodeProxy.audio(s, 2);
~synth.source = 0;

~sourceBuf = Buffer.read(s, "/Users/fsc/Desktop/SET EM BR/sounds/HumF_50.wav", bufnum: 0);
~sourceBuf = Buffer.read(s, "/Users/fsc/Desktop/SET EM BR/sounds/HumD1_48.wav", bufnum: 0);
~sourceBuf = Buffer.read(s, "/Users/fsc/Desktop/SET EM BR/sounds/HumH_52.wav", bufnum: 0);
~sourceBuf = Buffer.read(s, "/Users/fsc/Desktop/SET EM BR/sounds/HumA1_44.wav", bufnum: 0);
~sourceBuf = Buffer.read(s, "/Users/fsc/Desktop/SET EM BR/sounds/barrell-roll_4.wav", bufnum:0);
~sourceBuf.plot;

~sourceSynth = NodeProxy.audio(s, 2);
~sourceSynth.source = {
	// PlayBuf.ar(4, ~sourceBuf.bufnum, rate:0.601)
	Mix(Mix(PlayBuf.ar(3, ~sourceBuf.bufnum, rate:[0.24, 0.12], loop:1))) * [1,1]
//	+ (PlayBuf.ar(4, ~sourceBuf.bufnum, rate:[0.7, 0.5], loop:1).sum * 4)
};
~sourceSynth.stop;

~synth.objects[0].synthDef.draw;
// unit 0 PlayBuf
// in  16 0.24 1 0 1 0
// out -0.00234738 -0.000577152 0.00365099
// unit 1 PlayBuf
// in  16 0.12 1 0 1 0
// out 0.000624055 -0.0036925 0.000154926
// unit 0 PlayBuf
// in  16 0.24 1 0 1 0
// out 0.00136276 0.000932415 -0.00699925
// unit 1 PlayBuf
// in  16 0.12 1 0 1 0
// out -0.00189589 0.000905477 -0.000864238


~buffers = Array.fill(20, {
	| i |
	Buffer.alloc(s, 1024, bufnum: i + 1);
});

Node.basicNew(s, ~sourceSynth.objects[0].nodeID).trace;

~bufferUpdate = {
	try {
		~bufferview.string.interpret();
		{ Archive.global.put(\shape, \bufferString, ~bufferview.string) }.defer;
		~b.do({
			|b, i|
			var array;
			if (b.class == Function) {
				b = 513.collect({
					|n|
					b.value(n / 513.0 * 2 - 1);
				})
			};

			if (b.class == Env) {
				b = 513.collect({
					|n|
					b = b.deepCopy().duration_(513);
					b.at(n);
				})
			};

			if (b.isKindOf(Collection) && (b.size > 0)) {
				~buffers[i].sendCollection(Signal.newFrom(b.resamp1(513)).asWavetableNoWrap());
			};
		});
		~synthUpdate.();
	} {
		|e|
		"...".postln;
		e.throw;
	}
};


~synthUpdate = {
	var code, func, duration = 0.1, minval, maxval;
	code = ~synthview.string;
	fork({
		Server.default.sync();
		try {
			code = code.compile();
			func = {
				(
					b: ~buffers.collect(_.bufnum),
					sig: SinOsc.ar(30),
				).use(code)
			};
			Archive.global.put(\shape, \synthString, ~synthview.string);

			func.loadToFloatArray(duration, s, {
				|array, buf|
				var numChan = buf.numChannels;
				{
					~plotter.setValue(
						array.unlace(numChan).collect(_.drop(-1)),
						findSpecs: true,
						refresh: false
					);
					if(minval.isNumber && maxval.isNumber) {
						~plotter.specs = [minval, maxval].asSpec
					} {
						minval !? { ~plotter.minval = minval };
						maxval !? { ~plotter.maxval = maxval };
					};
					~plotter.domainSpecs = ControlSpec(0, duration, units: "s");
					~plotter.refresh;
				}.defer
			});

			{
				~synth.source = {
					(
						b: ~buffers.collect(_.bufnum),
						sig: ~sourceSynth.ar(2),
					).use(code) * [1, 1];
				};
			}.defer(0.1);

		} {
			|e|
			"err...".postln;
			e.throw;
		}
	}, AppClock);
};

~w = Window().layout_(VLayout(

	~bufferview = TextView().string_(Archive.global.at(\shape, \bufferString)),

	~synthview = TextView().string_(Archive.global.at(\shape, \synthString)),

	~plot = View(bounds:Rect(0,0,100,100)).minHeight_(200),

	HLayout(
		Button().states_([['execute']]).action_({
			~bufferUpdate.();
		}),
		Button().states_([['play'], ['stop']]).action_({
			| b |
			var code;

			if (b.value == 1) {
				~synth.play;
			} {
				~synth.stop;
			};
		}),
	)
));

~plotter = Plotter("asdf", ~plot.bounds.moveTo(0,0), ~plot).value_([0, 1, 3, 4, 9].scramble * 100);
~synthview.action_(~synthUpdate);
~bufferview.action_(~bufferUpdate);
~w.front;

