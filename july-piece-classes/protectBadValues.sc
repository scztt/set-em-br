TraceBadValues {
	classvar <synthdefs;

	*initClass {
		synthdefs = IdentityDictionary();
	}

	*new {
		| ...ugens |
		this.traceUgens(ugens.flatten);
		^DC.ar(0);
	}

	*traceUgens {
		| inUgens |
		var ugens, finalizedUgens, newUgens, removeUgens, finished = false, i = 0, ugenBlewUp, sendReply, uniqueid, channelName, controlValuesList, ugensAr, ugensKr;
		uniqueid = inUgens.hash;

		ugens = IdentitySet();
		finalizedUgens = IdentitySet();
		ugens.addAll(inUgens);
		"initial ugens: %".format(ugens).postln;

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

			ugens.removeAll(removeUgens);
			ugens.addAll(newUgens);
			i = i + 1;

		};

		finalizedUgens = finalizedUgens.asArray.sort({ |a, b| a.synthIndex < b.synthIndex });
		"finalized ugens [%]: %".format(finalizedUgens.size, finalizedUgens).postln;
		ugensAr = inUgens.asArray.select({ |u| u.postln.rate == \audio });
		ugensKr = inUgens.asArray.select({ |u| u.postln.rate == \control });

		sendReply = 0;
		if (ugensAr.size > 0) {
			ugenBlewUp = CheckBadValues.ar(ugensAr);
			sendReply = PulseCount.ar(ugenBlewUp) > 0;
		};

		if (ugensKr.size > 0) {
			ugenBlewUp = CheckBadValues.kr(ugensKr);
			sendReply = sendReply + K2A.ar(PulseCount.kr(ugenBlewUp) > 0);
		};

		channelName = ("/synthstate_" ++ uniqueid).asSymbol;
		TraceBadValues.synthdefs[channelName] = UGen.buildSynthDef;

		controlValuesList = SparseArray();
		UGen.buildSynthDef.children.do({
			| child |
			if ([Control, AudioControl, TrigControl, LagControl].includes(child.class)) {
				child.channels.do({
					| chan, i |
					controlValuesList[child.specialIndex + i] = chan;
				})
			}
		});

		SendReply.ar(sendReply, channelName, [-1] ++ controlValuesList);

		finalizedUgens.do({
			|u|
			SendReply.ar(sendReply, channelName, [u.class.classIndex, u.synthIndex, (u.rate == \audio).if(1, 0), u] ++ u.inputs);
		});

		OSCdef(\ugenstate, {
			|msg|
			var name, node, ugen, ugenIndex, value, inputs, isInvalid, synthdef, argnames, argstring, rate, controlValues, controlNames;
			isInvalid = {
				|value|
				((value == inf) || (value == -inf) || value.isNaN);
			};

			name = msg[0];
			node = msg[1];
			ugen = msg[3];

			synthdef = TraceBadValues.synthdefs[name.asSymbol];

			if (ugen == -1) {
				controlNames = synthdef.allControlNames;
				controlValues = msg[4..];
				controlValues = controlValues.reshapeLike(controlNames.collect(_.defaultValue));
				"Controls for node %: (%)".format(
					node,
					controlValues.collect({
						|v, i|
						"%: %".format(controlNames[i].name, v);
					}).join(", ")
				).postln;

			} {
				ugen = Class.allClasses.detect({ |c| c.classIndex == ugen });
				argnames = ugen.class.findMethod('ar').argNames;
				if (argnames.isNil) { argnames = ugen.class.findMethod('kr').argNames };
				if (argnames.isNil) { argnames = ugen.class.findMethod('ir').argNames };
				if (argnames.isNil) { argnames = [] };
				argnames = argnames[1..];

				ugenIndex = msg[4];
				rate = (msg[5] == 1).if('ar', 'kr');
				value = msg[6];
				inputs = msg[7..];

				if (isInvalid.(value)) {
					if (inputs.detect({ |v| isInvalid.(v) }).isNil) {
						"******".post;
					};

					argstring = inputs.collect({
						| val, i |
						"%: %".format(argnames[i], val);
					}).join(", ");

					"Ugen State for node %, ugen %: %.%(%) == %".format(node, ugenIndex, ugen.name, rate, argstring, value).postln;
				}
			}
		}, channelName);
	}
}


