
Log(\gliz, "Loading gliz samples.");

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
~resources.add(~lowLongMono[\buffer]);

~glassPath = PathName("/Users/fsc/Desktop/SET EM BR/sounds");
~glassPath.entries.do({
	| path |
	var sound, name = path.fileName;

	if (path.extension == "wav") {
		if ("[A-Z]_.*".matchRegexp(name)) {

			sound = (
				path: path.asAbsolutePath(),
				baseFreq: ~glassNote[name[0].asSymbol]
			);
			~glassHits[name[0].asSymbol].add(sound);
		} {
			if (name[0..2] == "Hum") {
				sound = (
					path: path.asAbsolutePath,
					baseFreq: ~humNote[path.fileNameWithoutExtension.asSymbol]
				);
				~glassHums.add(sound);
			} {
				//"Dunno what to do with %".format(name).postln;
			}
		}
	}
});

~glassHits.do(
	_.do({
		|sound|
		sound[\buffer] = Buffer.read(s, sound[\path]);
		~resources.add(sound[\buffer]);
	})
);

~glassHums.do({
	|sound|
	sound[\buffer] = Buffer.read(s, sound[\path]);
	~resources.add(sound[\buffer]);
});

Log(\gliz, "Loaded % hums and % hits".format(~glassHums.size, ~glassHits.size));

SynthDef(\glassHit, {
	| out = 0, amp, buffer, freq = 440, baseFreq = 440, rotation = 0, dur = 1 |
	var rate, env, envAmt, sig, doneAction;
	rate = freq / baseFreq;

	sig = PlayBuf.ar(3, buffer, rate, doneAction: 2) * 0.05;
	sig = Splay.ar(sig) * amp;
	sig = Rotate2.ar(sig[0], sig[1], rotation);
	doneAction = (dur < 0.3).if(4, 0);
	env = EnvGen.ar(Env.perc(0.001, 1), doneAction: doneAction);
	envAmt = ((0.4 - dur) / 0.3).min(1).max(0);
	envAmt.poll(30);
	sig = (sig * (1 - envAmt)) + (sig * env * envAmt);

	Out.ar(out, sig);
}).add;

SynthDef(\glassHum, {
	| out = 0, amp, buffer, freq = 440, baseFreq = 440, rotation = 0, gate = 1, dur 1|
	var rate, env, sigA, sigB, sigMix, bufferDur, bufferFrames, phasorA, phasorB, relPos;
	rate = freq / baseFreq;
	bufferDur = BufDur.kr(buffer);
	bufferFrames = BufFrames.kr(buffer);

	phasorA = Phasor.ar(1, BufRateScale.kr(buffer) * rate, 0, bufferFrames);
	phasorB = (phasorA + (bufferFrames / 2).floor) % bufferFrames;
	relPos = phasorA / bufferFrames;

	sigA = BufRd.ar(3, buffer, phasorA);
	sigB = BufRd.ar(3, buffer, phasorB);

	sigMix = IEnvGen.kr(Env([0, 1, 1, 0, 0], [0.05, 0.45, 0.05, 0.45]), relPos;
	sigMix = XFade2.ar(sigB, sigA, sigMix.linlin(0, 1, -1, 1));
	sigMix = Splay.ar(sigMix) * amp;
	sigMix = Rotate2.ar(sigMix[0], sigMix[1], rotation);
	sigMix = sigMix * EnvGen.kr(Env([0, 1, 1, 0], [1, 1, 3], releaseNode: 2), gate: gate, doneAction: 2);

	Out.ar(out, sigMix);
}).add.send(s);

Pdef(\glassBase, Pbind(
	\instrument, \glassHit,
	\dur, Pseq([1], inf),
	\amp, 1,
	\glassName, Prand([\D, \E], inf),
	\glass, Pfunc({ |e| e.putAll(State(\gliz)[\glassHits][e[\glassName]].choose()) }),
	\buffer, Pfunc({ |e| e[\buffer].bufnum }),
	\octave, 5,
	\degree, Pseq([1], inf),
	\rotation, Pseg(Pseq([-0.1, 0.1, -0.1], inf), Pseq([20] , inf), \sin, inf)
));


Pdef(\humBase, Pbind(
	\instrument, \glassHum,
	\dur, Pseq([10], inf),
	\hum, Ptrace( Prand((0..State(\gliz)[\glassHums].size - 1), inf) ),
	\glass, Pfunc({ |e| e.putAll(State(\gliz)[\glassHums][e[\hum]]) }),
	\buffer, Pfunc({ |e| e[\buffer].bufnum }),
	\amp, 1,
	\octave, Prand([3, 4, 5], inf),
	\degree, Pseq([ [1, 3], [2, 7], [2, 9], [-3, 2] ], inf),
	\rotation, Pfunc({ rrand(-1, 1) })
));

Pdef(\humBase).stop;

Pdef(\glassDurVary, Pbind(
	\dur, Pfunc({ |e| e[\dur] * rrand(0.95, 1.05) })
));

Pdef(\glassStutter1, Pbind(
	\dur, PdurStutter(
		Prand([1, 1, 1, 1, 1, 1, 1, 1, 1, 2.9, 3, 6], inf),
		Prand(
			(Pfunc({ rrand(0.46, 0.4) }) ! 5)
			++ [6, 4, 4]
			, inf)
	);
));
Pdef(\glassStutter2, Pdef(\glassDurVary) <> Pdef(\glassStutter1));

Pdef(\glassMostlyQuiet, Pbind(
	\amp, Pseq(Pfunc({ rrand(0.8, 0.4) }) ! 7 ++ [1], inf)
));

Pdef(\notes1, Pbind(
	\degree, Pseq([1.001, 1.05, 1.01, 1.05, 1.02, Prand([-2, -1.03])], inf)
));

Pdef(\repeated, Pbind(
	\baseDegree, Pseg(
		Pfunc({ rrand(1, 1.04) }) * Pser([1, 1.1, 1, 0.95, 1, 0.9, 1.05, 0.7], inf),
		Pfunc({ rrand(5.0, 8.0) })
	),
	\degree, Pkey(\baseDegree) * 1,
	\dur, Pseg(
		Pseq([0.9, 1.3, 1.1, 0.9, 1, 0.05, 1, 0.8, 1, 0.1, 1.0, 1.05] * 0.3, inf),
		Pfunc({ rrand(2, 4) }),
		\sine, inf
	),
	\amp, Ppatlace([
		Pseq(30.collect({ |i| (i/30).sin * 1.0 }), inf),
		Prand([0.1, 0.2, 0.2, 0.25, 0.15, 0.3, 2], inf)
	], inf)
));

Pdef(\jump1, Pbind(\degree, Pkey(\baseDegree) + 4.2));


Pdef(\glassMain, Pdef(\repeated) <> Pdef(\notes1) <> Pdef(\glassBase)).stop;
Pdef(\glassAccent, Pdef(\jump1) <> Pdef(\repeated) <> Pdef(\notes1) <> Pdef(\glassBase)).stop;