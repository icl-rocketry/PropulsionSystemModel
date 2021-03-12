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
beta_liq     = zeros(numRowsLiquidPhase, numPressureVals);
% Init coolprop

% Check Python availability
assert(~isempty(pyenv), message('physmod:simscape:utils:twoPhaseFluidTables:CannotLocatePython'))

% Check that installPath is a valid path to CoolProp Python package
% Also check if substance is valid by attempting to obtain molar mass
coolpropFun = str2func(installPath);
betaLiqFun = str2func("NitrousFluidProps.NistNitrous.getLiquidIsobaricExpansion");
betaVapFun = str2func("NitrousFluidProps.NistNitrous.getGasIsobaricExpansion");
% Compute values

% Obtain fluid properties along saturation curve
for j = 1 : n_sub
    i = numRowsLiquidPhase;
    %Only define for above triple point
    [cp_liq(i,j), cv_liq(i,j), pvap_liq(i,j),~, beta_liq(i,j)] ...
        = getSatProps(p(j), 0, substance, coolpropFun, betaLiqFun, betaVapFun);
        
    i = 1;
    [cp_vap(i,j), cv_vap(i,j), pvap_vap(i,j),~, beta_vap(i,j)] ...
        = getSatProps(p(j), 1, substance, coolpropFun, betaLiqFun, betaVapFun);
end

% Fill in fluid properties along the extended saturation boundary
for j = n_sub+1 : numPressureVals
    [cp_liq(numRowsLiquidPhase,j), cv_liq(numRowsLiquidPhase,j),...
        pvap_liq(numRowsLiquidPhase,j), beta_liq(numRowsLiquidPhase,j), beta_vap(1,j)] ...
        = getProps(p(j), nitrousFluidTable.liquid.u_sat(j), substance,...
        coolpropFun, p_crit, betaLiqFun, betaVapFun);
    
    cp_vap(1,j) = cp_liq(numRowsLiquidPhase,j);
    cv_vap(1,j) = cv_liq(numRowsLiquidPhase,j);
    pvap_vap(1,j) = pvap_vap(numRowsLiquidPhase,j); % what is this?
end

% Fill in arrays with fluid properties
for j = 1 : numPressureVals
    for i = 1 : numRowsLiquidPhase-1
        [cp_liq(i,j), cv_liq(i,j), pvap_liq(i,j), beta_liq(i,j)] ...
                = getProps(p(j), nitrousFluidTable.liquid.u(i,j), substance,...
                coolpropFun, p_crit, betaLiqFun, betaVapFun);
    end
    for i = 2 : numRowsVapourPhase
        [cp_vap(i,j), cv_vap(i,j), pvap_vap(i,j), ~, beta_vap(i,j)] ...
                = getProps(p(j), nitrousFluidTable.liquid.u(i,j), substance,...
                coolpropFun, p_crit, betaLiqFun, betaVapFun);
    end
end

% Pack into struct
disp(max(pvap_vap));
extraFluidProps.liquid.cp = cp_liq;
extraFluidProps.liquid.cv = cv_liq;
extraFluidProps.liquid.pvap = pvap_liq;
extraFluidProps.liquid.unorm = nitrousFluidTable.liquid.unorm;
extraFluidProps.liquid.beta = beta_liq;
extraFluidProps.vapor.cp = cp_vap;
extraFluidProps.vapor.cv = cv_vap;
extraFluidProps.vapor.pvap = pvap_vap;
extraFluidProps.vapor.beta = beta_vap;
extraFluidProps.vapor.unorm = nitrousFluidTable.vapor.unorm;
extraFluidProps.p = nitrousFluidTable.p;

save('+NitrousFluidProps/NitrousExtraFluidProps.mat', 'extraFluidProps');
disp("Done!");

function [Cp, Cv, PVap, T, beta] = getSatProps(p, x, substance,...
                    coolpropFun, betaLiqFun, betaVapFun)
    p_Pa = p*1e6; 
    Cp = coolpropFun('Cpmass', 'P', p_Pa, 'Q', x, substance); %J/kg/K
    Cv = coolpropFun('Cvmass', 'P', p_Pa, 'Q', x, substance); %J/kg/K
    T = coolpropFun('T', 'P', p_Pa, 'Q', x, substance); % K
    PVap = p;
    switch x
        case 0
            beta =  betaLiqFun(p_Pa,T);
        case 1
            beta = betaVapFun(p_Pa,T);
        otherwise
            fprintf("x != 0, 1 in genSatProps. T: %g K, P: %g bar",T,p_Pa/1e5)
    end
