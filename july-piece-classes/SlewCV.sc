SlewCV {
	classvar <slewMap,
	<>updateRate = 30,
	<>recoverTime = 0.4;

	var <cv, <>target, <>dur, <>updateRate,
	<>recoverTime,
	routine, externalTouch, recoverRoutine, slewChanging = false, delta;

	*initClass {
		slewMap = IdentityDictionary();
	}

	*new {
		arg cv, target, dur, updateRate;
		^super.newCopyArgs(cv, target, dur, updateRate).init();
	}

	init {
		updateRate = updateRate ? this.class.updateRate;
		recoverTime = recoverTime ? this.class.recoverTime;
	}

	play {
		if (slewMap[cv].notNil) {
			slewMap[cv].remove();
		};

		delta = (target - cv.value) / (dur * updateRate).floor;
		slewMap[cv] = this;
		this.scheduleSlew();
	}

	stop {
		routine.stop();
	}

	remove {
		externalTouch.notNil.if({ externalTouch.remove() });
		externalTouch = nil;

		recoverRoutine.notNil.if({ recoverRoutine.cancel() });
		recoverRoutine = nil;

		if (slewMap[cv] == this) {
			slewMap[cv].stop();
			slewMap[cv] = nil;
		}
	}

	scheduleSlew {
		arg initialValue;
		var steps, curTime, cvValue;

		cvValue = initialValue ? cv.value;

		if ((target - cvValue).sign != delta.sign) {
			delta = delta.neg;
		};

		if ( ((cvValue - target).abs < 0.0001)) {
			cv.value = target;
		} {
			steps = (target - cvValue) / delta;
			if (steps < 1) {
				cv.value = target;
			} {
				curTime = AppClock.seconds;

				recoverRoutine = Collapse({ this.scheduleSlew(initialValue) }, recoverTime, AppClock);
				externalTouch = SimpleController(cv).put(\synch, {
					if (slewChanging.not) {
						routine.stop();
						routine = nil;

						externalTouch.remove();
						externalTouch = nil;

						recoverRoutine.defer();
						recoverRoutine = nil;
					}
				});

				if (routine.notNil) {
					"Routine was not nil while starting a new routine!".warn;
					routine.stop();
					routine = nil;
				};
				routine = Routine({
					while({ steps > 0 }, {
						steps = steps - 1;

						slewChanging = true;
						cvValue = cvValue + delta;
						cv.value = cvValue;
						slewChanging = false;

						waitUntil(curTime + updateRate.reciprocal);
						curTime = AppClock.seconds;
					});

					// One last set to ensure cv is perfectly correct.
					slewChanging = true;
					cv.value = target;
					slewChanging = false;

					this.remove();
				});

				routine.play(AppClock);
			}
		}
	}
}

+CV {
	slewTo {
		arg target, dur, updateRate = 15;

		SlewCV(this, target, dur, updateRate).play;
	}
}