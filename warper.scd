~sound = SoundFile.openRead("/Users/fsc/Desktop/SET EM BR/sounds/HumA2_45-mono.wav");
~soundData = FloatArray.fill(~sound.numFrames, 0);
~sound.readData(~soundData);
~transformedData = FloatArray.fill(~sound.numFrames, -1);

~plotter = Plotter("asdf", Rect(300,300,400,400));

~timewarp = {
	| data, center=0 |
	var size = data.size;
	data.collect({
		| v, t |
		var newT;
		t = t / size * 2 - 1;
		newT = (t + (center.neg * sin((t + 1.0) * (pi / 2.0)))).pow(1);
		newT = newT + 1 / 2 * size;
		data.blendAt(newT);
	});
};

~linearize = {
	| data, amount |
	var a, b;
	a = data.first;
	b = data.last;
	data.collect({
		| v, t |
		t = t / data.size();
		(amount * (a + ((b - a) * t))) +
		((1 - amount) * v)
	});
};

~transform = {
	| data |
	data = ~sinify.(data, 0.4, 3);
	data = ~timewarp.(data, -0.4);
	data = ~linearize.(data, 0.4);
	data;
};

~sinify = {
	| data, amount=0.05, freq=1 |
	var a, b, low, high;
	a = data.first;
	b = data.last;
	low = a;
	high = b;
	data = (data - low) / (high - low) * 2 - 1;

	data = data.collect({
		| v, t |
		t = t / data.size() * 2 - 1;
		v + (amount * sin((1 + (freq * 4)) * v * pi / 2)) / (1 + amount);
	});

	data = data + 1 / 2 * (high - low) + low;
};

~splitter = (
	plotter: ~plotter,
	minTime: 100,
	segments: List(),
	lastSegmentT: 0,
	lastSegmentV: 0,
	lastValue: 0,
	lastSlope: 0,
	lastTime: 0,
	split: {
		| time, value, data |
		var newSegment, slope = value - ~lastValue;
		if ((slope * ~lastSlope).isNegative && (~lastTime > ~minTime)) {
			"segment found at %".format(time).postln;
			~segments.add(newSegment = [~lastSegmentT, time]);
			//~plotter.value = data[~lastSegmentT..time];
			~lastSegmentT = time;
			~lastSegmentV = value;
			0.yield;
		};
		~lastSlope = slope;
		~lastValue = value;
		~lastTime = time;

		newSegment;
	}
);

fork({
	~soundData[0..500000].do({
		| value, time |
		var transformed, segment, data = ~soundData;
		~splitter.use({ segment = ~split.(time, value, data) });
		if (segment.notNil) {
			"Segment: % - %".format(*segment).postln;
			transformed = ~transform.(data[segment[0]..(segment[1] - 1)]);
			transformed.do({
				| v, i |
				~transformedData[segment[0] + i] = v;
				"% + %: %".format(segment[0], i, v).postln;
			});
			if ((time % 20) == 0) {
				~plotter.value = transformed;
			};
		}
	});
	~out = SoundFile().numChannels_(1);
	~out.openWrite("/Users/fsc/Desktop/SET EM BR/sounds/HumA2_45-mono-out.aiff");
	~out.writeData(FloatArray.newFrom(~transformedData));
	~out.close();
}, AppClock);

