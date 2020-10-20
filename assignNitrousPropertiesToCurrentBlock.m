clear
nitrousFluidTable = getNitrousFluidTable();

disp("Current block:");
disp(gcb);
twoPhaseFluidTables(gcb,nitrousFluidTable);
disp("Assigned!");