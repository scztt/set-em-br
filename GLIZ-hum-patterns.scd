State(\gliz).initActions.put(11, {
	SynthDef(\glassHum, {
		| out = 0, amp = 1, buffer, freq = 440, baseFreq = 440, rotation = 0, gate = 1, dur 1, bend = 0, rotationSpeed = 0|
		var rate, env, sigA, sigB, sigMix, bufferDur, bufferFrames, phasorA, phasorB, relPos,
		a, b, c, d, e, f, g, h, bSig;
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
		sigMix = sigMix * amp;

		rotation = LFSaw.ar(rotationSpeed * Rand(0.8, 1.2), Rand(0, 1)) + 1;
		bSig = PanB2.ar(sigMix[0], (rotation - 1).poll(3))
		+ PanB2.ar(sigMix[0], ((rotation % 1) - 1).poll(3));

		#a, c, d, b = DecodeB2.ar(4, bSig[0], bSig[1], bSig[1], 0.5);
		#e, g, h, f = DecodeB2.ar(4, bSig[0], bSig[1], bSig[1], 0.5);

		//Out.ar(out, [a, b, c, d, e, f, g, h]);
		#a, b = B2UHJ.ar(*bSig);
		Out.ar(out, [a, b]);
	}).add;

	Pdef(\humBase, Pbind(
		\instrument, \glassHum,
		\dur, Pseq([6], inf),
		\hum, 3,
		\legato, 1,
		\amp, 0.7,
		\octave, 8,
		\degree, 0,
		\rotation, 0,
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

	Pdef(\humControl, Pbind(
		\amp, ~humAmp,
		\rotationSpeed, ~rotationSpeed,
		\bend, ~pitchBend,
	));

	~humPatterns = [
		Pdef(\humA, Pbind(
			\hum, Pseq(   [ [  0,   1,   1,   1,   0 ] ], inf),
			\degree, Pseq([ [-32, -25, -25, -18, -18 ] +.x [0, -12] ], inf),
		)),

		Pdef(\humB, Pbind(
			\hum, Pseq(   [ [ 9, 9 ] ], inf),
			\degree, Pseq([ [ 1, 2 ] ], inf),
		)),

		Pdef(\humC, Pbind(
			\hum, Pseq(   [ [ 8, 9 ] ], inf),
			\degree, Pseq([ [-1, 2] ], inf),
		)),

		Pdef(\humD, Pbind(
			\hum, Pseq(   [ [ 9,  8, 9 ] ], inf),
			\degree, Pseq([ [-3, -1, 2 ] ], inf),
		)),

		Pdef(\humE, Pbind(
			\hum, Pseq(   [ [ 7,  8, 9 ] ], inf),
			\degree, Pseq([ [-6, -3, 1 ] ], inf),
		)),

		Pdef(\humF, Pbind(
			\hum, Pseq(   [ [ 7,  7,  8, 9 ] ], inf),
			\degree, Pseq([ [-8, -6, -3, 1 ] ], inf),
		)),

		Pdef(\humG, Pbind(
			\hum, Pseq(   [ [  6,  7,  6, 8 ] ], inf),
			\degree, Pseq([ [-11, -6, -3, 1 ] ], inf),
		)),

		Pdef(\humH, Pbind(
			\hum, Pseq(   [ [  2,  6,   7,   6,  7, ] ], inf),
			\degree, Pseq([ [-11, -9,  -6,  -3,  1, ] ], inf),
		)),

		Pdef(\humI, Pbind(
			\hum, Pseq(   [ [  2,   5,   6,  7,  5,  6 ] ], inf),
			\degree, Pseq([ [-14, -11, -11, -9, -6, -2 ] ], inf),
		)),

		Pdef(\humJ, Pbind(
			\hum, Pseq(   [ [  3,   7,   5,  5,  3, 6, 6 ] ], inf),
			\degree, Pseq([ [-14, -14, -11, -6,  3, 6, 6 ] ], inf),
		)),

		Pdef(\humK, Pbind(
			\hum, Pseq(   [ [  3,   7,   6,   6,  3, 6, 1 ] ], inf),
			\degree, Pseq([ [-23, -13, -13, -11, -4, 3, 8 ] ], inf),
		)),

		Pdef(\humL, Pbind(
			\hum, Pseq(   [ [  2,   3,   5,   5,  3, 5, 6, 5 ] ], inf),
			\degree, Pseq([ [-24, -16, -16, -12, -9, 3, 3, 8 ] ], inf),
		)),

		Pdef(\humM, Pbind(
			\hum, Pseq(   [ [  1,   3,   5,   3,   6,  6 ] ], inf),
			\degree, Pseq([ [-29, -24, -20, -12, -12, 10 ] ], inf),
		)),

		Pdef(\humN, Pbind(
			\hum, Pseq(   [ [  1,   3,   5,   3,   5,  6 ] ], inf),
			\degree, Pseq([ [-29, -24, -20, -12, -13, 10 ] ], inf),
		)),

		Pdef(\humO, Pbind(
			\hum, Pseq(   [ [  5,   2,   3,   3,   5 ] ], inf),
			\degree, Pseq([ [-29, -25, -20, -12, -13 ] ], inf),
		)),

		Pdef(\humP, Pbind(
			\hum, Pseq(   [ [  6,   1,   3,   2,   5 ] ], inf),
			\degree, Pseq([ [-29, -25, -21, -16, -13 ]  ], inf),
		)),

		Pdef(\humQ, Pbind(
			\hum, Pseq(   [ [  5,   0,   3,   1,   5 ] ], inf),
			\degree, Pseq([ [-32, -25, -21, -16, -13 ] ], inf),
		)),

		Pdef(\humR, Pbind(
			\hum, Pseq(   [ [  2,   0,   1,   0,   3 ] ], inf),
			\degree, Pseq([ [ -32, -25, -22, -18, -17] ], inf),
		)),

		Pdef(\humS, Pbind(
			\hum, Pseq(   [ [  1,   0,   1,   0,   2 ] ], inf),
			\degree, Pseq([ [-32, -25, -25, -18, -18 ] ], inf),
		)),

		Pdef(\humT, Pbind(
			\hum, Pseq(   [ [  0,   0,   0,   0,   0 ] ], inf),
			\degree, Pseq([ [-32, -25, -25, -18, -18 ] +.x [0, -12] ], inf),
		)),

		Pdef(\humU, Pbind(
			\hum, Pseq(   [ [  0,   1,   1,   1,   2 ] ], inf),
			\degree, Pseq([ [-32, -32, -25, -25, -25 ] +.x [0, -12, -24] ], inf),
		)),
	];

	~humGroup = Group();

	~currentHumGroup = ~currentHumGroup = nil;
	~humTriggers = ~humPatterns.collect({
		| pdef, i |
		e({
			// ~previousHumGroup = ~currentHumGroup;
			// ~currentHumGroup = Group(~humGroup, \addToTail);
			Pdef(\humMain,  Pdef(\humControl) <> Pbind(\group, ~humGroup.nodeID) <> Pdef(\humBuf) <> pdef <> Pdef(\humBase));
			Log(\gliz, "Now playing Pdef(%) in Group(%)".format(pdef.key, ~humGroup.nodeID));
		})
	});

	~buttonsArray = ((((0..7) * [4]) +.t [0, 1, 2]).flop.flatten[0..21]);
	~buttonsArray.remove(20);
	~triggerButtons = ~buttonsArray.collect({
		|button, i|
		~lc.knobs[button].button.default.toggle_(true).buttonOnActions.add(e({
			~humTriggers[i].value();
		}));
		~lc.knobs[button].button;
	});

	CVModalGroup(*~triggerButtons);

});

State(\gliz).startActions.put(11, {
	Log(\gliz, "Humming on.");
	Pdef(\humMain).play;

	[
		\amp, ~humAmp,
		\rotationSpeed, ~rotationSpeed,
		\bend, ~pitchBend,
	].connectToNode(Server.default, ~humGroup.nodeID);
});

State(\gliz).stopActions.put(11, {
	Log(\gliz, "Humming off.");
	Pdef(\humMain).stop;
});
