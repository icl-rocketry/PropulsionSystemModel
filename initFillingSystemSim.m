
dataLoaded = load('+NitrousFluidProps/NitrousFluidTablesExtended.mat');
nitrousFluidTable = dataLoaded.nitrousFluidTable;

sim.extTank.volume = 1*0.25*pi*(20e-2).^2; %volume of external tank m^3
sim.extTank.pressure = 50*10^5; %pressure of external tank Pa
sim.fillpipe.diameter = 7e-3; %pipe connecting to external tank m
sim.fillpipe.crossSection = 0.25*pi*(sim.fillpipe.diameter)^2; %m^2

sim.Heater.SA = 1; %SA of heater surrounding tank
sim.Heater.temp = 293; %initialises heater at room temperature
sim.Heater.weight = 0.1; %weight of heater. Very unsure as to the effect of this

sim.fillValve.max = 0.005; %maximum opening of valve m^2