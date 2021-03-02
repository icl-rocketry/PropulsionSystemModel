uMin = -3.45; %kJ/kg
uMax = 450; %kJ/kg
%BE CAREFUL generating below triple point
pMin = 0.09; %0.1*0.09; %MPa
pMax = 10; %Mpa
numRowsLiquidPhase = 60;
numRowsVapourPhase = 60;
numPressureVals = 80;

nitrousFluidTable = NitrousFluidProps.twoPhaseFluidTablesCustom(...
    [uMin,uMax],[pMin,pMax],...
    numRowsLiquidPhase,numRowsVapourPhase,numPressureVals,...
'NitrousOxide','py.CoolProp.CoolProp.PropsSI');
save('+NitrousFluidProps/NitrousFluidTables.mat', 'nitrousFluidTable');
disp("Generated!");