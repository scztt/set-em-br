
Log(\gliz, "Loading gliz samples.");

~glassNote = (
	A:		432 * 4,
	B:		964,
	D:		716,
	E:		755,
);

~humNote = (
	HumA2_45: 428,
	HumA1_44: 428,
	HumI_53: 439,
	HumH_52: 721,
	HumF_50: 751,
	HumG_51: 930,
	HumD1_48: 962,
	HumC1_47: 960,
	HumE1_49: 965,
	HumB1_46: 1081,
);

~glassSort = {|a, b| a[\baseFreq] < b[\baseFreq]};
~glassHits = (
	A: List(),
	B: List(),
	D: List(),
	E: List(),
);
~glassHums = SortedList(10, ~glassSort);

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
		path.postln;
		if ("^[A-Z]_.*".matchRegexp(name)) {
			sound = (
				path: path.asAbsolutePath(),
				baseFreq: ~glassNote[name[0].asSymbol]
			);
			// "Hit: %".format(sound[\path]).postln;
			~glassHits[name[0].asSymbol].add(sound);

		} {
			if (name[0..2] == "Hum") {
				sound = (
					path: path.asAbsolutePath,
					baseFreq: ~humNote[path.fileNameWithoutExtension.asSymbol]
				);
				// "Hum: %".format(sound[\path]).postln;
				~glassHums.add(sound);
			} {
				// "Dunno what to do with %".format(name).postln;
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
	| out = 0, amp, buffer, freq = 440, baseFreq = 440, rotation = 0, gate = 1, dur 1, bend = 0|
	var rate, env, sigA, sigB, sigMix, bufferDur, bufferFrames, phasorA, phasorB, relPos;
	rate = (freq  + bend.lag(3)) / baseFreq;
	bufferDur = BufDur.kr(buffer);
	bufferFrames = BufFrames.kr(buffer);

//	phasorA = (Phasor.ar(1, BufRateScale.ir(buffer) * rate, 0, bufferFrames));
	phasorA = (Phasor.ar(1, BufRateScale.kr(buffer) * rate, 0, bufferFrames) + Rand(0, 48000 * 10)) % bufferFrames;
	phasorB = (phasorA + (bufferFrames / 2)) % bufferFrames;
	relPos = phasorA / bufferFrames;

	sigA = BufRd.ar(3, buffer, phasorA, interpolation: 4);
	sigB = BufRd.ar(3, buffer, phasorB, interpolation: 4);

	sigMix = IEnvGen.kr(Env([0, 1, 1, 0, 0], [0.05, 0.45, 0.05, 0.45]), relPos);
	sigMix = XFade2.ar(sigB, sigA, sigMix.linlin(0, 1, -1, 1));
	sigMix = Splay.ar(sigMix) * amp;
	sigMix = Rotate2.ar(sigMix[0], sigMix[1], rotation);
	sigMix = sigMix * EnvGen.kr(Env([0, 1, 1, 0], [1, 1, 10], releaseNode: 2), gate: gate, doneAction: 2);
	sigMix = LPF.ar(sigMix, 20000 * rate.min(1));

	Out.ar(out, sigMix);
}).add;

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

~hum_group = Group();

Pdef(\humBase, Pbind(
	\instrument, \glassHum,
	\dur, Pseq([6], inf),
	\hum, 3,
	\legato, 1,
	\amp, 0.7,
	\octave, 8,
	\degree, 0,
	\rotation, 0,
	\group, ~hum_group.nodeID,
	\scale, Scale.chromatic
));

Pdef(\humBuf, Pbind(
	\buffer, Pfunc({
		|e|
		if (e[\hum].isCollection) {
			e[\hum].collect({ |i| State(\gliz)[\glassHums][i][\buffer].bufnum })
		} {
			State(\gliz)[\glassHums][e[\hum]][\buffer].bufnum
		};
	}),
	\baseFreq, Pfunc({
		|e|
		if (e[\hum].isCollection) {
			e[\hum].collect({ |i| State(\gliz)[\glassHums][i][\baseFreq] });
		} {
			State(\gliz)[\glassHums][e[\hum]][\baseFreq];
		};
	})
));

Pdef(\humA, Pbind(
	\hum, Ptrace(Pseq([ [9, 9]. ], 1)),
	\degree, Pseq([ [1, 2] ], 1),
));

(
Pdef(\test, Pbind(
	\instrument, \default,
	\scale, Scale.chromatic,
	\octave, 7,
	\legato, 2,
	\degree, Pseq([-32, -25, -25, -18, -18], inf),
	\dur, 0.1
)).stop;
)

Pseq([
	[1, 2]
	[-1, 2]
	[-4, -1, 2]
	[-6, -3, 1]
	[-8, -6, -3, 1]
	[-9, -7, -4, 0]
	[-11, -9, -7, -4, 0, 5]
	[-11, -11, -10, -5, -1, 4]
	[-13, -13, -11, -6, 4, 6]
	[-23, -13, -13, -11, -4, 3, 3, 8]
	[-24, -14, -14, -11, -4, 3, 3, 5]
	[-29, -24, -20, -12, -12]
	[-29, -25, -20, -12, -13]
	[-29, -25, -21, -16, -13]
	[-32, -25, -21, -16, -13]
	[-32, -25, -22, -18, -17]
	[-32, -25, -25, -18, -18]
])

