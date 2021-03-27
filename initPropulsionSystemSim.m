clear
applyReceiverAccumulatorPatch();
%initFillingSystemSim()
%%
%Sim fluid data
%Combustion products data for thermochem (load once). 
%In global workspace so can be found by combustion products thermo block. 
%(Maybe there's a cleaner way to do this with masks??)
%load('+HybridMotor/propepPropsKeraxN2O_modified.mat');
load('+HybridMotor/propepPropsKeraxN2O.mat');
Sim.nitrousFluidTable = getNitrousFluidTable(); %Nitrous fluid properties for two phase flow model
Sim.extraNitrousPropsTable = getExtraNitrousFluidTable();
Sim.PAmbient = 101325; %Pa

%%
%Feed System properties
Sim.phaseChangeTimeConstant = 0.01; %sec. Arbitrary value, please refine

Sim.runTank.volume = 0.013784;% m^3 (Source: Phil). 0.8*(0.25*pi*(150e-3).^2); %m^3
Sim.runTank.PInit = 60e5; %Pascal. Very temperature dependent. Eg. 0C->31bar, 20C->50bar, 30C->63bar
Sim.pipe.diameter = 7e-3; %m
Sim.pipe.crossSection = 0.25*pi*(Sim.pipe.diameter)^2; %m^2
Sim.pipe.startPressure = Sim.runTank.PInit; %Pa (40e5 or so for Pablo)
Sim.pipe.mdotOxInitial = 0.45; %kg/sec (0.05 or so for Pablo)

Sim.preInjectorPipe.diameter = 60e-3; %m
Sim.preInjectorPipe.crossSection = 0.25*pi*Sim.preInjectorPipe.diameter^2; %m^2

%%
%Injector properties
Sim.injector.injectorDepth = 5e-3; %m
%For mdot ~0.503kg/s @ 10 bar dP (OF 8, 30 bar chamber, Isp 180, 1kN)
% Sim.injector.singleHoleDiamPort1 = 1.5e-3; %m
% Sim.injector.singleHoleDiamPort2 = 1.5e-3; %m
% Sim.injector.numHolesPort1 = 7;
% Sim.injector.numHolesPort2 = 7;
% Sim.injector.singleHoleAPort1 = 0.25*pi*(Sim.injector.singleHoleDiamPort1)^2; %m^2
% Sim.injector.singleHoleAPort2 = 0.25*pi*(Sim.injector.singleHoleDiamPort2)^2; %m^2
%For mdot ~0.453kg/s (Actually ~0.467kg/s) @10 bar dP (OF 8, 30 bar chamber, Isp 200, 1kN)
Sim.injector.singleHoleDiamPort1 = 1.5e-3; %m
Sim.injector.singleHoleDiamPort2 = 1.5e-3; %m
Sim.injector.numHolesPort1 = 7;
Sim.injector.numHolesPort2 = 6;
Sim.injector.singleHoleAPort1 = 0.25*pi*(Sim.injector.singleHoleDiamPort1)^2; %m^2
Sim.injector.singleHoleAPort2 = 0.25*pi*(Sim.injector.singleHoleDiamPort2)^2; %m^2
Sim.injector.singleHoleA = Sim.injector.singleHoleAPort1; %Used for local restriction injector model (probably not the one selected)
Sim.injector.postInjectorCrossSection = 0.25*pi*(76e-2)^2;%m^2; Area used after injector for modelled reservoir
%Used for calculating velocity after the injector for oxidiser transport
%time lag
Sim.injector.totalArea = (Sim.injector.singleHoleAPort1.*Sim.injector.numHolesPort1 + Sim.injector.singleHoleAPort2.*Sim.injector.numHolesPort2);
%Ideally empirically determined. Using an arbitrary scaling for now to give
%right order of magnitude oxidiser delay time
Sim.injector.effectiveExitArea = 5.*Sim.injector.totalArea;

%%
%Combustion chamber properties
Sim.combustionChamber.preCombustionChamberLength = 38e-3; %m
Sim.combustionChamber.OFRatioInitial = 6.5;
Sim.combustionChamber.mdotOxInitial = Sim.pipe.mdotOxInitial; %kg/s
Sim.combustionChamber.rhoFuel = 993.825; %kg/m^3 (density)
Sim.combustionChamber.combustionEfficiency = 0.9744; %Scaled applied to c*, RPA default value
Sim.combustionChamber.PChamberInit = 15e5;
Sim.combustionChamber.artificalPChamberMax = 60e5; %Up to 60e5 is max we have data for;
Sim.combustionChamber.portLength = 120e-3;%130e-3; %m. "Lp" in SPAD
%Regression rate parameters, empirical
Sim.combustionChamber.useOxFluxRegRateEquation = 1; %If 1 then uses rdot=a*Gox^n, if 0 then uses rdot=a*Gprop^n*length^m
%McCormick et all 2005 for FR5560
%(https://core.ac.uk/download/pdf/304374863.pdf)
% Sim.combustionChamber.regRateParams.a = 0.155e-3;
% Sim.combustionChamber.regRateParams.n = 0.5;
% Sim.combustionChamber.regRateParams.m = NaN; %Unused

%From fitting very approximately to results from Shani model (Implementing
%Shani model would be much better)
%https://drive.google.com/file/d/1nFCp3qxr5mZa92okDZEKBcNdREDE7amt/view
Sim.combustionChamber.regRateParams.a = 0.00016572;
Sim.combustionChamber.regRateParams.n = 0.53253;
Sim.combustionChamber.regRateParams.m = NaN; %Unused

%Numbers from adam bakers excel file for rdot=a*Gprop^n*length^m
% Sim.combustionChamber.regRateParams.a = 2.3600e-5;
% Sim.combustionChamber.regRateParams.n = 0.6050;
% Sim.combustionChamber.regRateParams.m = 0;
%Port configuration, circular
%Values for potentially possible pablo
Sim.combustionChamber.initialPortDiameter = 26e-3; %m (Grain inner diam)
grainOuterDiam = 76e-3;%63.5e-3; %m
Sim.combustionChamber.initialFuelWebThickness = grainOuterDiam-Sim.combustionChamber.initialPortDiameter; %m (Grain outer diam - inner diam)

%%
%Nozzle properties
Sim.nozzle.throatArea = 2.4575e-4; %m^2 (4.07e-5 for Pablo)
Sim.nozzle.expansionRatio = 5.15;%2592; % (2.6 for Pablo) <-- design point gamma = 1.1484 at P = 30bar and OF = 8

%Applied as a direct scaling to thrust calculated (Includes effect of divergence, extra real gas effects, non ideal expansion, friction, etc...):
Sim.nozzle.thrustEfficiencyFactor = 0.9; %This value may be too low (conservative), check Isp predictions against other data

%RPA predicts N2O and C34H70 (Paraffin kerawax we think) Isp of ~220 with
%default efficiencies and truncated ideal bell nozzle, ~230 ideal. 
%Using the below thrust efficiency factor approx matches this at the time
%of writing
%Sim.nozzle.thrustEfficiencyFactor = 0.97;