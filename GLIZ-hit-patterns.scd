State(\gliz).initActions.put(12, {
	SynthDef(\glassHit, {
		| out = 0, amp, buffer, freq = 440, baseFreq = 440, rotation = 0, dur = 1 |
		var rate, env, envAmt, sig, doneAction;
		rate = freq / baseFreq;

		sig = PlayBuf.ar(3, buffer, rate, doneAction: 2) * 0.05;
		sig = Splay.ar(sig) * amp;
		sig = Rotate2.ar(sig[0], sig[1], rotation);
		doneAction = (dur < 0.3).if(2, 0);
		env = EnvGen.ar(Env.perc(0.001, 1), doneAction: doneAction);
		envAmt = ((0.4 - dur) / 0.3).min(1).max(0);
		sig = (sig * (1 - envAmt)) + (sig * env * envAmt);

		Out.ar(out, sig);
	}).add;

	Pdef(\glassBase, Pbind(
		\instrument, \glassHit,
		\dur, Pseq([1], inf),
		\amp, 1,
		\glassName, Prand([\A, \D, \E], inf),
		\glass, Pfunc({ |e| e.putAll(State(\gliz)[\glassHits][e[\glassName]].choose()) }),
		\buffer, Pfunc({ |e| e[\buffer].bufnum }),
		\octave, 5,
		\degree, Pseq([1], inf),
		\rotation, Pseg(Pseq([-0.1, 0.1, -0.1], inf), Pseq([20] , inf), \sin, inf)
	));


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
			Pseq([0.9, 1.3, 1.1, 0.9, 1, 0.3, 1, 0.8, 1, 0.1, 1.0, 1.05] * 0.3, inf),
			Pfunc({ rrand(2, 4) }),
			\sine, inf
		),
		\amp, Ppatlace([
			Pseq(30.collect({ |i| (i/30).sin * 1.0 }), inf),
			Prand([0.1, 0.2, 0.2, 0.25, 0.15, 0.3, 2], inf)
		], inf)
	));

	Pdef(\jump1, Pbind(\degree, Pkey(\baseDegree) + 4.2));


	Pdef(\glassHits,  Pdef(\glassStutter2) <> Pdef(\repeated) <> Pdef(\notes1) <> Pdef(\glassBase)).play;
	Pdef(\glassAccent, Pdef(\jump1) <> Pdef(\repeated) <> Pdef(\notes1) <> Pdef(\glassBase)).stop;


});
