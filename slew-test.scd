w = Window().front().layout_(VLayout());

~cvs = [
	CV(),
	CV(),
	CV(),
	CV(),
	CV(),
];

~knobs = List();

~cvs.do({
	|cv|
	var k;
	~knobs.add(k = Knob().mode_(\horiz));
	cv.connect(k);
	w.layout.add(k);
});

b = Button();
w.layout.add(b);

({
	~slewMap = IdentityDictionary();

	~slew = {
		|cv, target, dur = 5, delta, updateRate = 30|
		var recoverTime = 0.4, steps,
		slewRoutine, recoverRoutine, ended = false,
		startTime, endTime, curTime, slewChanging = false, externalTouch;

		if (dur.notNil and: { (dur < 0.0001) || ( dur > 10000) || ((cv.value - target).abs < 0.001) }) {
			cv.value = target;
		} {
			if (~slewMap[cv].notNil) {
				~slewMap[cv].stop();
				~slewMap[cv] = nil;
			};

			if (delta.notNil) {
				if ((target - cv.value).sign != delta.sign) {
					delta = delta.neg;
				};

				steps = (target - cv.value) / delta;
				dur = steps * (updateRate.reciprocal);
			} {
				steps = (dur * updateRate).floor;
				delta = (target - cv.value) / steps.asFloat;
			};

			startTime = AppClock.seconds;
			endTime = startTime + dur;
			curTime = startTime;

			externalTouch = SimpleController(cv).put(\synch, {
				var newSteps, newDur;
				if (slewChanging.not) {
					~slewMap[cv].stop();
					~slewMap[cv] = nil;

					externalTouch.remove();

					newSteps = ((target - cv.value) / delta);
					newDur = newSteps / updateRate;
					recoverRoutine.defer(
						cv,
						target,
						nil,
						delta,
						updateRate
					);
				}
			});

			recoverRoutine = Collapse(~slew, recoverTime, AppClock);
			slewRoutine = Routine({
				while({ steps > 0 }, {
					steps = steps - 1;
					slewChanging = true;
					cv.value = cv.value + delta;
					slewChanging = false;

					waitUntil(curTime + updateRate.reciprocal);
					curTime = AppClock.seconds;
				});

				if (cv.value != target) {
					slewChanging = true;
					cv.value = target;
					slewChanging = false;
				};

				externalTouch.remove();

				~slewMap[cv] = nil;
			});
			~slewMap[cv] = slewRoutine;
			slewRoutine.play(AppClock);
		};
	};

	~cvs.do({
		|cv|
		~slew.(cv, 0.5, 7);
	});
})