

// Read and process file

s.options.device = ServerOptions.devices[12];

(
var audio, freq, period, buffer, crossingBuffer, synth, pitchBuffer, pitches;
var lastSample=0, lastZeroCrossing=0;

var soundfile = SoundFile.new;
var overshoot, env, path, baseFreq;

//path = "/Users/fsc/Documents/_sounds/cello/C-string/C-str-7_mono.aif";
~baseFreq = 262;
path = "/Users/fsc/Documents/_sounds/cello/C-str-3-mono.wav";
//path = "/Users/fsc/Documents/_sounds/stand/bluett.aiff";
//path = "/Users/fsc/D.ocuments/_sounds/antlers/bear-full.wav";
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
//~buffer.play;
~rms = {
	| sig, windowSize = 64 |
	var pos, sum=0, result;
	result = sig.copy();
	sum = sig[0..windowSize].sum({ |v| v * v });

	Range(windowSize, sig.size - windowSize).do({
		| i |
		sum = sum + (sig.foldAt(i)).pow(2)
		- (sig.foldAt(i - windowSize).pow(2));
		result[i - (windowSize / 2)] = sum.pow(0.5);
	});
	result;
};
~audiorms = ~rms.(~audio, 8);

~zeroCrossings = List.new;


fork {
	var currentPitch, currentPeriod, lastCrossing,
	currentSample, nextSample, nextSampleMod, aValue, bValue, done,
	searchStart, searchEnd, maxIndex, plotter;

	~buffer = buffer = Buffer.read( s, path );
	pitchBuffer = Buffer.alloc( s, soundfile.numFrames/64 + 100 );
	env = Buffer.loadCollection( s, FloatArray.fill( 1000, 1 ) );
	s.sync;
	n = {
		var sig, hasFreq, freq;
		sig = PlayBuf.ar( 1, buffer.bufnum, doneAction:2 );
		sig = HPF.ar( LPF.ar( sig, 2000), 60 );
		//#freq, hasFreq = Pitch.kr( sig, 800, 100, 1400, execFreq: 200, median:14, peakThreshold:0.75, downSample:1 );
		#freq, hasFreq = Tartini.kr(sig, n:2048 , k:2048, overlap:1024, smallCutoff:0.7);
		freq = Gate.kr( freq, hasFreq > 0.45 );
		RecordBuf.kr( Lag3.kr(freq, 0.01), pitchBuffer.bufnum );
	}.play;
	(soundfile.numFrames/soundfile.sampleRate).wait;
	{ pitchBuffer.plot( "pitch", minval: 40, maxval:1600 ) }.defer;
	pitchBuffer.getToFloatArray( wait:0.1, timeout:30, action:{ | array | pitches = array; [ soundfile.numFrames, pitches.size].postln });

	currentSample = 0;
	lastCrossing = 0;
	audio.size.postln;

	{ plotter = ([0 ! 512, 0 ! 512]).plot }.defer;
	0.5.wait;
	while({ currentSample < audio.size }, {
		currentPitch = pitches[currentSample / 64];

		if( currentPitch > 20, {
			currentPeriod = min(~buffer.sampleRate / currentPitch, ~buffer.sampleRate).round(1);
			nextSample = currentSample + currentPeriod;
			searchStart = (nextSample - (currentPeriod / 4)).asInteger;
			searchEnd = (nextSample + (currentPeriod / 4)).asInteger;

			maxIndex = ~audiorms.asArray[searchStart..searchEnd].maxIndex;

			{
				plotter.setValue([
					~audio.asArray[searchStart..searchEnd],
					~audiorms.asArray[searchStart..searchEnd]
				]);
			}.defer;
			0.001.wait;

			if (maxIndex.isNil) {
				maxIndex = nextSample ?? 0;
				"No max found: %".postf(~audiorms.asArray[searchStart..searchEnd]);
			};
			maxIndex = searchStart + maxIndex;

			"\t%:% [%..%] -> %\n".postf(currentSample, currentPeriod, searchStart, searchEnd, maxIndex - nextSample);
			~zeroCrossings.add(maxIndex);
			//~zeroCrossings.add(nextSample);
			currentSample = maxIndex;
		}, {
			currentSample = currentSample + 1;
		});
	});
	"DONE".postln;
}
)


~splits = FloatArray.newClear(~audio.size);
~zeroCrossings.do { |i|
	~splits[i] = 1;
};

