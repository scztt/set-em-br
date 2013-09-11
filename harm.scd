

// Read and process file

s.options.device = ServerOptions.devices[12];

(
var audio, freq, period, buffer, crossingBuffer, synth, pitchBuffer, pitches;
var lastSample=0, lastZeroCrossing=0;

var soundfile = SoundFile.new;
var overshoot, env, path, baseFreq;

path = "/Users/fsc/Documents/_sounds/cello/C-string/C-str-7_mono.aif";
~baseFreq = 262;
//path = "/Users/fsc/Documents/_sounds/cello/C-str-3-mono.wav";
//path = "/Users/fsc/Documents/_sounds/stand/bluett.aiff";
//path = "/Users/fsc/Documents/_sounds/antlers/bear-full.wav";
//path = "/Users/fsc/Documents/_sounds/stand/dolce1.aiff";
//path = "/Users/fsc/Documents/_sounds/cello/scelsi.wav";
//path = "/Users/fsc/Documents/_sounds/playthrough.aiff";
//path = "/Users/fsc/Documents/_sounds/melodica/1.wav";
//path = "/Users/fsc/Desktop/saw.wav";

//Server.default = s = Server.internal.boot;
s.wait;
soundfile.openRead( path );

~audio = audio = Signal.newClear( soundfile.numFrames.postln );
soundfile.readData( audio );
soundfile.close();
~buffer.play;

~zeroCrossings = List.new;

fork {
	var currentPitch, currentPeriod, lastCrossing,
		currentSample, nextSample, nextSampleMod, aValue, bValue, done;

	~buffer = buffer = Buffer.read( s, path );
	pitchBuffer = Buffer.alloc( s, soundfile.numFrames/64 + 100 );
	env = Buffer.loadCollection( s, FloatArray.fill( 1000, 1 ) );
	s.sync;
	n = {
		var sig, hasFreq, freq;
		sig = PlayBuf.ar( 1, buffer.bufnum, doneAction:2 );
		sig = HPF.ar( LPF.ar( sig, 2000), 60 );
		//#freq, hasFreq = Pitch.kr( sig, 200, 100, 800, execFreq: 200, median:14, peakThreshold:0.75, downSample:1 );
		#freq, hasFreq = Tartini.kr( sig );
		freq = Gate.kr( freq, hasFreq>0.85 );
		RecordBuf.kr( Lag3.kr(freq, 0.01), pitchBuffer.bufnum );
	}.play;
	(soundfile.numFrames/soundfile.sampleRate).wait;
	{ pitchBuffer.plot( "pitch", minval: 40, maxval:600 ) }.defer;
	pitchBuffer.getToFloatArray( wait:0.1, timeout:30, action:{ | array | pitches = array; [ soundfile.numFrames, pitches.size].postln });
	2.wait;

	currentSample = 0;
	lastCrossing = 0;
	audio.size.postln;
	while({ currentSample < audio.size }, {
		currentSample.postln;
		0.00001.wait;
		currentPitch = pitches[ currentSample/64 ];

		if( currentPitch > 20, {
			currentPeriod = min(44100 / currentPitch, 44100).round(1);
			nextSample = currentSample + currentPeriod;
			nextSampleMod = 0;

			"\t%\n".postf(currentPeriod);

			if( nextSample < audio.size, {
				done = false;
				while({ (nextSampleMod < currentPeriod) && done.not  }, {
					0.000001.wait;
					"\t%\n".postf(nextSample + nextSampleMod);

					aValue = audio[max(nextSample - nextSampleMod - 1, 0)];
					bValue = audio[max(nextSample - nextSampleMod, 0)];
					if((aValue <= 0) && (bValue > 0) && done.not, {
						~zeroCrossings.add( nextSample - nextSampleMod );
						"Crossing found at % (-% from expected)\n".postf( nextSample - nextSampleMod, nextSampleMod );
						lastCrossing = nextSample - nextSampleMod;
						currentSample = lastCrossing - 1;
						done = true;
					});

					aValue = audio[min(nextSample + nextSampleMod - 1, audio.size - 1)];
					bValue = audio[min(nextSample + nextSampleMod, audio.size - 1)];
					if( (aValue <= 0) && (bValue > 0) && done.not, {
						~zeroCrossings.add( nextSample - nextSampleMod );
						"Crossing found at % (% from expected)\n".postf( nextSample + nextSampleMod, nextSampleMod );
						lastCrossing = nextSample + nextSampleMod;
						currentSample = lastCrossing - 1;
						done = true;
					});

					nextSampleMod = nextSampleMod + 1;
				});
			});
		});
		currentSample = currentSample + 1;
	});
	"DONE".postln;
}
)

