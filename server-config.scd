Server.default = s = Server.local;
Server.default.options.device = "MOTU UltraLite mk3 Hybrid";
Server.default.options.numOutputBusChannels = 16;
s.options.sampleRate = 48000;
s.reboot();

s.waitForBoot({
	s.scope(4, 0);
	s.plotTree ;
});