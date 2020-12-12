% Find all ports with data logging enabled
pH = find_system('propulsionSystem', 'FindAll', 'on', 'Type', 'Port', 'DataLogging', 'on');
% Disable all logging
for x=1:length(pH)
   set_param(pH(x), 'DataLogging', 'off');
end