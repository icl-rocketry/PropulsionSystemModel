clear
nitrousFluidTable = getNitrousFluidTable(); %Base properties to start from

substance = 'NitrousOxide';
installPath = 'py.CoolProp.CoolProp.PropsSI';

uMin = nitrousFluidTable.u_min; %kJ/kg
uMax = nitrousFluidTable.u_max; %kJ/kg
%BE CAREFUL generating below triple point
pMin = nitrousFluidTable.p_min; %0.1*0.09; %MPa
pMax = nitrousFluidTable.p_max; %Mpa
numRowsLiquidPhase = size(nitrousFluidTable.liquid.T,1);
numRowsVapourPhase = size(nitrousFluidTable.vapor.T,1);
numPressureVals = length(nitrousFluidTable.p);

p_crit = nitrousFluidTable.p_crit; %MPa
u_crit = nitrousFluidTable.u_crit; %kJ/kg

% Create uniform grid in transformed space
unorm_liq = linspace(-1, 0, numRowsLiquidPhase)';
unorm_vap = linspace( 1, 2, numRowsVapourPhase)';
p = logspace(log10(pMin), log10(pMax), numPressureVals);
n_sub = sum(p < p_crit);

% Preallocate arrays
cp_liq     = zeros(numRowsLiquidPhase, numPressureVals);
cv_liq     = zeros(numRowsVapourPhase, numPressureVals);
pvap_liq     = zeros(numRowsVapourPhase, numPressureVals);
cp_vap     = zeros(numRowsLiquidPhase, numPressureVals);
cv_vap     = zeros(numRowsVapourPhase, numPressureVals);
pvap_vap     = zeros(numRowsVapourPhase, numPressureVals);
beta_vap     = zeros(numRowsVapourPhase, numPressureVals);

% Init coolprop

% Check Python availability
assert(~isempty(pyversion), message('physmod:simscape:utils:twoPhaseFluidTables:CannotLocatePython'))

% Check that installPath is a valid path to CoolProp Python package
% Also check if substance is valid by attempting to obtain molar mass
coolpropFun = str2func(installPath);

% Compute values

% Obtain fluid properties along saturation curve
for j = 1 : n_sub
    i = numRowsLiquidPhase;
    %Only define for above triple point
    [cp_liq(i,j), cv_liq(i,j), pvap_liq(i,j)] ...
            = getSatProps(p(j), 0, substance, coolpropFun);
    i = 1;
    [cp_vap(i,j), cv_vap(i,j), pvap_vap(i,j), T_temp] ...
        = getSatProps(p(j), 1, substance, coolpropFun);
    
    beta_vap(i,j) = NitrousFluidProps.NistNitrous.getGasIsobaricExpansion(T_temp, pvap_vap(i, j));
end

% Fill in fluid properties along the extended saturation boundary
for j = n_sub+1 : numPressureVals
    [cp_liq(numRowsLiquidPhase,j), cv_liq(numRowsLiquidPhase,j), pvap_liq(numRowsLiquidPhase,j), T_temp] ...
        = getProps(p(j), nitrousFluidTable.liquid.u_sat(j), substance, coolpropFun, p_crit);
    cp_vap(1,j) = cp_liq(numRowsLiquidPhase,j);
    cv_vap(1,j) = cv_liq(numRowsLiquidPhase,j);
    pvap_vap(1,j) = pvap_vap(numRowsLiquidPhase,j);
    
    beta_vap(1,j) = NitrousFluidProps.NistNitrous.getGasIsobaricExpansion(T_temp, pvap_vap(1,j));
end

% Fill in arrays with fluid properties
for j = 1 : numPressureVals
    for i = 1 : numRowsLiquidPhase-1
        [cp_liq(i,j), cv_liq(i,j), pvap_liq(i,j)] ...
                = getProps(p(j), nitrousFluidTable.liquid.u(i,j), substance, coolpropFun, p_crit);
    end
    for i = 2 : numRowsVapourPhase
        [cp_vap(i,j), cv_vap(i,j), pvap_vap(i,j), T_temp] ...
                = getProps(p(j), nitrousFluidTable.liquid.u(i,j), substance, coolpropFun, p_crit);
        
        % this pulls a LOT of shit from outside the gasIsobaricExpansion
        % dataset
        
        beta_vap(i,j) = NitrousFluidProps.NistNitrous.getGasIsobaricExpansion(T_temp, pvap_vap(i, j));
    end
end

% Pack into struct
extraFluidProps.liquid.cp = cp_liq;
extraFluidProps.liquid.cv = cv_liq;
extraFluidProps.liquid.pvap = pvap_liq;
extraFluidProps.liquid.unorm = nitrousFluidTable.liquid.unorm;
extraFluidProps.vapor.cp = cp_vap;
extraFluidProps.vapor.cv = cv_vap;
extraFluidProps.vapor.pvap = pvap_vap;
extraFluidProps.vapor.beta = beta_vap;
extraFluidProps.vapor.unorm = nitrousFluidTable.vapor.unorm;
extraFluidProps.p = nitrousFluidTable.p;

save('+NitrousFluidProps/NitrousExtraFluidProps.mat', 'extraFluidProps');
disp("Done!");

function [Cp, Cv, PVap, T] = getSatProps(p, x, substance, coolpropFun)
    p_Pa = p*1e6; 
    Cp = coolpropFun('Cpmass', 'P', p_Pa, 'Q', x, substance); %J/kg/K
    Cv = coolpropFun('Cvmass', 'P', p_Pa, 'Q', x, substance); %J/kg/K
    T = coolpropFun('T', 'P', p_Pa, 'Q', x, substance); % K
    PVap = p;
end

% T is returned to call Nist.Nitrous.getGasIsobaricExpansion(P,T)
function [Cp, Cv, PVap, T] = getProps(p, u, substance, coolpropFun, p_crit)
    p_Pa = p*1e6;
    u_Jkg = u*1e3;
    Cp = coolpropFun('Cpmass', 'P', p_Pa, 'U', u_Jkg, substance);
    Cv = coolpropFun('Cvmass', 'P', p_Pa, 'U', u_Jkg, substance); %J/kg/K
    T = coolpropFun('T', 'P', p_Pa, 'U', u_Jkg, substance);
    T_crit = coolpropFun('T', 'P', p_crit*1e6, 'Q', 0, substance);
    if(p >= p_crit && T >= T_crit)
       PVap = p_crit;
       return;
    end
    
    PVap_Pa = coolpropFun('P', 'T', T, 'Q', 0, substance);
    PVap = PVap_Pa / 1e6; %PVap is the vapour pressure for the same temperature that the substance is at for the given (P, U)
end