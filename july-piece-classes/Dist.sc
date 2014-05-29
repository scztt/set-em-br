DistCurve : Singleton {
	var <>server, <descriptions, <buffers, <size=512, <mirror = false, synced = false, log;

	init {
		server = Server.default;
		server.onBootAdd(this);
		server.onQuitAdd(this);
		buffers = List();
		log = Log(\DistCurve);
	}

	set {
		arg ...inDescriptions;
		descriptions = inDescriptions;
		log.debug("Setting: %", descriptions);
		log.debug("Current buffers: %", buffers);
		this.updateBuffers();
	}

	doOnServerBoot {
		if (buffers.size() > 0) {
			log.error("Uncleared buffers detected on server boot! These are invalid - why are they here?");
			this.clearBuffers();
		};

		this.updateBuffers();
	}

	doOnServerQuit {
		synced = false;
		this.clearBuffers();
	}

	clearBuffers {
		if (server.serverRunning) {
			buffers.do {
				| buf |
				buf.free;
			}
		};
		buffers = List();
	}

	size_{
		arg inSize;
		size = inSize;
		this.clearBuffers();
		this.updateBuffers();
	}

	mirror_{
		arg inMirror;
		mirror = inMirror;
		this.updateBuffers();
	}

	numBuffers_{
		arg num;
		var sizeDiff = buffers.size() - num;

		if (sizeDiff > 0) {
			log.debug("Removing % unused buffers ([%..]).", sizeDiff, num);
			buffers[num..].do(_.free);
			buffers = buffers[0..(num - 1)];
		};

		if (sizeDiff < 0) {
			log.debug("Preparing to allocate % new buffers.", sizeDiff.neg);
			sizeDiff.neg.do {
				buffers.add(nil);
			}
		};
	}

	updateBuffers {
		if (server.serverRunning) {
			var buf, unusedBuffers;
			synced = false;

			this.numBuffers = descriptions.size;
			descriptions.do {
				| desc, i |
				if (buffers[i].notNil) {
					buffers[i].sendCollection(this.toWavetable(desc));
					log.debug("Refilled buffer % with %", buffers[i]);
				} {
					buffers[i] = Buffer.sendCollection(server, this.toWavetable(desc));
					log.debug("Created new buffer %", buffers[i]);
				}
			};

			// Set the flag when the server has finished processing messages.
			fork {
				server.sync();
				synced = true;
			};
		}
	}

	plot {
		this.asArrays.plot();
	}

	asWavetables {
		^descriptions.collect(this.toWavetable(_, size));
	}

	asArrays {
		^descriptions.collect(this.toArray(_, size));
	}

	ar {
		arg in, position, pre, post;
		position = position ?? { DC.kr(0) };

		if (synced.not) { "Buffers have not yet been synced to the server! You can't call ar yet.".throw };

		if (descriptions.size > 1) {
			^this.xfadeAr(in, position, pre, post);
		} {
			^this.buildShaper(buffers[0], in, pre, post);
		}
	}

	xfadeAr {
		arg in, position, pre, post;
		var sigs = descriptions.collect({
			| desc, i |
			this.buildShaper(buffers[i], in, pre, post);
		});

		^LinSelectX.ar(position * (sigs.size - 1), sigs, wrap:0);
	}

	buildShaper {
		arg buffer, in, pre, post;
		var sig;
		sig = in;
		if (pre.notNil) { sig = sig * pre.dbamp };
		sig = Shaper.ar(buffer.bufnum, sig);
		if (post.notNil) { sig = sig * post.dbamp };
		^sig;
	}

	toWavetable {
		arg desc, size;
		^Signal.newFrom(this.toArray(desc, size)).asWavetableNoWrap;
	}

	toArray {
		arg desc;
		var data, targetSize;

		if (mirror) {
			targetSize = (size / 2).asInteger;
		} {
			targetSize = size + 1
		};

		if (desc.class == Function) 						{ data = this.toWavetableFunction(desc, targetSize) };
		if (desc.class == Env) 								{ data = this.toWavetableEnv(desc, targetSize) };
		if (desc.isKindOf(Collection) && (desc.size >= 2)) 	{ data = this.toWavetableCollection(desc, targetSize) };

		if (mirror) {
			data = (0 - data.reverse) ++ [0] ++ data
		};
		^data;
	}

	toWavetableFunction {
		arg desc, size;
		^size.collect({
			|n|
			desc.value(n / size * 2 - 1);
		});
	}

	toWavetableEnv {
		arg desc, size;
		desc = desc.deepCopy();
		desc.duration = size;
		^size.collect(desc.at(_));
	}

	toWavetableCollection {
		arg desc, size;
		^desc.resamp1(size);
	}

	onClear {
		this.clearBuffers();
		descriptions = [];
	}
}