~plotLoc = {
	|l|
	[
		~splits[~zeroCrossings[l].asInteger..~zeroCrossings[l + 20].asInteger],
		~audio[~zeroCrossings[l].asInteger..~zeroCrossings[l + 20].asInteger],
		~audiorms[~zeroCrossings[l].asInteger..~zeroCrossings[l + 20].asInteger],
	].plot;
};
~plotLoc.(2200);

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
	var mousePos, centerPos,
		centerPosA, centerPosB,
	centerA, centerB,
		nextCenterA, nextCenterB,
		startA, startB, nextStartA, nextStartB,
		trig,
		dur, durA, durB, trigDurA, trigDurB,
		trigStartA, trigStartB,
		trigNextStartA, trigNextStartB,
		sigA,
		nextcenterPosA, nextcenterPosB, centerPosMix, rate,
		wavelength,
		poll;



	rate = [1];

	centerPos = LFSaw.kr(1 / 40);

	//centerPos = (centerPos * BufSamples.kr( ~crossingBuffer.bufnum )).min(BufSamples.kr( ~crossingBuffer.bufnum )).max(0);
	//centerPos = LFSaw.ar([0.01,0.02,0.04, 0.035] / BufDur.kr(~buffer.bufnum)) + MouseX.kr(0,2) % 1;
	centerPos = centerPos * BufSamples.kr(~crossingBuffer.bufnum);
	centerPos.postln;

	centerPosA = 	Select.kr(centerPos.floor % 2, [centerPos.floor + 1, centerPos.floor]);
	centerPosB = 	Select.kr(centerPos.floor % 2, [centerPos.floor, centerPos.floor + 1]);
	centerPosMix = 	Select.kr(centerPos.floor % 2, [1 - (centerPos - centerPosB), centerPos - centerPosA]);
	centerPosA.postln;

	nextcenterPosA = centerPosA + 1;
	nextcenterPosB = centerPosB + 1;

	centerA = 		{ Dbufrd(~crossingBuffer.bufnum, centerPosA % BufSamples.kr(~crossingBuffer.bufnum), 1) };
	centerB = 		{ Dbufrd(~crossingBuffer.bufnum, centerPosB % BufSamples.kr(~crossingBuffer.bufnum), 1) };
	nextCenterA =	{ Dbufrd(~crossingBuffer.bufnum, nextcenterPosA % BufSamples.kr(~crossingBuffer.bufnum), 1) };
	nextCenterB =	{ Dbufrd(~crossingBuffer.bufnum, nextcenterPosB % BufSamples.kr(~crossingBuffer.bufnum), 1) };

	//wavelength = LFNoise2.kr(0.05).range(0.9,1);
	wavelength = 2;
	durA = { ( (nextCenterA - centerA)/SampleRate.ir ).max(0.0000000001).min(1) / wavelength };
	durB = { ( (nextCenterB - centerB)/SampleRate.ir ).max(0.0000000001).min(1) / wavelength };

	startA = centerA - (durA / 2);
	startB = centerB - (durB / 2);
	nextStartA = nextCenterA - (durA / 2);
	nextStartB = nextCenterB - (durB / 2);

	dur = durA + ((durB - durA) * centerPosMix);
	//dur = 1 / ((rate * 140) + { LFNoise2.kr(300).range(-2,2) });

	#trig, trigStartA, trigStartB, trigNextStartA, trigNextStartB, trigDurA, trigDurB =
		TDuty.ar( dur, 0, [ 1, startA, startB, nextStartA, nextStartB, durA, durB ] );
	//centerPosMix = Gate.ar( centerPosMix, trig );

	Out.kr(0, [ centerPosMix, centerPosA, centerPosB,
				Gate.ar( trigDurA*rate, trigDurA*rate),
				Gate.ar( trigStartA / BufSamples.kr(~buffer.bufnum), trigStartA / BufSamples.kr(~buffer.bufnum)),
				Gate.ar( trigDurB*rate, trigDurB*rate),
				Gate.ar( trigStartB / BufSamples.kr(~buffer.bufnum) , trigStartB / BufSamples.kr(~buffer.bufnum))
			]);
	sigA = [ XFade2.ar(
				BufGrainB.ar( trig,
					dur: dur,
					sndbuf: ~buffer.bufnum,
					rate: 1,
					pos: trigStartA / BufSamples.kr(~buffer.bufnum),
					envbuf: ~env.bufnum,
					interp: 4),
				DC.ar(0),
				(centerPosMix * 2 - 1)
			),
			XFade2.ar(
				DC.ar(0),
				BufGrainB.ar( trig,
					dur: dur,
					sndbuf: ~buffer.bufnum,
					rate: 1,
					pos: trigStartB / BufSamples.kr(~buffer.bufnum),
					envbuf: ~env.bufnum,
					interp: 4),
				(centerPosMix * 2 - 1)
			)].postln;

	sigA = CombC.ar( sigA, 5,
		[0.1, 0.5, 2.3, 4.5], 0.4 );
	//sigA = FreeVerb.ar( Mix( sigA ), room:2.9 );
	//[ sigA, sigA ];
	//LeakDC.ar( sigA ) * [1,1]
}.play;
)

