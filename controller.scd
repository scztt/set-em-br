// .value\W+= (.*);

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
		State(\peng)[\lcb].connect();
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

	// Log(\control, "READY");
});

State(\control).doInit();