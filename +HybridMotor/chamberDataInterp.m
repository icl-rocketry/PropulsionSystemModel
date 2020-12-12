function [T_flame, gamma, m_mol, R, rho, isentropicExponent, c_star] = chamberDataInterp(propepProps, OF,P_cc,etac)
%interp uses X is P_cc and Y is OF

% propepProps = load('+HybridMotor/propepPropsKeraxN2O.mat');

if(OF < min(propepProps.OFVals) || OF > max(propepProps.OFVals))
    disp("OF: ");
    disp(OF);
    disp("Min OF:");
    disp(min(propepProps.OFVals));
    disp("Max OF:");
    disp(max(propepProps.OFVals));
    error('OF Out of bounds (thermochem)');
end

if P_cc < min(propepProps.PChamberVals) || P_cc > max(propepProps.PChamberVals)
    disp("P_cc: ");
    disp(P_cc);
    disp("Min P_cc:");
    disp(min(propepProps.PChamberVals));
    disp("Max P_cc:");
    disp(max(propepProps.PChamberVals));
    error(['P_cc Out of bounds (thermochem)']);
end

T_flame = interp2(propepProps.PChamberVals,propepProps.OFVals,propepProps.TFlame,P_cc,OF);  % [K] 
gamma = interp2(propepProps.PChamberVals,propepProps.OFVals,propepProps.gamma,P_cc,OF);      % [-]
m_mol = interp2(propepProps.PChamberVals,propepProps.OFVals,propepProps.molarMass,P_cc,OF);      % [kg/mol]
R = interp2(propepProps.PChamberVals,propepProps.OFVals,propepProps.gasConstant,P_cc,OF); %Specific gas constant
rho = interp2(propepProps.PChamberVals,propepProps.OFVals,propepProps.density,P_cc,OF); %kg/m^3
isentropicExponent = interp2(propepProps.PChamberVals,propepProps.OFVals,propepProps.isentropicExponent,P_cc,OF); %p*v^k = constant for isentropic

%etac is the combustion efficiency, usually about 0.95 [SPAD]
c_star = etac*sqrt(gamma*R*T_flame)/(gamma*(2/(gamma+1))^((gamma+1)/(2*gamma-2))); %characteristic velocity [SPAD, eq 7.71]

end
