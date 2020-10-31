clear

%%
%Sim fluid data
%Combustion products data for thermochem (load once). 
%In global workspace so can be found by combustion products thermo block. 
%(Maybe there's a cleaner way to do this with masks??)
propepProps = load('+HybridMotor/propepinterp.mat');
sim.nitrousFluidTable = getNitrousFluidTable(); %Nitrous fluid properties for two phase flow model
sim.PAmbient = 101325; %Pa

%%
%Feed System properties
sim.runTank.volume = 0.8*(0.25*pi*(150e-3).^2); %m^3
sim.pipe.diameter = 7e-3; %m
sim.pipe.crossSection = 0.25*pi*(sim.pipe.diameter)^2; %m^2
sim.pipe.startPressure = 64e5; %Pa
sim.pipe.mdotOxInitial = 0.3; %kg/sec

sim.preInjectorPipe.diameter = 7e-3; %m

%%
%Injector properties
sim.injector.singleHoleA = 0.25*pi*(1.5e-3)^2; %m^2
sim.injector.postInjectorCrossSection = 0.25*pi*(11e-2)^2;%m^2; Area used after injector for modelled reservoir (Shouldn't matter)

%%
%Combustion chamber properties
sim.combustionChamber.OFRatioInitial = 6.5;
sim.combustionChamber.mdotOxInitial = sim.pipe.mdotOxInitial; %kg/s
sim.combustionChamber.rhoFuel = 953; %kg/m^3 (density)
sim.combustionChamber.combustionEfficiency = 0.95;
sim.combustionChamber.PChamberInit = 30e5;
sim.combustionChamber.portLength = 0.5967; %m. "Lp" in SPAD
%Regression rate parameters, empirical
%using numbers from adam bakers excel file.
sim.combustionChamber.regRateParams.a = 2.3600e-5;
sim.combustionChamber.regRateParams.n = 0.6050;
sim.combustionChamber.regRateParams.m = 0;
%Port configuration, circular
sim.combustionChamber.initialPortDiameter = 0.0403; %m (Grain inner diam)
sim.combustionChamber.initialFuelWebThickness = 0.0098; %m (Grain outer diam - inner diam)

%%
%Nozzle properties
sim.nozzle.throatArea = 2.4575e-4; %m^2
sim.nozzle.expansionRatio = 2.3325; %m^2
sim.nozzle.thrustEfficiencyFactor = 0.85; %lambda