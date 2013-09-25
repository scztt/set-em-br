// .value\W+= (.*);
//	#c, d, a, b = PanAz.ar(4, sig, MouseX.kr(-1, 0.5).poll, orientation: 0);

Log.logErrors();

LogWindow(\perf, [\gliz, \peng, \mass, \control, \error]).gui();
LogWindow(\perf).clear;

EnvirWindow.show();

Require("server-config", always: true);
Require("GLIZ", always: true);
Require("PENG", always: true);
Require("MASS", always: true);

State(\control).clear();
State(\control).initActions.add({

	if (~lc.notNil) { ~lc.disconnect.free };
	~lc = LCDevice();
	~currentState = nil;

	~lc.buttons[0..3].do({
		|b|
		b.default.toggle_(true);
	});

	~lc.buttons[0].buttonOnActions.add(e{
		Log(\peng, "connected");
		State(\peng)[\lc].connect();
		~currentState = State(\peng);
	});

	~lc.buttons[0].buttonOffActions.add(e{
		//Log(\peng, "disconnected");
		State(\peng)[\lc].disconnect();
	});

	~lc.buttons[1].buttonOnActions.add(e{
		Log(\mass, "connected");
		State(\mass)[\lc].connect();
		~currentState = State(\mass);
	});

	~lc.buttons[1].buttonOffActions.add(e{
		//Log(\mass, "disconnected");
		State(\mass)[\lc].disconnect();
	});

	~lc.buttons[2].buttonOnActions.add({
		Log(\gliz, "connected");
		State(\gliz)[\lc].connect();
		~currentState = State(\gliz);
	});

	~lc.buttons[2].buttonOffActions.add({
		//Log(\gliz, "disconnected");
		State(\gliz)[\lc].disconnect();
	});

	CVModalGroup(*~lc.buttons[0..3]);

	~lc.connect;

/*	~mixdown = {
		var stereoSig, sig = In.ar(0, 8);
		stereoSig = 0.2 * [
			sig[0] + sig[2] + sig[4] + sig[6] ,
			sig[1] + sig[3] + sig[5] + sig[7]
		];
		ReplaceOut.ar(0, stereoSig ++ sig);
	}.play(target: s, addAction: \addAfter);*/

	~mixdown = {
		var sig = In.ar(0, 10);
		ReplaceOut.ar(0, (DC.ar(0) ! 2) ++ sig);
	}.play(target: s, addAction: \addAfter);

	// Log(\control, "READY");
});

State(\control).freeActions.add({
	~mixdown.free;
});

State(\control).doInit();b