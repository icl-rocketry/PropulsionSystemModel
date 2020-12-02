
dataLoaded = load('+NitrousFluidProps/NitrousFluidTablesExtended.mat');
nitrousFluidTable = dataLoaded.nitrousFluidTable;

Sim.extTank.volume = 1*0.25*pi*(20e-2).^2; %volume of external tank m^3
Sim.extTank.pressure = 30*10^5; %pressure of external tank Pa

Sim.fillpipe.diameter = 7e-3; %pipe connecting to external tank m
Sim.fillpipe.crossSection = 0.25*pi*(Sim.fillpipe.diameter)^2; %m^2
Sim.fillpipe.roughness = 0.0015*10^(-3); %absolute roughness of PVC pipe

Sim.Heater.SA = 1; %SA of heater surrounding tank
Sim.Heater.temp = 293; %initialises heater at room temperature
Sim.Heater.weight = 0.1; %weight of heater. Very unsure as to the effect of this

Sim.fillValve.max = 0.005; %maximum opening of valve m^2