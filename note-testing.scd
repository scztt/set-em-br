(
~base = 30;
~scale = 100.collect({
	|i|
	[
		Scale.dorian.degreeToFreq(7.rand, ~base.midicps, 2.rand),
		Scale.dorian.degreeToFreq([1, 4, 6][i % 3], ~base.midicps, 2.rand),
		Scale.dorian.degreeToFreq([3, 5, 8][i % 3], ~base.midicps, 2.rand),
		Scale.dorian.degreeToFreq([2, 7, 11][i % 3], ~base.midicps, 2.3.rand.floor),
		Scale.dorian.degreeToFreq([1, 5, 10][i % 3], ~base.midicps, 1 + 2.rand.floor),
		Scale.dorian.degreeToFreq([2, 6, 13][i % 3], ~base.midicps, 1 + 2.rand),
		Scale.dorian.degreeToFreq([2, 4, 6, 13][i % 4], ~base.midicps, 3.rand),
	]
}).flop;

)

~fx = 6;

SynthDef(\saw, {
	|freq = 100, gate = 1|
	var sig;
	sig = LPF.ar(LFSaw.ar(freq, 1.0.rand), 1000);
	sig = sig * EnvGen.kr(Env.adsr(), gate: gate, doneAction: 2);
	Out.ar([0, 1], sig * 0.01);
}).add;

Pdef(\test, Pbind(
	\instrument, \saw,
	\freq, Pfunc({ ~scale[~fx].choose.value }),
	\dur, Pseq([0.02], inf)
)).play;