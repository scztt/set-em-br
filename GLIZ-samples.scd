State(\gliz).initActions.put(10, {

	~glassNote = (
		A:		432 * 4,
		B:		964,
		D:		716,
		E:		755,
	);

	~humNote = (
		HumI_53: 439,
		HumH_52: 721,
		HumG_51: 930,
		HumF_50: 751,
		HumE1_49: 965,
		HumD1_48: 962,
		HumC1_47: 960,
		HumB1_46: 1081,
		HumA2_45: 428,
		HumA1_44: 428,
	);

	~glassHits = (
		A: List(),
		B: List(),
		D: List(),
		E: List(),
	);
	~glassHums = List();

	~highLongMono = (
		\baseFreq: 964,
		\buffer: Buffer.readChannel(s, "/Users/fsc/Desktop/SET EM BR/sounds/B_good_30.wav", channels:[2]);
	);
	~lowLongMono = (
		\baseFreq: 964,
		\buffer: Buffer.readChannel(s, "/Users/fsc/Desktop/SET EM BR/sounds/A_8.wav", channels:[2]);
	);
	~resources.add(~highLongMono[\buffer]);
	~resources.add(~lowLongMono[\buffer])

	~glassPath = PathName("/Users/fsc/Desktop/SET EM BR/sounds");
	~glassPath.entries.do({
		| path |
		var sound, name = path.fileName;

		if (path.extension == "wav") {
			if ("[A-Z]_.*".matchRegexp(name)) {
				"hit: %".format(name).postln;

				sound = (
					path: path.asAbsolutePath(),
					baseFreq: ~glassNote[name[0].asSymbol]
				);
				~glassHits[name[0].asSymbol].add(sound);
			} {
				if (name[0..2] == "Hum") {
					"Hum: %".format(name).postln;
					sound = (
						path: path.asAbsolutePath,
						baseFreq: ~humNote[path.fileNameWithoutExtension.asSymbol]
					);
					~glassHums.add(sound);
				} {
					"Dunno what to do with %".format(name).postln;
				}
			}
		}
	});

	~glassHits.do(
		_.do({
			|sound|
			sound[\buffer] = Buffer.read(s, sound[\path].postln);
			~resources.add(sound[\buffer]);
		})
	);

	~glassHums.do({
		|sound|
		sound[\buffer] = Buffer.read(s, sound[\path].postln);
		~resources.add(sound[\buffer]);
	});

	SynthDef(\glassHit, {
		| out, amp, buffer, freq = 440, baseFreq = 440, rotation = 0 |
		var rate, env, sig;
		rate = freq / baseFreq;

		sig = PlayBuf.ar(3, buffer, rate, doneAction: 2) * 0.05;
		sig = Splay.ar(sig) * amp;
		sig = Rotate2.ar(sig[0], sig[1], rotation);
		Out.ar(out, sig);
	}).add;

	Pdef(\glassBase, Pbind(
		\instrument, \glassHit,
		\dur, PdurStutter(
			Prand([1, 1, 1, 1, 1, 1, 1, 1, 1, 2.9, 3, 6], inf),
			Prand(
				(Pfunc({ rrand(0.46, 0.4) }) ! 5)
				++ [6, 4, 4]
				, inf)
		),
		\amp, Pseq(Pfunc({ rrand(0.08, 0.04) }) ! 7 ++ [1], inf),
		\glassName, Prand([\D, \E], inf),
		\glass, Pfunc({ |e| e.putAll(~glassHits[e[\glassName]].choose()) }),
		\buffer, Pfunc({ |e| e[\buffer].bufnum }),
		\octave, 5,
		\degree, Pseq([1.001, 1.05, 1.01, 1.05, 1.06, Prand([-2, -1.03])], inf),
		\rotation, Pseq((-1, -0.95..1), inf)
	));
});