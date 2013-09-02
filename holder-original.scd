
/* Not used
s = Server.internal.boot;
p = Dictionary.new;
*/

// Execute one time
(

p[\holder3] = DualEnvir.new(s, "holder3");
p[\holder3].push.linkDoc;
Document.current.proxyBold;

~b_buf = Buffer.new( s );
~b_history = Buffer.alloc( s, 2**22, 1 );
~b_env = Buffer.alloc(s,  2048, 1);
~b_buf.updateInfo({ | a,b,c | [a,b,c].postln; });

~b_buf.allocRead(s, "/Users/scott/Desktop/SET EM BR/sounds/pile1.wav");
~b_buf.play;
~b_history.alloc( s, 2**22 );
~b_env.sine3( [1], [1], [3*pi/2], asWavetable:false );
~b_buffers = [
	"/Users/fsc/Documents/Samples/rawNoise/longping.aiff",
	"/Users/fsc/Documents/Samples/rawNoise/firefox-bin.aiff" ,
	"/Users/fsc/Documents/Samples/rawNoise/QuickTime Player.aiff" ,
	"/Users/fsc/Documents/Samples/playthrough.aiff" ,
	"/Applications/SuperCollider/sounds/doors1.aiff" ,
	"/Applications/SuperCollider/sounds/feldman.aiff",
	"/Applications/SuperCollider/sounds/borges1.aiff"  ];
)


// gui

(
~buf = { HPF.ar( (PlayBuf.ar( 1, ~b_buf.bufnum, rate: 0.9, loop:1 )*0.6), 4) };

~in = ~buf;

~in = NodeProxy.audio;
~in.source = { AudioIn.ar([1,2]) };
~in.source = { PlayBuf.ar(2, ~b_buf.bufnum, loop:1) };

~in.fadeTime = 10;

//~in = { (~hbuf.ar*0.8) }
//~in = { ~out.ar };
//~in = { FreqShift.ar( AudioIn.ar(1), 5)*0.2 }
~in = { Mix.new( p[\holder2][\out].ar +
	p[\holder][\out].ar +
	p[\ats1][\out].ar) };


~play = NodeProxy.audio();

~play.source = {
	| outAmp=0.4, f=20, threshDecay=0.1, feedback=0.1, off=0 |
	var in, rec, freq, reset=0, sig1, sig2, sig, amp,
	threshAmp, recordPhase, loopPoint=0, ph1, ph2, hasFreq, i_readers;
	i_readers = 12;
	freq = f / i_readers;
	in = ~in.ar(1);
	amp = Amplitude.kr( in, 0.001, 0.001 );
	threshAmp = Slew.kr( DelayL.kr( amp, 0.01, 0.01 ), 10000, threshDecay );
	reset =  Trig.ar(amp>threshAmp, freq.reciprocal/2 );

	ph1 = Phasor.ar( 0, 1, 0, freq.reciprocal*44100 );

	recordPhase = Phasor.ar( 0, 1, 0, 2**22 );
	loopPoint = Latch.ar(  recordPhase-64, reset );

	sig =  Splay.ar({
		| i |
		var ph;
		ph =  (ph1 + (i * freq.reciprocal * 44100 / i_readers)) % (freq.reciprocal * 44100);
		(
			sig = BufRd.ar(1, ~b_history.bufnum, ph + Latch.ar( loopPoint, ph < 1), 1 )
			* (0.5 + (0.5 * BufRd.ar(1, ~b_env.bufnum, 2048 * ph / (freq.reciprocal * 44100), 0)))
		);
	} ! i_readers);

	BufWr.ar(in + LeakDC.ar(sig.sum*feedback), ~b_history.bufnum, recordPhase, 0);
	off = Lag.kr( off, 0.4 );
	( sig*outAmp*(1-off) ) + ( in * outAmp * off );
};
~play.play;

~play.set(\f, 60);
~play.set(\threshDecay, 10.01);
~play.set(\feedback, 0.2);


~b_history.loadToFloatArray(action:{
	| array |
	array.average;
});


~x = { MouseX.kr( 0.3, 70 ) };
~y = { MouseY.kr( 0, 1 ) };
~x = Bus.control( s, 1 ).set( 0.5);
~y = Bus.control( s, 1 ).set( 0.1 );
~thresh = Bus.control( s, 1 ).set( 0.1 );

~proc = {
	| kill=0 |
	var sig, amp, env;
	amp = Amplitude.kr( ~play.ar, 0.2, 0.2 );
	env = EnvGen.ar( Env.new( [0,1,0], [1,0.5], releaseNode:1 ), kill );
	sig = ( (env<0.01) * ~play.ar)  +
	( (env>=0.01) * CombL.ar(
		LeakDC.ar( HPF.ar(
			( ~play.ar.round(  env*7*amp ) ),
			1000+(env*6000) ) ),
		1/9000, 1/9000, 58 ) ) ;
};

~out = {| amp=0.9| [~proc.ar, ~proc.ar] * amp};
~out.fadeTime = 0.5;
)

