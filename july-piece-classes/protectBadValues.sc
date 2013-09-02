+UGen {
	protectBadValues {
		arg ugen;
		var ugens, finalizedUgens, newUgens, removeUgens, finished = false, i = 0, ugenBlewUp, sendReply;
		ugens = IdentitySet();
		finalizedUgens = IdentitySet();
		ugens.add(ugen);
		"initial ugen: %".format(ugen).postln;

		while {finished.not && (i < 100)} {
			finished = true;
			newUgens = List();
			removeUgens = List();
			ugens.do({
				|u|
				case
				{ u.isKindOf(Array) } {
					removeUgens.add(u);
					newUgens.addAll(u);
					finished = false;
				}
				{ u.isKindOf(OutputProxy) } {
					removeUgens.add(u);
					newUgens.add(u.source);
					finished = false;
				}
				{ u.isKindOf(BasicOpUGen) || u.isKindOf(MulAdd) || u.isKindOf(Sum3) || u.isKindOf(Sum4) } {
					removeUgens.add(u);
					newUgens.addAll(u.inputs);
					finished = false;
				}
				{ u.isNumber() } {
					removeUgens.add(u);
					finished = false;
				}
				{ u.isKindOf(UGen) } {
					removeUgens.add(u);
					newUgens.addAll(u.inputs);
					finalizedUgens.add(u);
					finished = false;
				};
			});
			"new ugens: %".format(newUgens).postln;
			"removed ugens: %".format(removeUgens).postln;
			ugens.removeAll(removeUgens);
			ugens.addAll(newUgens);
			i = i + 1;
			"ugens list[%]: %".format(ugens.size, ugens).postln;
		};
		"\n\n\n".postln;
		"finalized ugens [%]: %".format(finalizedUgens.size, finalizedUgens).postln;
		finalizedUgens.do({
			|u|
			"%.%: %, %".format(u.class, u.rate, u.synthIndex, u.specialIndex);
		});
		finalizedUgens = finalizedUgens.asArray.sort({ |a, b| a.synthIndex >= b.synthIndex });
		ugenBlewUp = CheckBadValues.ar(ugen);
		sendReply = PulseCount.ar(ugenBlewUp) > 0;

		SendReply.ar(sendReply, '/synthstate', [-1] ++ UGen.buildSynthDef.controls);
		finalizedUgens.do({
			|u|
			SendReply.ar(sendReply, '/synthstate', [u.class.classIndex, u.synthIndex, u] ++ u.inputs);
		});

		OSCdef(\ugenstate, {
			|msg|
			var node, ugen, ugenIndex, value, inputs, isInvalid;
			isInvalid = {
				|value|
				((value == inf) || (value == -inf) || value.isNaN);
			};
			node = msg[1];
			ugen = msg[3];
			if (ugen == -1) {
				"Controls for node %: (%)".format(node, msg[3..]).postln;
			} {
				ugen = Class.allClasses.detect({ |c| c.classIndex == ugen }).name;
				ugenIndex = msg[4];
				value = msg[5];
				inputs = msg[6..];

				if (isInvalid.(value)) {
					if (inputs.detect({ |v| isInvalid.(v) }).isNil) {
						"******".post;
					};
					"Ugen State for node %: %[%] = % (%)".format(node, ugen, ugenIndex, value, inputs.join(",")).postln;
				}
			}
		}, '/synthstate');
	}
}