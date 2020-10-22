clear
nitrousFluidTable = getNitrousFluidTable(); %Nitrous fluid properties for two phase flow model
PAmbient = 101325; %Pa
nitrousTankVolume = 0.8*(0.25*pi*(150e-3).^2); %m^3
injectorSingleHoleA = 0.25*pi*(1.5e-3)^2; %m^2
feedSystemStartPressure = 64e5;
nominalFeedSysPipeDiam = 7e-3;
tankInletA = 0.25*pi*(11e-2)^2;%m^2; Area used after injector for modelled reservoir (Shouldn't matter)
nominalFeedSysPipeCrossSection = 0.25*pi*(nominalFeedSysPipeDiam)^2;

%Combustion chamber properties
combutionChamber.OFRatioInitial = 6.5;
combutionChamber.mdotOxInitial = 0.3; %kg/s
combutionChamber.rhoFuel = 953; %kg/m^3
combutionChamber.combustionEfficiency = 0.95;
combutionChamber.PChamberInit = 30e5;
combutionChamber.portLength = 0.5967; %m. "Lp" in SPAD
%Regression rate parameters, empirical
%using numbers from adam bakers excel file.
combutionChamber.regRateParams.a = 2.3600e-5;
combutionChamber.regRateParams.n = 0.6050;
combutionChamber.regRateParams.m = 0;
%Port configuration, circular
combutionChamber.initialPortDiameter = 0.0403; %m^2
combutionChamber.initialFuelWebThickness = 0.0098;

%Nozzle properties
nozzle.throatArea = 2.4575e-4; %m^2
nozzle.expansionRatio = 2.3325; %m^2
nozzle.thrustEfficiencyFactor = 0.85; %lambda