State(\gliz).initActions.put(11, {
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
		\group, Pfunc({ State(\gliz)[\hum_group].nodeID }),
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
		\octave, 8,
		\hum, Pseq(   [ [  0,   1,   1,   1,   0 ] ], inf),
		\degree, Pseq([ [-32, -25, -25, -18, -18 ] +.x [0, -12] ], inf),
	));

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
		\degree, Pseq([ [-11, -6, -3, 1 ] ], inf),
	));

	Pdef(\humA, Pbind(
		\octave, 8,
		\hum, Pseq(   [ [  2,  6,   7,   6,  7, ] ], inf),
		\degree, Pseq([ [-11, -9,  -6,  -3,  1, ] ], inf),
	));

	Pdef(\humA, Pbind(
		\octave, 8,
		\hum, Pseq(   [ [  2,   5,   6,  7,  5,  6 ] ], inf),
		\degree, Pseq([ [-14, -11, -11, -9, -6, -2 ] ], inf),
	));

	Pdef(\humA, Pbind(
		\octave, 8,
		\hum, Pseq(   [ [  3,   7,   5,  5,  3, 6, 6 ] ], inf),
		\degree, Pseq([ [-14, -14, -11, -6,  3, 6, 6 ] ], inf),
	));

	Pdef(\humA, Pbind(
		\octave, 8,
		\hum, Pseq(   [ [  3,   7,   6,   6,  3, 6, 1 ] ], inf),
		\degree, Pseq([ [-23, -13, -13, -11, -4, 3, 8 ] ], inf),
	));

	Pdef(\humA, Pbind(
		\octave, 8,
		\hum, Pseq(   [ [  2,   3,   5,   5,  3, 5, 6, 5 ] ], inf),
		\degree, Pseq([ [-24, -16, -16, -12, -9, 3, 3, 8 ] ], inf),
	));

	Pdef(\humA, Pbind(
		\octave, 8,
		\hum, Pseq(   [ [  1,   3,   5,   3,   6,  6 ] ], inf),
		\degree, Pseq([ [-29, -24, -20, -12, -12, 10 ] ], inf),
	));

	Pdef(\humA, Pbind(
		\octave, 8,
		\hum, Pseq(   [ [  1,   3,   5,   3,   5,  6 ] ], inf),
		\degree, Pseq([ [-29, -24, -20, -12, -13, 10 ] ], inf),
	));

	Pdef(\humA, Pbind(
		\octave, 8,
		\hum, Pseq(   [ [  5,   2,   3,   3,   5 ] ], inf),
		\degree, Pseq([ [-29, -25, -20, -12, -13 ] ], inf),
	));

	Pdef(\humA, Pbind(
		\octave, 8,
		\hum, Pseq(   [ [  6,   1,   3,   2,   5,  6 ] ], inf),
		\degree, Pseq([ [-29, -25, -21, -16, -13, 10 ]  ], inf),
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

	Pdef(\glassMain, Pdef(\humBuf) <> Pdef(\humA) <> Pdef(\humBase)).play;
});