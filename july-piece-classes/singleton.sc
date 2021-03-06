Singleton {
	classvar <>all, <>know=false, creatingNew=false;

	var <>name;

	*initClass {
		all = IdentityDictionary();
	}

	*new {
		arg name = \default ...settings;
		var sing, classAll;

		classAll = all.atFail(this, {
			all[this] = IdentityDictionary();
			all[this];
		});

		sing = classAll.atFail(name, {
			var newSingleton = this.createNew();
			newSingleton.init(name);
			newSingleton.name = name;
			classAll[name] = newSingleton;
			newSingleton;
		});

		if (settings.notNil && settings.notEmpty) { sing.set(*settings) };
		^sing;
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
				};
				item = this.new(selector, *args);
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

MockSingleton : Singleton {
	var <settings;
	set {
		arg ...inSettings;
		settings = inSettings;
	}
}

TestSingleton : UnitTest {

	test_default {
		var a, b;
		a = Singleton();
		b = Singleton(\default);
		this.assertEquals(a, b);
	}

	test_settigs {
		var settings = [\a, 1, "2",  [3, 3, 3]];
		MockSingleton(\test, *settings);
		this.assertEquals(settings, MockSingleton(\test).settings)
	}

	test_know {
		MockSingleton.know = true;
		MockSingleton.foo = \argument;
		this.assertEquals(MockSingleton.foo.settings, [\argument]);
		MockSingleton.know = false;
	}

}