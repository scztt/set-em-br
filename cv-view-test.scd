
t = TabbedView2.newColorLabels();
t.add("untitled");
t.tabViews[0].layout_(VLayout(v = ScrollView()));
q = View();
q.layout = VLayout().spacing_([0, 0, 0, 0]);

~makeCVView =

currentEnvironment.keysValuesDo({
	|key, val|
	var hasContents = false, collView;

	if (val.isKindOf(CV)) {
		q.layout.insert(~makeCVView.(val, "~" ++ key.asString), index:0, stretch:2);
	} {
		if (val.isKindOf(Collection)) {
			hasContents = false;
			collView = View().layout_(VLayout(
				StaticText().string_("~" ++ key.asString).font_(Font("Helvetica", 14, true)).align_(\right)
			));
			collView.background = Color.grey(0.6, 0.2);

			val.do({
				|item, i|
				if (item.isKindOf(CV)) {
					hasContents = true;
					collView.layout.add(~makeCVView.(item, "[%]".format(i)), stretch:2);
				}
			});

			if (hasContents) {
				q.layout.add(collView);
			};
		}
	}
});
v.canvas = q;
