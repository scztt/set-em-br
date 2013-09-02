
/* Not used
s = Server.internal.boot;
p = Dictionary.new;
*/

// Execute one time
(

p[\holder3] = DualEnvir.new(s, "holder3");
p[\holder3].push.linkDoc;
Document.current.proxyBold;

~b_buf = Buffer(s);
~b_buf.allocRead(s, "/Users/fsc/Desktop/SET EM BR/sounds/pile1.wav");
~b_buf.allocRead(s, "/Users/fsc/Desktop/SET EM BR/sounds/02-rrose-waterfall-test.wav");
~b_buf.allocRead(s, "/Users/fsc/Desktop/SET EM BR/sounds/pile-dist-1.wav");
~b_buf.allocRead(s, "/Users/fsc/Desktop/SET EM BR/sounds/barrell-roll_3.wav");
~b_buf.allocRead(s, "/Users/fsc/Desktop/SET EM BR/sounds/loop1.wav")

~b_buf.updateInfo;
~b_history = Buffer.alloc(s, 2**22, 4);
~b_history.zero;

~b_env = Buffer.alloc(s,  2048, 1);
~b_env.sine3([1], [1], [3*pi/2], asWavetable:false);


~in = NodeProxy.audio(s, 4);
//~in.source = { AudioIn.ar([1,2]) };
//~in.source = { SinOsc.ar(40); };
~in.source = { PlayBuf.ar(4, ~b_buf.bufnum, loop:1) };
~in.source = {
	var sig;
	sig = PlayBuf.ar(2, ~b_buf.bufnum, loop:1);
	sig ++ sig
};
~b_buf.plot

~in.fadeTime = 10;

~play = NodeProxy.audio();

(
~b_history.zero;
~play.source = {
	arg inBus = 99, outAmp = 0.4, f = 20, threshDecay = 0.1, feedback = 0.1, off = 0;
	var in, rec, freq, reset = 0, sig1, sig2, sig, quadSig, stereoSig, stereoIn, amp,
	ampThresh, recordPhase, loopPoint = 0, ph1, ph2, hasFreq, i_readers, sr, notes;

	sr = SampleRate.ir();
	i_readers = 10;
	freq = f;
	in = InFeedback.ar(inBus, 4);

	amp = Amplitude.kr(in.sum / in.size, 0.001, 0.001);
	ampThresh = Slew.kr(DelayL.kr(amp, 0.01, 0.01), 10000, threshDecay);
	reset = Trig.ar(amp > ampThresh, freq.reciprocal / 2);

	recordPhase = Phasor.ar(0, 1, 0, 2**22);
	loopPoint = Latch.ar(recordPhase - 64, reset);

	notes = [55, 58, 62, 67, 70, 79, 82, 86, 91, 94].midicps.scramble / 2;
	notes = notes ++ notes;

	sig = i_readers.collect({
		| i |
		var basePh, ph, readerFreq, historySig, monoSig;
		readerFreq = freq + SinOsc.ar(rand(0.02) + 0.02, rand(0.1), freq * 0.05);
		basePh = Phasor.ar( 0, 1, 0, readerFreq.reciprocal * sr );
		ph =  (basePh + (i * readerFreq.reciprocal * sr / i_readers)) % (readerFreq.reciprocal * sr);

		historySig = BufRd.ar(4, ~b_history.bufnum, ph + Latch.ar(loopPoint, ph < 1), 1);
		monoSig = SelectX.ar(i / i_readers * historySig.size, historySig);
		monoSig = monoSig * BufRd.ar(1, ~b_env.bufnum, 2048 * ph / (readerFreq.reciprocal * sr), 0).range(0, 1);
		monoSig = LeakDC.ar(monoSig);
	});

	quadSig = SplayAz.ar(4, sig[5..9] ++ sig[0..4]);
	BufWr.ar(in + LeakDC.ar(quadSig * feedback), ~b_history.bufnum, recordPhase, 0);

	sig = sig.collect({
		| sig, i |
		sig + LPF.ar(CombC.ar(sig, 0.2, notes[i].reciprocal, (SinOsc.ar(0.03, rand(0.1) + 0.1).range(0, 1).pow(4) * 0.3)), 2000);
	});

	stereoSig = Splay.ar(sig);
	stereoSig = Compander.ar(stereoSig, stereoSig, 0.7, 1, 0.1);
	stereoIn = Splay.ar(in);

	off = Lag.kr( off, 0.4 );

	(stereoSig * outAmp * (1 - off)) + (stereoIn * outAmp * off);
};
~play.play;
~play.set(\inBus, ~in.bus.index);
~play.set(\f, 20);
~play.set(\threshDecay, 10.9);
~play.set(\feedback, 1.8);
~play.set(\outAmp, 1);
~play.set(\off, 0.0);
)

TwoTube