~zeroCrossings

(
~crossingBuffer = Buffer.loadCollection(s, ~zeroCrossings.asArray);
~envsize = 1024;
~transition = ~envsize * 0.1;

~envcoll = ~envsize.collect({
	| i |
	case
	{ i < ~transition }
		{ cos(pi * i / ~transition).neg + 1 / 2 }

	{ i > (~envsize - ~transition) }
		{ cos(pi * (~envsize - i) / ~transition).neg + 1 / 2 }
	{ true }
		{ 1};
});
~envcoll.plot;
~env = Buffer.loadCollection(s, ~envcoll);
//~env.loadCollection( ~envcoll );
)

s.sync;
buffer.plot;



(
~synth = {
	var mousePos, startPos,
		startPosA, startPosB,
		nextStartA, nextStartB,
		trig,
		dur, durA, durB, trigDurA, trigDurB,
		trigStartA, trigStartB,
		startA, startB,
		trigNextStartA, trigNextStartB,
		sigA,
		nextStartPosA, nextStartPosB, startPosMix, rate,
		wavelength,
		poll;



	rate = [ 1, 1.05, 0.967 ];

	//startPos = MouseX.kr(0, 1);
	startPos = LFSaw.kr(1/40);
	//startPos = startPos + Resonz.ar( K2A.ar(startPos), 5, 0.1);
	startPos = (startPos * BufSamples.kr( ~crossingBuffer.bufnum )).min(BufSamples.kr( ~crossingBuffer.bufnum )).max(0);
	//startPos = LFSaw.ar([0.01,0.02,0.04, 0.035] / BufDur.kr(~buffer.bufnum)) + MouseX.kr(0,2) % 1;
	startPos = startPos * BufSamples.kr( ~crossingBuffer.bufnum );
	startPos.postln;

	startPosA = Select.kr(startPos.floor%2, [ startPos.floor + 1, startPos.floor ]);
	startPosB = Select.kr(startPos.floor%2, [ startPos.floor, startPos.floor + 1]);
	startPosMix = Select.kr(startPos.floor%2, [ 1 - (startPos - startPosB), startPos - startPosA ]);
	startPosA.postln;

	nextStartPosA = startPosA + 1;
	nextStartPosB = startPosB + 1;

	startA = { Dbufrd( ~crossingBuffer.bufnum, startPosA%BufSamples.kr( ~crossingBuffer.bufnum ), 1 ) };
	startB = { Dbufrd( ~crossingBuffer.bufnum, startPosB%BufSamples.kr( ~crossingBuffer.bufnum ), 1 ) };
	nextStartA ={ Dbufrd( ~crossingBuffer.bufnum, nextStartPosA%BufSamples.kr( ~crossingBuffer.bufnum ), 1 ) };
	nextStartB ={ Dbufrd( ~crossingBuffer.bufnum, nextStartPosB%BufSamples.kr( ~crossingBuffer.bufnum ), 1 ) };

	wavelength = LFNoise2.kr(0.05).range(0.9,1);
	durA = { ( (nextStartA-startA)/SampleRate.ir ).max(0.0000000001).min(1) / wavelength };
	durB = { ( (nextStartB-startB)/SampleRate.ir ).max(0.0000000001).min(1) / wavelength };

	dur = (durB * startPosMix) + (durA * (1-startPosMix));
	dur = 1 / ((rate * 140) + { LFNoise2.kr(300).range(-2,2) });

	#trig, trigStartA, trigStartB, trigNextStartA, trigNextStartB, trigDurA, trigDurB =
		TDuty.ar( dur, 0, [ 1, startA, startB, nextStartA, nextStartB, durA, durB ] );
	//startPosMix = Gate.ar( startPosMix, trig );

	Out.kr(0, [ startPosMix, startPosA, startPosB,
				Gate.ar( trigDurA*rate, trigDurA*rate),
				Gate.ar( trigStartA / BufSamples.kr(~buffer.bufnum), trigStartA / BufSamples.kr(~buffer.bufnum)),
				Gate.ar( trigDurB*rate, trigDurB*rate),
				Gate.ar( trigStartB / BufSamples.kr(~buffer.bufnum) , trigStartB / BufSamples.kr(~buffer.bufnum))
			]);
	sigA = [ XFade2.ar(
				BufGrainB.ar( trig,
					dur: MouseX.kr(0,0.01),
					sndbuf: ~buffer.bufnum,
					rate: wavelength,
					pos: trigStartA / BufSamples.kr(~buffer.bufnum),
					envbuf: ~env.bufnum,
					interp: 4),
				DC.ar(0),
				(startPosMix * 2 - 1)
			),
			XFade2.ar(
				DC.ar(0),
				BufGrainB.ar( trig,
					dur: MouseX.kr(0,0.01),
					sndbuf: ~buffer.bufnum,
					rate: wavelength,
					pos: trigStartB / BufSamples.kr(~buffer.bufnum),
					envbuf: ~env.bufnum,
					interp: 4),
				(startPosMix * 2 - 1)
			)].postln;

	sigA = CombC.ar( sigA, 5,
		[0.1, 0.5, 2.3, 4.5], 0.4 );
	//sigA = FreeVerb.ar( Mix( sigA ), room:2.9 );
	//[ sigA, sigA ];
	//LeakDC.ar( sigA ) * [1,1]
}.play;
)


