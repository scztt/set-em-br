Server.default = s = Server.local;
Server.default.options.device = "MOTU UltraLite mk3 Hybrid";
Server.default.options.numOutputBusChannels = 16;
Server.default.options.numInputBusChannels = 16;
s.options.sampleRate = 48000;

fork {
	s.quit();
	1.wait;
	s.waitForBoot({
		s.scope(4, 0);
		s.plotTree;
	});
}