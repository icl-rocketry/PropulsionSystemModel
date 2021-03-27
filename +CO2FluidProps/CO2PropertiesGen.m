clear
uMin = 399.4; %kJ/kg
uMax = 480.2; %kJ/kg
%BE CAREFUL generating below triple point
pMin = 0.1; %0.1*0.09; %MPa
pMax = 10; %Mpa
numRowsLiquidPhase = 190;
numRowsVapourPhase = 190;
numPressureVals = 200;

CO2FluidTables = CO2FluidProps.twoPhaseFluidTablesCustomCO2(...
    [uMin,uMax],[pMin,pMax],...
    numRowsLiquidPhase,numRowsVapourPhase,numPressureVals,...
'PR::CarbonDioxide','py.CoolProp.CoolProp.PropsSI');
%%
save('+CO2FluidProps/CO2FluidTables.mat', 'CO2FluidTables');
disp("Generated!");