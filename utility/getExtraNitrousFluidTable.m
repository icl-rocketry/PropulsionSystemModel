function table = getExtraNitrousFluidTable()

tableFile = '+NitrousFluidProps/NitrousExtraFluidProps.mat';

dataLoaded = load(tableFile);
disp("Loaded Nitrous extra properties from file!");

table = dataLoaded.extraFluidProps;
end