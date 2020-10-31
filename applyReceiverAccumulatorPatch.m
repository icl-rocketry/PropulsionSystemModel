doPatch();

function doPatch()
disp("Checking if MATLAB has patched reciver accumulator version...");
matlabDir = '';
patchDirPath = '';
fullPatchDirPath = '';
patchFilePath = '';
patchTestFilePath = '';
makePaths();
patchedAlready = exist(patchTestFilePath);
if(patchedAlready)
    disp("Already patched! Not re-applying patch!");
   return; 
end

localPatchFilePath = fullfile(['Patch for R2020b and R2020a' filesep 'receiver_accumulator.sscp']);
if ~exist(localPatchFilePath)
   error('Unable to find local patch file, make sure it exists and you are running this script from the same folder it is in'); 
end

disp("Copying patch file");
[copySuccess, msg] = copyfile(localPatchFilePath, patchFilePath, 'f');
if ~copySuccess
   disp(msg);
   error('Unable to copy patch file'); 
end
disp("Patch file copied successfully!");
disp("Running necessary commands to refresh MATLAB...");
clear classes
rehash toolboxcache
disp("Commands ran, patch should be applied! Creating a file to mark that the patch was applied...");
%Need to redefine var as was cleared
makePaths();
fid = fopen(patchTestFilePath, 'w');
fprintf(fid, 'receiver_accumulator.sscp patched at %s', datestr(datetime('now')));
fclose(fid);

    function makePaths()
        matlabDir = fullfile(matlabroot());
        patchDirPath = ['toolbox' filesep 'physmod' filesep 'fluids' filesep 'fluids' filesep '+fluids' ...
        filesep '+two_phase_fluid' filesep '+tanks_accumulators'];
        fullPatchDirPath = fullfile([matlabDir filesep patchDirPath]);
        patchFilePath = fullfile([fullPatchDirPath filesep 'receiver_accumulator.sscp']);
        patchTestFilePath = fullfile(['receiverAccumulatorPatchedLog.txt']); %If this exists then is patched
    end

end
