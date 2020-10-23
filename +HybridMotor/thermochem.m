function [T_flame, gamma, m_mol, R,c_star] = thermochem(propepProps, OF,P_cc,etac)
%interp uses X is P_cc and Y is OF

% propepProps = load('+HybridMotor/propepinterp.mat');

%T_flame = 3300;
%gamma = 1.24;
%m_mol = 0.0262109;  %Molar mass (kg/mol) should be determined properly

if(OF < min(propepProps.OF_vals) || OF > max(propepProps.OF_vals))
    disp("OF: ");
    disp(OF);
    disp("Min OF:");
    disp(min(propepProps.OF_vals));
    disp("Max OF:");
    disp(max(propepProps.OF_vals));
    error('OF Out of bounds (thermochem)');
end

if P_cc < min(propepProps.P_cc_vals) || P_cc > max(propepProps.P_cc_vals)
    disp("P_cc: ");
    disp(P_cc);
    disp("Min P_cc:");
    disp(min(propepProps.P_cc_vals));
    disp("Max P_cc:");
    disp(max(propepProps.P_cc_vals));
    error(['P_cc Out of bounds (thermochem)']);
end

T_flame = interp2(propepProps.P_cc_vals,flipud(propepProps.OF_vals),flipud(propepProps.T_flame_data),P_cc,OF);  % [K] 
gamma = interp2(propepProps.P_cc_vals,flipud(propepProps.OF_vals),flipud(propepProps.gamma_data),P_cc,OF);      % [-]
m_mol = interp2(propepProps.P_cc_vals,flipud(propepProps.OF_vals),flipud(propepProps.m_mol_data),P_cc,OF);      % [kg/mol]

R = 8.314/m_mol;    %Specific Gas Constant [SPAD, eq 7 .72]
%etac is the combustion efficiency, usually about 0.95 [SPAD]
c_star = etac*sqrt(gamma*R*T_flame)/(gamma*(2/(gamma+1))^((gamma+1)/(2*gamma-2))); %characteristic velocity [SPAD, eq 7.71]

end
