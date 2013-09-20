MultiStateManager : Singleton {
	var <states, <currentState;

	init {
	}

	switch {
		arg state ...args;
		if (currentState != state) {
			if (currentState.notNil) {
				currentState.doStop(*args);
			};
			currentState = nil;

			if (state.notNil) {
				state.doStart(*args);
			};
			currentState = state;
		}
	}
}

State : Singleton {
	var <initialized=false, <running = false, <>requireServer = true;
	var <>server, <initActions, <startActions, <stopActions, <freeActions, <resources;
	var <envir, <name;

	init {
		arg inName;
		server = Server.default;
		ServerTree.add(this, server);
		ServerQuit.add(this, server);
		CmdPeriod.add(this);

		initActions = SparseArray();
		startActions = SparseArray();
		stopActions = SparseArray();
		freeActions = SparseArray();
		resources = SparseArray();

		envir = Environment();
		name = inName;
		envir[\name] = name;
		envir[\resources] = resources;

		this.clear();
	}

	onError {
		|e|
		"%: Error running action %.".format(e, this.name()).error;
		e.reportError;
	}

	*add {
		|...args|
		args.postln;
	}

	at {
		arg selector;
		^envir.at(selector);
	}

	put {
		arg key, value;
		^envir.put(key, value);
	}

	clear {
		this.doStop();
		this.doFree();

		initActions.clear(8);
		startActions.clear(8);
		stopActions.clear(8);
		freeActions.clear(8);
		resources.clear(8);

		envir.clear();
		envir[\name] = name;
	}

	push {
		envir.push();
	}

	pop {
		envir.pop();
	}

	use {
		arg func;
		envir.use(func);
	}

	log {
		arg str;
		"%: %".format(envir[\name].asString.toUpper, str).postln;
	}

	doInit {
		arg ...args;

		if (initialized.not && (server.serverRunning || requireServer.not)) {
			initActions.do({
				arg action;
				try {
					envir.use({
						action.value(*args)
					});
				} {
					|e|
					this.onError(e)
				};
			});

			initialized = true;
			envir.use({ this.changed(\initialized, true) });
			this.log("initialized");
		};
	}

	doStart {
		arg ...args;
		if (initialized.not) {
			"State not initialized.".warn;
		} {
			if (running) {
				"State already started.".warn;
			} {
				startActions.do({
					arg action;
					try {
						envir.use({
							action.value(*args)
						});
					} {
						|e|
						this.onError(e)
					};
				});
				running = true;
				envir.use({ this.changed(\running, true) });
				this.log("started");
			} ;
		};
	}

	doStop {
		arg ...args;
		if (running) {
			stopActions.do({
				arg action;
				try {
					envir.use({
						action.value(*args)
					});
				} {
					|e|
					this.onError(e)
				};
			});
			running = false;
			envir.use({ this.changed(\running, false) });
			this.log("stopped");
		} {
			"State not running.".warn;
		};
	}

	doFree {
		arg ...args;

		if (running) {
			this.doStop();
		};

		if (initialized) {
			freeActions.do({
				arg action;
				try {
					envir.use({
						action.value(*args)
					});
				} {
					|e|
					this.onError(e)
				};
			});

			envir[\resources].do({
				arg resource;
				this.freeResource(resource);
			});

			envir.use({ this.changed(\initialized, false) });
			initialized = false;
			this.log("freed");
		}
	}

	doOnServerTree {
		arg inServer;
		if (inServer == server) {
			this.doInit();
		}
	}

	doOnServerQuit {
		arg inServer;
		if (inServer == server) {
			this.doFree();
		}
	}

	cmdPeriod {
		this.doStop();
		this.doFree();
	}

	freeResource {
		arg resource;

		case
		{ resource.isKindOf(Buffer) } {
			resource.free;
		}

		{ resource.isKindOf(Bus) } {
			resource.free;
		}

		{ resource.isKindOf(Node) } {
			resource.free;
		}

		{ resource.isKindOf(CV) } {
			resource.releaseDependants;
		}

		{ resource.isKindOf(CVGroup) } {
			resource.do(this.free());
		}

		{ resource.isKindOf(SimpleController) } {
			resource.remove();
		}

		{ resource.isKindOf(Collection) } {
			resource.do(this.freeResource(_));
		}
	}

	printOn {
		arg stream;
		stream << "State(\\" << name << ") [initialized:" << initialized << ", running:" << running << ")";
	}
}