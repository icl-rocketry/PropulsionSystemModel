function table = getNitrousFluidTable()

tableFile = '+NitrousFluidProps/NitrousFluidTables.mat';
if ~exist(tableFile, 'file')
    import NitrousFluidProps.nitrousPropertiesGen
    nitrousPropertiesGen();
    disp("Generated properties...");
end

dataLoaded = load(tableFile);
disp("Loaded Nitrous properties from file!");

table = dataLoaded.nitrousFluidTable;
end