%     assert(beta > 0, "beta < 0, T: %g K, P: %g bar, x: %i", T, p_Pa/1e5, x)
end

function [Cp, Cv, PVap, beta_liq, beta_vap] = getProps(p, u, substance,...
                    coolpropFun, p_crit, betaLiqFun, betaVapFun)
    p_Pa = p*1e6;
    u_Jkg = u*1e3;
    Cp = coolpropFun('Cpmass', 'P', p_Pa, 'U', u_Jkg, substance);
    Cv = coolpropFun('Cvmass', 'P', p_Pa, 'U', u_Jkg, substance); %J/kg/K
    T = coolpropFun('T', 'P', p_Pa, 'U', u_Jkg, substance);
    T_crit = coolpropFun('T', 'P', p_crit*1e6, 'Q', 0, substance);
    [beta_liq, beta_vap] = getBeta(p_Pa, u_Jkg, T, substance,...
                    coolpropFun, betaLiqFun, betaVapFun);
    
    if(p >= p_crit && T >= T_crit)
       PVap = p_crit;
       return
    end
    
    PVap_Pa = coolpropFun('P', 'T', T, 'Q', 0, substance);
    PVap = PVap_Pa / 1e6; %PVap is the vapour pressure for the same temperature that the substance is at for the given (P, U)
end

function [beta_liq, beta_vap] = getBeta(p_Pa, u_Jkg, T, substance,...
                    coolpropFun, betaLiqFun, betaVapFun)
    phase = coolpropFun("Phase", "P", p_Pa, "U", u_Jkg, substance); % returns phase index
    phase_map = containers.Map([0, 1, 2, 3, 5, 6, 8],["liquid",...
        "supercritical","supercritical_gas","supercritical_liquid","gas",...
        "twophase","not_imposed"]); % for fancy error messages
    % 0: liquid
    % 0 also returned when CP.get_phase_index() fed unknown string, potential
    % issue?
    % 1: supercritical
    % 2: supercritical_gas
    % 3: supercritical_liquid
    % 5: gas/vapour
    % 6: twophase
    % 8: not_imposed
    switch phase
        case 0 % liquid
            beta_liq =  betaLiqFun(p_Pa,T);
            beta_vap = beta_liq;
%             assert(beta_liq > 0, "beta < 0. T: %g K, P: %g bar, phase: %s",...
%                 T, p_Pa/1e5, phase_map(phase))
        case 1 % supercritical
            beta_vap = betaVapFun(p_Pa,T);
            beta_liq = betaLiqFun(p_Pa,T);
        case 3 % supercritical_liquid
            beta_liq = betaLiqFun(p_Pa,T);
            beta_vap = beta_liq;
            if(~(beta_vap > 0 && beta_vap < 1))
                beta_vap = betaVapFun(p_Pa,T);
            end
        case 5 % gas
            beta_vap = betaVapFun(p_Pa,T);
            beta_liq = beta_vap;
            assert(beta_vap > 0, "beta < 0. T: %g K, P: %g bar, phase: %s",...
                T, p_Pa/1e5, phase_map(phase))
        case 6 % twophase
%             fprintf("2p region; T: %g K, P: %g bar\n", T, p_Pa/1e5)
            beta_vap = betaVapFun(p_Pa,T);
            beta_liq = betaLiqFun(p_Pa,T);
        otherwise % something is wrong if this triggers
            error("x != 0, 1. T: %g K, P: %g bar, phase: %s\n",...
                T, p_Pa/1e5, phase_map(phase))
    end
    assert(beta_liq < 1)
    if(~(beta_vap > 0 && beta_vap < 1))
       disp("Non physical beta_vap for P:"+p_Pa+", T:"+T); 
    end
    assert(beta_vap > 0 && beta_vap < 1)
end