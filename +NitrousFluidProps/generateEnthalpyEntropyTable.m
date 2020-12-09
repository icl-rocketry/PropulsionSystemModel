%Generate h(T,P) and s(T,P) tables to use with StarCCM+ from existing two phase
%fluid data
clear
clc
tableFile = '+NitrousFluidProps/NitrousFluidTables.mat';
load(tableFile);
liquidPhase = @(fluidTable) fluidTable.liquid;
vapourPhase = @(fluidTable) fluidTable.vapor;
[H, T] = getSpecificEnthalpyAndTemp(nitrousFluidTable, liquidPhase, 65e5, -0.5);

PValsLiq = nitrousFluidTable.p.*1e6;%linspace(90e3, 100e5, 80);
PValsVap = nitrousFluidTable.p.*1e6;
unormValsLiq = linspace(-1, 0, 60);
unormValsVap = linspace(1, 2, 60);

disp("Generating...");
mkdir('fluidTables');
makeEnthalpyEntropyTable(nitrousFluidTable, liquidPhase, PValsLiq, unormValsLiq, ...
    'fluidTables/liqEnthalpy.csv', 'fluidTables/liqEntropy.csv');
makeEnthalpyEntropyTable(nitrousFluidTable, vapourPhase, PValsLiq, unormValsLiq, ...
    'fluidTables/vapEnthalpy.csv', 'fluidTables/vapEntropy.csv');
disp("Generated!");

function makeEnthalpyEntropyTable(fluidTable, phase, PVals, unormVals, fileOutEnthalpy, fileOutEntropy)
    outStrH = sprintf("T(K)   P(Pa)   h(J/kg)\n");
    outStrS = sprintf("T(K)   P(Pa)   s(J/kg-k)\n");

    for i=1:length(PVals)
       for j=1:length(unormVals)
            [H, T] = getSpecificEnthalpyAndTemp(fluidTable, phase, PVals(i), unormVals(j));
            [S, ~] = getSpecificEntropyAndTemp(fluidTable, phase, PVals(i), unormVals(j));
            outStrH = outStrH + sprintf("%d\t%d\t%d\n", T, PVals(i), H);
            outStrS = outStrS + sprintf("%d\t%d\t%d\n", T, PVals(i), S);
       end
    end

    fid = fopen(fileOutEnthalpy,'wt');
    fprintf(fid, '%s', outStrH);
    fclose(fid);
    
    fid = fopen(fileOutEntropy,'wt');
    fprintf(fid, '%s', outStrS);
    fclose(fid);
end

function [H, T] = getSpecificEnthalpyAndTemp(fluidTable, phasePropertyFcn, P, unorm)
    %h = u+pv
    %P values in MPa fluidTable.p as row vector;
    %u values in kJ/Kg fluidTable.liquid.u column is P, row is unorm
    %v values in m^3/Kg fluidTable.liquid.v column is P , row is unorm
    %unorm values in fluidTable.liquid.unorm between -1 and 0
    PMpa = P.*1e-6;
    u = 1000.*interp2(fluidTable.p, phasePropertyFcn(fluidTable).unorm, phasePropertyFcn(fluidTable).u, ...
        PMpa, unorm); %J/kg
    v = interp2(fluidTable.p, phasePropertyFcn(fluidTable).unorm, phasePropertyFcn(fluidTable).v, ...
        PMpa, unorm);
    T = interp2(fluidTable.p, phasePropertyFcn(fluidTable).unorm, phasePropertyFcn(fluidTable).T, ...
        PMpa, unorm);
    H = u+P.*v;
end

function [S, T] = getSpecificEntropyAndTemp(fluidTable, phasePropertyFcn, P, unorm)
    %h = u+pv
    %P values in MPa fluidTable.p as row vector;
    %s values in kJ/Kg-K fluidTable.liquid.s column is P, row is unorm
    %unorm values in fluidTable.liquid.unorm between -1 and 0
    PMpa = P.*1e-6;
    S = 1000.*interp2(fluidTable.p, phasePropertyFcn(fluidTable).unorm, phasePropertyFcn(fluidTable).s, ...
        PMpa, unorm); %J/kg
    T = interp2(fluidTable.p, phasePropertyFcn(fluidTable).unorm, phasePropertyFcn(fluidTable).T, ...
        PMpa, unorm);
end