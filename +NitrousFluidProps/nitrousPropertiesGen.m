%After generating this script check the values for vapor thermal
%conductivity and prandtl number at the edge of the grid for negative
%values (Usually like 1 or 2 data points) and replace manually them if found 
%or else MATLAB will refuse to work
%with the generated fluid properties. (The limitiation of using a regular
%grid...)

uMin = -3.45; %kJ/kg
uMax = 443;%450; %kJ/kg
%BE CAREFUL generating below triple point
pMin = 0.09; %0.1*0.09; %MPa
pMax = 10; %Mpa
numRowsLiquidPhase = 190;
numRowsVapourPhase = 190;
numPressureVals = 200;

nitrousFluidTable = NitrousFluidProps.twoPhaseFluidTablesCustom(...
    [uMin,uMax],[pMin,pMax],...
    numRowsLiquidPhase,numRowsVapourPhase,numPressureVals,...
'NitrousOxide','py.CoolProp.CoolProp.PropsSI');
%%
% save('+NitrousFluidProps/NitrousFluidTables.mat', 'nitrousFluidTable');
disp("Generated!");