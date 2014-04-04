WindowViewRecall {
	*autoRememberPosition {
		| that ...addr |

		var func = {
			that.rememberPosition(*addr);
		};

		that.toFrontAction = that.toFrontAction.addFunc(func);
		that.endFrontAction = that.endFrontAction.addFunc(func);
	}

	*rememberPosition {
		| that ...addr |
		var bounds = that.bounds;
		if (bounds.notNil) {
			Archive.global.put(*([\WindowPositions] ++ addr ++ [ that.bounds ]));
		}
	}

	*recallPosition {
		| that ...addr |
		var bounds = Archive.global.at(*([\WindowPositions] ++ addr));
		if (bounds.notNil) {
			that.bounds = bounds;
		}
	}

	*resetWindowPositions {
		| that ...addrs |
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

+ Window {
	autoRememberPosition {
		| ...addr |
		WindowViewRecall.autoRememberPosition(this, *addr);
	}

	rememberPosition {
		| ...addr |
		if (this.isClosed.not) {
			WindowViewRecall.rememberPosition(this, *addr);
		}
	}

	recallPosition {
		| ...addr |
		WindowViewRecall.recallPosition(this, *addr);
	}

	resetWindowPositions {
		| ...addrs |
		WindowViewRecall.resetWindowPositions(this, *addrs);
	}
}

+ View {
	autoRememberPosition {
		| ...addr |
		WindowViewRecall.autoRememberPosition(this, *addr);
	}

	rememberPosition {
		| ...addr |
		WindowViewRecall.rememberPosition(this, *addr);
	}

	recallPosition {
		| ...addr |
		WindowViewRecall.recallPosition(this, *addr);
	}

	resetWindowPositions {
		| ...addrs |
		WindowViewRecall.resetWindowPositions(this, *addrs);
	}
}