clear

dataLoaded = load('+NitrousFluidProps/NitrousFluidTables.mat'); % Extended
Sim.nitrousFluidTable = dataLoaded.nitrousFluidTable;%getNitrousFluidTable(); 
Sim.extraNitrousPropsTable = getExtraNitrousFluidTable();

Sim.PAmbient = 101325; %Pa

Sim.runTank.volume = 0.8*(0.25*pi*(150e-3).^2); % m^3
Sim.runTank.PInit = 1e5; % Pascal. Very temperature dependent. Eg. 0C->31bar, 20C->50bar, 30C->63bar    

Sim.extTank.volume = 1*0.25*pi*(20e-2).^2; % volume of external tank m^3
Sim.extTank.pressure = 50e5; % pressure of external tank Pa. function takes values in deg C & assumes in v-L equilibrium

Sim.fillpipe.diameter = 7e-3; % pipe connecting to external tank m
Sim.fillpipe.crossSection = 0.25*pi*(Sim.fillpipe.diameter)^2; % m^2; ~ 3.85e-5 
Sim.fillpipe.roughness = 0.0015*10^(-3); % absolute roughness of PVC pipe

Sim.controlValve.diameter = Sim.fillpipe.diameter; % maximum diameter of local restriction m
Sim.controlValve.crossSection = 0.25*pi*(Sim.controlValve.diameter)^2; % maximum area of local restriction m^2

Sim.Heater.SA = 1; % SA of heater surrounding tank
Sim.Heater.temp = 293; % initialises heater at room temperature
Sim.Heater.weight = 0.1; % weight of heater. Very unsure as to the effect of this