(
~synth = {
	var mousePos, startPos,
		startPosA, startPosB,
		nextStartA, nextStartB,
		trig,
		dur, durA, durB, trigDurA, trigDurB,
		trigStartA, trigStartB,
		startA, startB,
		trigNextStartA, trigNextStartB,
		sigA,
		nextStartPosA, nextStartPosB, startPosMix, rate,
		wavelength,
		poll;

	rate = 0.1;
	//startPos = startPos + Resonz.ar( K2A.ar(startPos), 5, 0.1);
	//startPos = (startPos * BufSamples.kr( ~crossingBuffer.bufnum )).min(BufSamples.kr( ~crossingBuffer.bufnum )).max(0);
	startPos = LFSaw.ar([0.01,0.02,0.04, 0.035] / BufDur.kr(~buffer.bufnum)) + MouseX.kr(0,2) % 1
		* BufSamples.kr( ~crossingBuffer.bufnum );
	//startPos = LFSaw.ar( 1/BufDur.kr(~buffer.bufnum) ) * BufSamples.kr( ~crossingBuffer.bufnum );
//	startPos = 0.6;

	startPosA = Select.kr(startPos.floor%2, [ startPos.floor + 1, startPos.floor ]);
	startPosB = Select.kr(startPos.floor%2, [ startPos.floor, startPos.floor + 1]);
	startPosMix = Select.kr(startPos.floor%2, [ 1 - (startPos - startPosB), startPos - startPosA ]);

	nextStartPosA = startPosA + 1;
	nextStartPosB = startPosB + 1;

	startA = { Dbufrd( ~crossingBuffer.bufnum, startPosA%BufSamples.kr( ~crossingBuffer.bufnum ), 1 ) };
	startB = { Dbufrd( ~crossingBuffer.bufnum, startPosB%BufSamples.kr( ~crossingBuffer.bufnum ), 1 ) };
	nextStartA ={ Dbufrd( ~crossingBuffer.bufnum, nextStartPosA%BufSamples.kr( ~crossingBuffer.bufnum ), 1 ) };
	nextStartB ={ Dbufrd( ~crossingBuffer.bufnum, nextStartPosB%BufSamples.kr( ~crossingBuffer.bufnum ), 1 ) };

	wavelength = 1;
	durA = { ( (nextStartA-startA)/SampleRate.ir ).max(0.0000000001).min(1) / wavelength };
	durB = { ( (nextStartB-startB)/SampleRate.ir ).max(0.0000000001).min(1) / wavelength };
	dur = (durB * startPosMix) + (durA * (1-startPosMix));
	//dur = 1 / 140;

	#trig, trigStartA, trigStartB, trigNextStartA, trigNextStartB, trigDurA, trigDurB =
		TDuty.ar( dur, 0, [ 1, startA, startB, nextStartA, nextStartB, durA, durB ] );
	//startPosMix = Gate.ar( startPosMix, trig );

	Out.kr(0, [ startPosMix, startPosA, startPosB,
				Gate.ar( trigDurA*rate, trigDurA*rate),
				Gate.ar( trigStartA / BufSamples.kr(~buffer.bufnum), trigStartA / BufSamples.kr(~buffer.bufnum)),
				Gate.ar( trigDurB*rate, trigDurB*rate),
				Gate.ar( trigStartB / BufSamples.kr(~buffer.bufnum) , trigStartB / BufSamples.kr(~buffer.bufnum))
			]);
	sigA = [ XFade2.ar(
				BufGrainB.ar( trig,
					dur: MouseX.kr(0,0.01),
					sndbuf: ~buffer.bufnum,
					rate: wavelength,
					pos: trigStartA / BufSamples.kr(~buffer.bufnum),
					envbuf: ~env.bufnum,
					interp: 4),
				DC.ar(0),
				(startPosMix * 2 - 1)
			),
			XFade2.ar(
				DC.ar(0),
				BufGrainB.ar( trig,
					dur: MouseX.kr(0,0.01),
					sndbuf: ~buffer.bufnum,
					rate: wavelength,
					pos: trigStartB / BufSamples.kr(~buffer.bufnum),
					envbuf: ~env.bufnum,
					interp: 4),
				(startPosMix * 2 - 1)
			)];
	sigA = sigA.flop.sum.postln;
/*	sigA = [
		BufGrainB.ar( trig,
			dur: MouseX.kr(0,0.01),
			sndbuf: ~buffer.bufnum,
			rate: wavelength,
			pos: trigStartA / BufSamples.kr(~buffer.bufnum),
			envbuf: ~env.bufnum,
			interp: 4),
		BufGrainB.ar( trig,
			dur: MouseX.kr(0,0.01),
			sndbuf: ~buffer.bufnum,
			rate: wavelength,
			pos: trigStartB / BufSamples.kr(~buffer.bufnum),
			envbuf: ~env.bufnum,
			interp: 4)
	];*/

	//sigA = CombC.ar( sigA, 5,
	//	[0.1, 0.5, 2.3, 4.5], 0.4 );
	//sigA = FreeVerb.ar( Mix( sigA ), room:2.9 );
	//sigA;
	LeakDC.ar( sigA.sum ) * [1,1]
}.play;
)



