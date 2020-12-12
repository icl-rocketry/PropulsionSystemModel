%Generate h(T,P) and s(T,P) etc... tables to use with StarCCM+ (or similar) from existing two phase
%fluid data generated for use with simscape
clear
clc
tableFile = '+NitrousFluidProps/NitrousFluidTables.mat';
load(tableFile);

%Define phases and how to extract their data from the existing fluid data
liquidPhase.name = 'liq';
liquidPhase.extractFcn = @(fluidTable) fluidTable.liquid;
vapourPhase.name = 'vap';
vapourPhase.extractFcn = @(fluidTable) fluidTable.vapor;

%Define values to iterate over for tabulating data
PValsLiq = nitrousFluidTable.p.*1e6;%linspace(90e3, 100e5, 80);
PValsVap = nitrousFluidTable.p.*1e6;
unormValsLiq = linspace(-1, 0, 60);
unormValsVap = linspace(1, 2, 60);

%Define properties to tabulate data for
enthalpy.name = 'Enthalpy';
enthalpy.columnHeader = "h(J/kg)";
enthalpy.extractFcn = @(fluidTable, phase, P, unorm) ...
    getSpecificEnthalpy(fluidTable, phase.extractFcn, P, unorm);
entropy.name = 'Entropy';
entropy.columnHeader = "s(J/kg-k)";
entropy.extractFcn = @(fluidTable, phase, P, unorm) ...
    getSpecificEntropy(fluidTable, phase.extractFcn, P, unorm);

%Tabulate data
disp("Generating...");
mkdir('fluidTables'); 
makePropertiesTables('fluidTables/', nitrousFluidTable, liquidPhase, PValsLiq, unormValsLiq, ...
    {enthalpy, entropy});
makePropertiesTables('fluidTables/', nitrousFluidTable, vapourPhase, PValsVap, unormValsVap, ...
    {enthalpy, entropy});
disp("Generated!");

function makePropertiesTables(path, fluidTable, phase, PVals, unormVals, properties)
    %Create headers for each
    for i=1:length(properties)
       outStr{i} = sprintf("T(K)   P(Pa)   %s\n", properties{i}.columnHeader); 
    end

    %Generate all property values
    for i=1:length(PVals)
       for j=1:length(unormVals)
            T = getTemp(fluidTable, phase.extractFcn, PVals(i), unormVals(j));
            for k=1:length(properties)
                propertyVal = properties{k}.extractFcn(fluidTable, phase, PVals(i), unormVals(j));
                outStr{k} = outStr{k} + sprintf("%d\t%d\t%d\n", T, PVals(i), propertyVal);
            end
       end
    end

    %Save all to file
    for i=1:length(properties)
        fileOutName = string(path)+string(phase.name)+string(properties{i}.name)+".csv";
        fid = fopen(fileOutName,'wt');
        fprintf(fid, '%s', outStr{i});
        fclose(fid);
    end
end

function H = getSpecificEnthalpy(fluidTable, phasePropertyFcn, P, unorm)
    %h = u+pv
    %P values in MPa fluidTable.p as row vector;
    %u values in kJ/Kg fluidTable.liquid.u column is P, row is unorm
    %v values in m^3/Kg fluidTable.liquid.v column is P , row is unorm
    %unorm values in fluidTable.liquid.unorm
    PMpa = P.*1e-6;
    u = 1000.*interp2(fluidTable.p, phasePropertyFcn(fluidTable).unorm, phasePropertyFcn(fluidTable).u, ...
        PMpa, unorm); %J/kg
    v = interp2(fluidTable.p, phasePropertyFcn(fluidTable).unorm, phasePropertyFcn(fluidTable).v, ...
        PMpa, unorm);
    H = u+P.*v;
end

function S = getSpecificEntropy(fluidTable, phasePropertyFcn, P, unorm)
    %P values in MPa fluidTable.p as row vector;
    %s values in kJ/Kg-K fluidTable.liquid.s column is P, row is unorm
    %unorm values in fluidTable.liquid.unorm
    PMpa = P.*1e-6;
    S = 1000.*interp2(fluidTable.p, phasePropertyFcn(fluidTable).unorm, phasePropertyFcn(fluidTable).s, ...
        PMpa, unorm); %J/kg
end

function T = getTemp(fluidTable, phasePropertyFcn, P, unorm)
    %P values in MPa fluidTable.p as row vector;
    PMpa = P.*1e-6;
    T = interp2(fluidTable.p, phasePropertyFcn(fluidTable).unorm, phasePropertyFcn(fluidTable).T, ...
        PMpa, unorm);
end