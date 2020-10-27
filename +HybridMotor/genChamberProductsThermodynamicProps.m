HybridMotor.KERAX_1303_raw_DATA

propepProps.OFVals = [2,3,4,5,6,7,8,9,10]';
propepProps.PChamberVals = 1e5*10*[0.05 0.1 0.15 0.2 0.25	0.3	0.35	0.4	0.45	0.5	0.55 ...
    0.6	0.65	0.7	0.75	0.8	0.85	0.9	0.95	1	1.5	2 ...
    2.5	3	3.5	4	4.5	5	5.5	6]'; %Pa
% (Rows = O/F 2-10, Columns = Pressure 0.5 - 60 Bar)
propepProps.TFlame = T_ALL; %flame temp K
propepProps.gasConstant = R_ALL; %J/(kg.K)
propepProps.molarMass = MW_ALL ./ 1e3; %kg/mol
propepProps.enthalpy = H_ALL ./ propepProps.molarMass; %J/Kg (From J/mol)
propepProps.internalEnergy = U_ALL ./ propepProps.molarMass; %J/Kg (From J/mol)
propepProps.entropy = S_ALL ./ propepProps.molarMass; %J/(Kg.K) (From J/mol)
propepProps.Cp = CP_ALL; %J/(kg.K)
propepProps.Cv = CV_ALL; %J/(kg.K)
propepProps.gamma = gamma_ALL; %Ratio of specific heats
propepProps.isentropicExponent = kappa_ALL; %Use for p*v^k = constant (isentropic)
propepProps.density = rho_ALL; %kg/m^3

save('+HybridMotor/propepPropsKeraxN2O.mat', 'propepProps');