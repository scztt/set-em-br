// Pcv : FilterPattern {
// 	var <>cv;
// 	*new { arg cv;
// 		^super.new(pattern).cv_(cv)
// 	}
//
// 	embedInStream { arg inevent;
// 		var cleanup, currentValue, server;
// 		cleanup = EventStreamCleanup.new;
// 		currentValue = cv.value;
// 		server = inevent[\server] ?? { Server.default };
// 		"inevent.id: %".format(inevent[\id]).postln;
// 		Event
// 	}
//
// 	*embedLoop { arg inevent, stream, groupID, ingroup, cleanup;
// 		var event, lag;
// 		loop {
// 			event = stream.next(inevent) ?? { ^cleanup.exit(inevent) };
// 			lag = event[\dur];
// 			inevent = event.yield;
// 			inevent.put(\group, groupID);
// 		}
// 	}
// }
