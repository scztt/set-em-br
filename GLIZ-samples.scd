State(\gliz).initActions.put(10, {

	Log(\gliz, "Loading gliz samples.");

	~glassNote = (
		A:		432 * 4,
		B:		964,
		D:		716,
		E:		755,
	);

	~humNote = (
		HumA2_45: 428,
		HumA1_44: 428,
		HumI_53: 439,
		HumH_52: 721,
		HumF_50: 751,
		HumG_51: 930,
		HumD1_48: 962,
		HumC1_47: 960,
		HumE1_49: 965,
		HumB1_46: 1081,
	);

	~glassSort = {|a, b| a[\baseFreq] < b[\baseFreq]};
	~glassHits = (
		A: List(),
		B: List(),
		D: List(),
		E: List(),
	);
	~glassHums = SortedList(10, ~glassSort);

	~highLongMono = (
		\baseFreq: 964,
		\buffer: Buffer.readChannel(s, "/Users/fsc/Desktop/SET EM BR/sounds/B_good_30.wav", channels:[2]);
	);
	~lowLongMono = (
		\baseFreq: 964,
		\buffer: Buffer.readChannel(s, "/Users/fsc/Desktop/SET EM BR/sounds/A_8.wav", channels:[2]);
	);
	~resources.add(~highLongMono[\buffer]);
	~resources.add(~lowLongMono[\buffer]);

	~glassPath = PathName("/Users/fsc/Desktop/SET EM BR/sounds");
	~glassPath.entries.do({
		| path |
		var sound, name = path.fileName;

		if (path.extension == "wav") {
			path.postln;
			if ("^[A-Z]_.*".matchRegexp(name)) {
				sound = (
					path: path.asAbsolutePath(),
					baseFreq: ~glassNote[name[0].asSymbol]
				);
				// "Hit: %".format(sound[\path]).postln;
				~glassHits[name[0].asSymbol].add(sound);

			} {
				if (name[0..2] == "Hum") {
					sound = (
						path: path.asAbsolutePath,
						baseFreq: ~humNote[path.fileNameWithoutExtension.asSymbol]
					);
					// "Hum: %".format(sound[\path]).postln;
					~glassHums.add(sound);
				} {
					// "Dunno what to do with %".format(name).postln;
				}
			}
		}
	});

	~glassHits.do(
		_.do({
			|sound|
			sound[\buffer] = Buffer.read(s, sound[\path]);
			~resources.add(sound[\buffer]);
		})
	);

	~glassHums.do({
		|sound|
		sound[\buffer] = Buffer.read(s, sound[\path]);
		~resources.add(sound[\buffer]);
	});

	Log(\gliz, "Loaded % hums and % hits".format(~glassHums.size, ~glassHits.size));

});

