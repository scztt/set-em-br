State(\gliz).initActions.put(12, {
	SynthDef(\glassHit, {
		| out = 0, amp = 1, vel = 0.3, buffer, freq = 440, baseFreq = 440, rotation = 0, dur = 1 |
		var rate, env, envAmt, sig, doneAction,
		a, b, c, d, e, f, g, h, bSig, velEnv;
		rate = freq / baseFreq;

		sig = PlayBuf.ar(3, buffer, rate, doneAction: 2) * 0.3;

		doneAction = (dur < 0.3).if(2, 0);
		env = EnvGen.ar(Env.perc(0.001, 1), doneAction: doneAction);
		envAmt = ((0.4 - dur) / 0.3).min(1).max(0);
		sig = (sig * (1 - envAmt)) + (sig * env * envAmt);
		vel = vel.pow(4);
		velEnv = EnvGen.ar(Env([vel.max(0.01), 1], [6], 4)).range(30, 12400);
		sig = LPF.ar(sig, velEnv, mul:amp);

		bSig = PanB2.ar(sig[0], rotation.wrap(-1, 1))
		+ PanB2.ar(sig[1], (rotation + 0.2).wrap(-1, 1))
		+ PanB2.ar(sig[2], (rotation - 0.2).wrap(-1, 1));

		#a, c, d, b = DecodeB2.ar(4, bSig[0], bSig[1], bSig[2], 0.5);
		#e, g, h, f = DecodeB2.ar(4, bSig[0], bSig[1], bSig[2], 0.5);

		Out.ar(out, [a, b, c, d, e, f, g, h]);
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
		\baseDegree, Pseq([1], inf),
		\rotation, 0
	));

	Pdef(\hitRotate, Pbind(
		\rotation, Pseq([-1, 1], inf) * Pseg(Pseq([0, 1, 0], inf), Pwhite(10, 15), \sin);
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

	Pdef(\hitControl, Pbind(
		\dur, Pfunc({ |e| ~hitSpeed.value * e[\dur] }),
		\amp, Pfunc({|e| ~hitAmp.value * e[\amp] })
	));

	Pdef(\glassStutter2, Pdef(\glassDurVary) <> Pdef(\glassStutter1));

	Pdef(\glassMostlyQuiet, Pbind(
		\amp, Pseq(Pfunc({ rrand(0.8, 0.4) }) ! 7 ++ [1], inf)
	));

	Pdef(\repeated, Pbind(
		\baseDegree, Pkey(\baseDegree)
		+ Pseg(
			Pfunc({ rrand(1, 1.023) }) * Pser([0, 0.024, 0, -0.01, 0, -0.004, 0.009, -0.032], inf),
			Pfunc({ rrand(5.0, 8.0) })
		),
		\degree, Pkey(\baseDegree) * 1,
		\dur, Pseg(
			Pseq([0.96, 1.1, 1.02, 0.96, 1, 0.3, 1, 0.89, 1, 0.04, 1.0, 1.03] * 0.3, inf),
			Pfunc({ rrand(2, 4) }),
			\sine, inf
		),
		\amp, Ppatlace([
			Pseq(30.collect({ |i| (i/30).sin * 1.0 }), inf),
			Prand([0.1, 0.2, 0.2, 0.25, 0.15, 0.3, 2], inf)
		], inf),
		\vel, Prand([0.0, 0.1, 0.3, 0.4, 0.3, 0.6, 1], inf)
	));

	Pdef(\jump1, Pbind(\degree, Pkey(\baseDegree) + 4.2));

	Pdef(\hitA, Pbind(
		\baseDegree, 3
	));


	Pdef(\glassAccent, Pdef(\jump1) <> Pdef(\repeated) <> Pdef(\notes1) <> Pdef(\glassBase)).stop

});

State(\gliz).startActions.put(12, {
	Pdef(\glassHits,
		Pdef(\hitRotate) <> Pdef(\hitA) <> Pdef(\hitControl) <>  Pdef(\repeated) <> Pdef(\hitA) <> Pdef(\glassBase)).play;
});


State(\gliz).stopActions.put(12, {
	Pdef(\glassHits).stop;
});

