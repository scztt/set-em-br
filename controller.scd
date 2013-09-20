// s.options.device = "Fireface 800 (C2F)";
// s.reboot;
State(\main).use({
	~lc.postln;
	if (~lc.notNil) { ~lc.disconnect.free };
	~lc = LCDevice();
	~lc.connect;
	~currentState = nil;

	~lc.buttons[0..3].do({
		|b|
		b.default.toggle_(true);
	});

	~lc.buttons[0].buttonOnActions.add(e{
		"peng connected".postln;
		State(\peng)[\lc].connect();
		~currentState = State(\peng);
	});

	~lc.buttons[0].buttonOffActions.add(e{
		"peng disconnected".postln;
		State(\peng)[\lc].disconnect();
	});

	~lc.buttons[1].buttonOnActions.add(e{
		"mass connected".postln;
		State(\mass)[\lc].connect();
		~currentState = State(\mass);
	});

	~lc.buttons[1].buttonOffActions.add(e{
		"mass disconnected".postln;
		State(\mass)[\lc].disconnect();
	});

	~lc.buttons[2].buttonOnActions.add({
		"button 2 on".postln;
		State(\gliz)[\lc].connect();
		~currentState = State(\gliz);
	});

	~lc.buttons[2].buttonOffActions.add({
		State(\gliz)[\lc].disconnect();
	});

	CVModalGroup(*~lc.buttons[0..3]);
});

