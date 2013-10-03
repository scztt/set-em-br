Require {
	classvar requireTable;

	*initClass {
		requireTable = IdentityDictionary();
	}

	*reset {
		requireTable.clear();
	}

	*new {
		arg identifier, cmdPeriod = false, always = false;
		^this.require(identifier, cmdPeriod, always);
	}

	// A resolveRelative that always assumes the interpreter as parent.
	*resolveRelative {
		arg str;
		var path = thisProcess.nowExecutingPath;

		if (str[0] == thisProcess.platform.pathSeparator) {^str};
		if (path.isNil) { ^str }; // It's okay if path is nil, just always resolve absolutely.
		^(path.dirname +/+ str)
	}

	*require {
		arg identifier, cmdPeriod = false, always = false;
		var paths, absPath, results, caller;

		// First try absolute
		paths = identifier.pathMatch();

		// Then relative
		if (paths.isEmpty()) {
			paths = this.resolveRelative(identifier).pathMatch();
		};

		// Then relative with implicit ./
		if (paths.isEmpty() && identifier[0] != ".") {
			identifier = "." +/+ identifier;
			paths = (this.resolveRelative(identifier)).pathMatch();
		};

		// Then relative with implicit extension
		if (paths.isEmpty() && identifier.endsWith(".scd").not) {
			identifier = identifier ++ ".scd";
			paths = (this.resolveRelative(identifier)).pathMatch();
		};

		if (paths.isEmpty) {
			Exception("No files found for Require(%)! (executing from: %)".format(identifier, thisProcess.nowExecutingPath).warn);

		} {
			var results = paths.collect({
				|path|
				var result, oldPath;

				absPath = PathName(path).asAbsolutePath().asSymbol();
				if (requireTable[absPath].isNil || always) {
					oldPath = thisProcess.nowExecutingPath;
					thisProcess.nowExecutingPath = absPath;

					try {
						result = absPath.asString.load();
					} {
						|e|
						"Require of file % failed!".format(absPath).error;
						e.throw();
					};

					thisProcess.nowExecutingPath = oldPath;

					requireTable[absPath] = result;

					if (cmdPeriod) {
						CmdPeriod.doOnce({
							requireTable[absPath] = nil;
						})
					}
				} {
					result = requireTable[absPath];
				};

				result;
			});

			if (results.size == 1) {
				^results[0];
			} {
				^results;
			}
		};
	}
}