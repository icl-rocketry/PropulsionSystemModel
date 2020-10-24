# PropulsionSystemModel
Simscape / Simulink Model for Hybrid Motor Nitrous Oxide Rocket Propulsion System

How to "download" the code (clone repo):
-Make sure you have git installed
-In MATLAB go to Home -> New -> Project -> From Git
-Enter the repository path as https://github.com/icl-rocketry/PropulsionSystemModel (Username/password login) or git@github.com:icl-rocketry/PropulsionSystemModel.git (SSH login, better)
-Set 'Sandbox' to where you want files to be stored locally
-Press retrieve
-MATLAB should download the project

Once downloaded:
-Open the project by double clicking "RocketFeedSystem.prj" within MATLAB (Probably should rename project...). This will also run the initPropulsionSystemSim.m script
-Open the propulsion simulation model by opening propulsionSystem.slx
-Run the simulation, modify/tweak/etc...
-To change input parameters modify the initPropulsionSystemSim.m script and then run it before running the sim again
