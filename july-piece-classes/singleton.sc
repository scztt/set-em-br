Singleton {
	classvar <>all, <>know=false, creatingNew=false;

	var logString, <postWindow, <>postActions;

	*initClass { all = IdentityDictionary(); }

	*new {
		arg name = \default ...settings;
		^all.atFail(name, {
			var newSingleton = this.createNew().init(name);
			if (settings.notNil, { newSingleton.set(*settings) });
			all[name] = newSingleton;
			newSingleton;
		});
	}

	*createNew {
		arg ...args;
		^super.new(*args);
	}

	*doesNotUnderstand { arg selector ... args;
		var item;

		if (know && creatingNew.not) {
			creatingNew = true;		// avoid reentrance
			try {
				if (selector.isSetter) {
					selector = selector.asString;
					selector = selector[0..(selector.size - 2)].asSymbol;
					item = this.new(selector, *args);
				} {
					item = this.new(selector);
				}
			};
			creatingNew = false;
			^item;
		} {
			^this.superPerformList(\doesNotUnderstand, selector, args);
		}
	}

	init {}

	set {
		// Override this to receive 'settings' parameter from Singleton.new(name, settings)
	}

}