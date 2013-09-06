
// Empty class, designed to init just after CVEvent
InitPostCV {
	*initClass {
		Class.initClassTree(CVEvent);

		CVEvent.synthEvent[\cvs] = #{
			currentEnvironment.selectKind(CV).asKeyValuePairs;
		}
	}
}

+ Event {
	cvSynth {
		this.parent = CVEvent.synthEvent;
	}
}

+ Collection {
	selectKind {
		| kind |
		^this.select(_.isKindOf(kind));
	}
}
