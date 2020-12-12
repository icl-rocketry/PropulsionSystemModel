clear
% nitrousFluidTable = getNitrousFluidTable();
dataLoaded = load('+NitrousFluidProps/NitrousFluidTablesExtended.mat');
nitrousFluidTable = dataLoaded.nitrousFluidTable;

disp("Current block:");
disp(gcb);
twoPhaseFluidTables(gcb,nitrousFluidTable);
disp("Assigned!");