# PropulsionSystemModel
Simscape / Simulink Model for Hybrid Motor Nitrous Oxide Rocket Propulsion System

# Fix for MATLAB R2020b/R2020a (IMPORTANT):
For the results to be valid it is important you do this. In R2020a/R2020b (at time of writing) there is a problem with the receiver accumulator block. MathWorks have provided an updated version of the block which is fixed but you will need to place it into the correct place within your MATLAB directory and then run a few commands.
Instructions:
- Close MATLAB
- Copy receiver_accumulator.sscp from the folder "Patch for R2020b and R2020a" to the following location:
\<matlabroot\>\toolbox\physmod\fluids\fluids\+fluids\+two_phase_fluid\+tanks_accumulators\
Where \<matlabroot\> looks something like C:\Program Files\MATLAB\R2020b
- Open MATLAB
- Run the MATLAB command: "clear classes"
- Run the MATLAB command: "rehash toolboxcache"
- Open the project and verify the model works

# How to "download" the code (clone repo):
- Make sure you have git installed
- In MATLAB go to Home -> New -> Project -> From Git
- Enter the repository path as https://github.com/icl-rocketry/PropulsionSystemModel (Username/password login) or git@github.com:icl-rocketry/PropulsionSystemModel.git (SSH login, better)
- Set 'Sandbox' to where you want files to be stored locally
- Press retrieve
- MATLAB should download the project

# Once downloaded:
- Open the project by double clicking "RocketFeedSystem.prj" within MATLAB (Probably should rename project...). This will also run the initPropulsionSystemSim.m script
- Open the propulsion simulation model by opening propulsionSystem.slx
- Run the simulation, modify/tweak/etc...
- To change input parameters modify the initPropulsionSystemSim.m script and then run it before running the sim again

# To re-sync:
- Within the 'Project' toolbar use the buttons in the 'source control' section:
- Press the 'Pull' button to fetch latest changes and merge them with your local copy. If there is a conflicting change, MATLAB will ask you to pick which change to keep ("Merge commits/branches")

# To submit changes:
- Within the 'Project' toolbar use the buttons in the 'source control' section:
- Make sure you're happy with your changes
- Press the "Commit" button, type a description of what you changed and press "Submit". This will LOCALLY commit the changes
- Press the "Push" button to submit your committed local changes to the repository. If it fails because your code 'is not up-to-date' then re-sync (Pull) and then try again.