(
d = SynthDef(\cellell, {
	| baseFreq = 100, squeal=0 |
	var mousePos, startPos,
		startPosA, startPosB,
		nextStartA, nextStartB,
		trig,
		dur, durA, durB, trigDurA, trigDurB,
		trigStartA, trigStartB,
		startA, startB,
		trigNextStartA, trigNextStartB,
		sigA,
		nextStartPosA, nextStartPosB, startPosMix, rate,
		wavelength,
		poll;

	rate = BufDur.kr(~buffer.bufnum) * 8;

	startPos = 0.0;
	//startPos = In.kr( ~korg.busNum(\knob1) );
	//startPos = startPos + Resonz.ar( K2A.ar(startPos), 5, 0.1);
	startPos = LFSaw.kr(1 / rate);
	startPos = startPos * BufSamples.kr( ~crossingBuffer.bufnum );

	startPosA = Select.kr(startPos.floor%2, [ startPos.floor + 1, startPos.floor ]);
	startPosB = Select.kr(startPos.floor%2, [ startPos.floor, startPos.floor + 1]);
	startPosMix = Select.kr(startPos.floor%2, [ 1 - (startPos - startPosB), startPos - startPosA ]);

	nextStartPosA = startPosA + 1;
	nextStartPosB = startPosB + 1;

	startA = { Dbufrd(~crossingBuffer.bufnum, startPosA % BufSamples.kr(~crossingBuffer.bufnum), 1) };
	startB = { Dbufrd(~crossingBuffer.bufnum, startPosB % BufSamples.kr(~crossingBuffer.bufnum), 1) };
	nextStartA ={ Dbufrd(~crossingBuffer.bufnum, nextStartPosA % BufSamples.kr(~crossingBuffer.bufnum), 1) };
	nextStartB ={ Dbufrd(~crossingBuffer.bufnum, nextStartPosB % BufSamples.kr(~crossingBuffer.bufnum), 1) };

	wavelength = 0.5;
	durA = { ( (nextStartA-startA)/SampleRate.ir ).max(0.0000000001).min(1) / wavelength };
	durB = { ( (nextStartB-startB)/SampleRate.ir ).max(0.0000000001).min(1) / wavelength };
	//dur = (durB * startPosMix) + (durA * (1-startPosMix));

	sigA = (baseFreq * [1, 1.99]).collect({
		|freq|
		var sig;

		dur = 1 / freq;

		#trig, trigStartA, trigStartB, trigNextStartA, trigNextStartB, trigDurA, trigDurB =
		TDuty.ar( dur, 0, [ 1, startA, startB, nextStartA, nextStartB, durA, durB ] );
		//startPosMix = Gate.ar( startPosMix, trig );

		//	Out.kr(0, [ startPosMix, startPosA, startPosB,
		//				Gate.ar( trigDurA*rate, trigDurA*rate),
		//				Gate.ar( trigStartA / BufSamples.kr(~buffer.bufnum), trigStartA / BufSamples.kr(~buffer.bufnum)),
		//				Gate.ar( trigDurB*rate, trigDurB*rate),
		//				Gate.ar( trigStartB / BufSamples.kr(~buffer.bufnum) , trigStartB / BufSamples.kr(~buffer.bufnum))
		//			]);
		sig = [
			XFade2.ar(
				BufGrainB.ar( trig,
					dur: dur * squeal.range(1, 15),
					sndbuf: ~buffer.bufnum,
					rate: wavelength,
					pos: trigStartA / BufSamples.kr(~buffer.bufnum),
					envbuf: ~env.bufnum,
				interp: 4),
				DC.ar(0),
				(startPosMix * 2 - 1)
			),
			XFade2.ar(
				DC.ar(0),
				BufGrainB.ar( trig,
					dur: dur * squeal.range(1, 15),
					sndbuf: ~buffer.bufnum,
					rate: wavelength,
					pos: trigStartB / BufSamples.kr(~buffer.bufnum),
					envbuf: ~env.bufnum,
					interp: 4),
				(startPosMix * 2 - 1)
		)];
	});
	sigA = sigA.sum;

	sigA = [
		CombC.ar( sigA[0], 5,
			[0.1, 0.5, 2.3, 4.5], 0.4 ),
		CombC.ar( sigA[1], 5,
			[0.1, 0.5, 2.3, 4.5], 0.4 )
	];
	sigA.postln;
	sigA = Mix(sigA.flop).postln;
	sigA = FreeVerb2.ar(sigA[0], sigA[1], room:2.9 ).sum;

	sigA = LeakDC.ar( sigA ) * [1,1];
	Out.ar(0, sigA);
}).add;
DotViewer.directory = "~/Desktop".standardizePath;
d.draw;
)


(
\instrument: \cellell,
\baseFreq: 100 * [1, 7/5],
\squeal: 0.2,
).play


k.asBus(\knob1).debugScope

~baseFreq * 12