~thresh = {
	LFNoise2.kr( 0.3, 0.01, 0.01 );
}

~off = { LFNoise2.kr( 0.2 ) < 0.5 };
~off.scope;

~thresh.scope;


(

~play.set(\f, 11);
~play.set(\threshDecay, 0.02);
~play.set(\feedback, 0.1);
~play.set(\off, 1.0);
~play.map(\f, ~f);
~play.map(\threshDecay, ~thresh);
~play.map(\feedback, ~y);
	~play.map(\off, ~off);

)
~out.play;
~out.stop;
~out.set( \amp,1)

/*
~proc.set(\kill, 0)
*/


~freq = {
	var freq, hasFreq;
	# freq, hasFreq = Pitch.kr(~in.ar, ampThreshold: 0.02, median: 7);
	Lag.kr(freq/10, 0.1);
}



(

w = SCWindow( "Tablet test", Rect( 100, 800, 310, 600 ) );
w.view.decorator = FlowLayout(w.view.bounds);
t = SCTabletView(w,Rect(40,40,300,300));
w.view.decorator.nextLine;



~c_controls = Array.new(6);
~c_controls.add( EZSlider( w, 280@30, "x", ControlSpec( 0.3, 70.3 ), labelWidth: 80, numberWidth:40) );
~c_controls[0].action_({ |v| p[\holder][\x].source.set( v.value ) }) ;

w.view.decorator.nextLine;


~c_controls.add( 	EZSlider( w, 280@30, "y", ControlSpec( 0.0, 1.1 ), labelWidth: 80, numberWidth:40) );
~c_controls[1].action_({ |v| p[\holder][\y].source.set( v.value ) }) ;

w.view.decorator.nextLine;


~c_controls.add( 	EZSlider( w, 280@30, "pres", ControlSpec( 0.001, 2.00 ), labelWidth: 80, numberWidth:40) );
~c_controls[2].action_({ |v| p[\holder][\thresh].source.set( v.value ); }) ;
w.view.decorator.nextLine;
~c_controls.add( 	EZSlider( w, 280@30, "tiltx", ControlSpec( -1.0, 1.0 ), labelWidth: 80, numberWidth:40) );

w.view.decorator.nextLine;


~c_controls.add( 	EZSlider( w, 280@30, "tilty", ControlSpec( -1.0, 1.0 ), labelWidth: 80, numberWidth:40) );

w.view.decorator.nextLine;


~c_controls.add( 	EZSlider( w, 280@30, "device", ControlSpec( 0, 5 ), labelWidth: 80, numberWidth:40) );


t.background = Color.white;
w.front;

f = { arg  view,x,y,pressure,tiltx,tilty,deviceID, buttonNumber,clickCount,absoluteZ,rotation;
	p[\holder].use({
		~c_controls[0].value = (x/300.0*70.0) + 0.3 ;
		~c_controls[1].value = y/300.0*1.1 ;
		~c_controls[2].value = 2-(pressure*2)-0.0 ;
		~c_controls[3].value = tiltx;
		~c_controls[4].value = tilty;
		~c_controls[5].value = deviceID;
	});
};
t.action = f;
t.mouseUpAction = { p[\holder][\play].set(\off, 1); p[\holder][\c_controls][1].value = 0; };
t.mouseDownAction = { p[\holder][\play].set(\off, 0) };


)