~hum_group.freeAll
Pdef(\glassMain, Pdef(\humBuf) <> Pdef(\humA) <> Pdef(\humBase)).play;

(
Pdef(\humA, Pbind(
	\octave, 8,
	\hum, Pseq(   [ [  0,   1,   1,   1,   0 ] ], inf),
	\degree, Pseq([ [-32, -25, -25, -18, -18 ] +.x [0, -12] ], inf),
));
)

Pdef(\humA, Pbind(
	\octave, 8,
	\hum, Pseq(   [ [ 9, 9 ] ], inf),
	\degree, Pseq([ [ 1, 2 ] ], inf),
));

Pdef(\humA, Pbind(
	\octave, 8,
	\hum, Pseq(   [ [ 8, 9 ] ], inf),
	\degree, Pseq([ [-1, 2] ], inf),
));

Pdef(\humA, Pbind(
	\octave, 8,
	\hum, Pseq(   [ [ 9,  8, 9 ] ], inf),
	\degree, Pseq([ [-3, -1, 2 ] ], inf),
));

Pdef(\humA, Pbind(
	\octave, 8,
	\hum, Pseq(   [ [ 7,  8, 9 ] ], inf),
	\degree, Pseq([ [-6, -3, 1 ] ], inf),
));

Pdef(\humA, Pbind(
	\octave, 8,
	\hum, Pseq(   [ [ 7,  7,  8, 9 ] ], inf),
	\degree, Pseq([ [-8, -6, -3, 1 ] ], inf),
));

Pdef(\humA, Pbind(
	\octave, 8,
	\hum, Pseq(   [ [  6,  7,  6, 8 ] ], inf),
	\degree, Pseq([ [-10, -6, -3, 0 ] ], inf),
));

Pdef(\humA, Pbind(
	\octave, 8,
	\hum, Pseq(   [ [  2,  6,   7,   6,  7, 8, 9 ] ], inf),
	\degree, Pseq([ [-11, -9,  -7,  -4,  0, 5, 5 ] ], inf),
));

Pdef(\humA, Pbind(
	\octave, 8,
	\hum, Pseq(   [ [  5,   6,  7,   5,  6, 8, 9 ] ], inf),
	\degree, Pseq([ [-11, -11, -9,  -4, -2, 5, 5 ] ], inf),
));

Pdef(\humA, Pbind(
	\octave, 8,
	\hum, Pseq(   [ [  3,   7,   5,  5,  3, 6, 6 ] ], inf),
	\degree, Pseq([ [-13, -13, -11, -7,  3, 6, 6 ] ], inf),
));

Pdef(\humA, Pbind(
	\octave, 8,
	\hum, Pseq(   [ [  3,   7,   6,   6,  3, 6, 5 ] ], inf),
	\degree, Pseq([ [-23, -13, -13, -11, -4, 3, 8 ] ], inf),
));

Pdef(\humA, Pbind(
	\octave, 8,
	\hum, Pseq(   [ [  2,   3,   5,   5,  3, 5, 6, 5 ] ], inf),
	\degree, Pseq([ [-24, -14, -14, -11, -4, 3, 3, 8 ] ], inf),
));

Pdef(\humA, Pbind(
	\octave, 8,
	\hum, Pseq(   [ [  1,   3,   5,   3,   6 ] ], inf),
	\degree, Pseq([ [-29, -24, -20, -12, -12 ] ], inf),
));

Pdef(\humA, Pbind(
	\octave, 8,
	\hum, Pseq(   [ [  1,   3,   5,   3,   5 ] ], inf),
	\degree, Pseq([ [-29, -24, -20, -12, -13 ] ], inf),
));

Pdef(\humA, Pbind(
	\octave, 8,
	\hum, Pseq(   [ [  5,   2,   3,   3,   5 ] ], inf),
	\degree, Pseq([ [-29, -25, -20, -12, -13 ] ], inf),
));

Pdef(\humA, Pbind(
	\octave, 8,
	\hum, Pseq(   [ [  6,   1,   3,   2,   5 ] ], inf),
	\degree, Pseq([ [-29, -25, -21, -16, -13 ]  ], inf),
));

Pdef(\humA, Pbind(
	\octave, 8,
	\hum, Pseq(   [ [  5,   0,   3,   1,   5 ] ], inf),
	\degree, Pseq([ [-32, -25, -21, -16, -13 ] ], inf),
));

Pdef(\humA, Pbind(
	\octave, 8,
	\hum, Pseq(   [ [  2,   0,   1,   0,   3 ] ], inf),
	\degree, Pseq([ [ -32, -25, -22, -18, -17] ], inf),
));

Pdef(\humA, Pbind(
	\octave, 8,
	\hum, Pseq(   [ [  1,   0,   1,   0,   2 ] ], inf),
	\degree, Pseq([ [-32, -25, -25, -18, -18 ] ], inf),
));

Pdef(\humA, Pbind(
	\octave, 8,
	\hum, Pseq(   [ [  0,   0,   0,   0,   0 ] ], inf),
	\degree, Pseq([ [-32, -25, -25, -18, -18 ] +.x [0, -12] ], inf),
));

Pdef(\humA, Pbind(
	\octave, 8,
	\hum, Pseq(   [ [  0,   1,   1,   1,   0 ] ], inf),
	\degree, Pseq([ [-32, -32, -25, -25, -25 ] +.x [0, -12, -24] ], inf),
));


~hum_group.set(\bend, 0)

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