+ QView {
	autoRememberPosition {
		| ...addr |

		var func = {
			this.rememberPosition(*addr);
		};

		this.toFrontAction = this.toFrontAction.addFunc(func);
		this.endFrontAction = this.endFrontAction.addFunc(func);
	}

	rememberPosition {
		| ...addr |
		var bounds = this.bounds;
		if (bounds.notNil) {
			Archive.global.put(*([\WindowPositions] ++ addr ++ [ this.bounds ]));
		}
	}

	recallPosition {
		| ...addr |
		var bounds = Archive.global.at(*([\WindowPositions] ++ addr));
		if (bounds.notNil) {
			this.bounds = bounds;
		}
	}

	resetWindowPositions {
		| ...addrs |
		if (addrs.isEmpty) {
			Archive.global.put(\WindowPositions, nil);
		} {
			addrs.do({
				| addr |
				Archive.global.put(*([\WindowPositions] ++ addr ++ [nil]));
			});
		};
		Archive.write();
	}
}