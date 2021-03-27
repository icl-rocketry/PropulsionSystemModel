function varargout = twoPhaseFluidTablesCustomCO2(varargin)
%twoPhaseFluidTables   obtain fluid properties from REFPROP or CoolProp
%
%   fluidTables = twoPhaseFluidTables(uRange, pRange, mLiquid, mVapor, n,
%   substance, installPath) returns the two-phase fluid property tables in
%   the structure fluidTables. The rows of the tables correspond to
%   normalized internal energy and the columns of the tables correspond to
%   pressure.
%
%   twoPhaseFluidTables(block, fluidTables) assigns the two-phase fluid
%   property tables to the Two-Phase Fluid Properties (2P) block identified
%   by the Simulink block path. The variable fluidTables must exist in the
%   workspace.
%
%   The range of the tables is specified by uRange and pRange. uRange is a
%   2-element array that contains the minimum and maximum specific internal
%   energy in kJ/kg. pRange is a 2-element array that contains the minimum
%   and maximum pressure in MPa. The minimum pressure must be greater than
%   the triple point pressure.
%
%   The size of the tables are specified by mLiquid, mVapor, and n. The
%   liquid tables have dimensions mLiquid-by-n. The vapor tables have
%   dimensions mVapor-by-n.
%
%   substance is a string scalar or character vector that contains the name
%   of the fluid recognized by REFPROP or CoolProp.
%
%   installPath is a string scalar or character vector that contains either
%   the directory where REFPROP is installed or the Python package path to
%   the CoolProp PropsSI function. For example, 'C:\Program Files
%   (x86)\REFPROP' or 'py.CoolProp.CoolProp.PropsSI'.
%
%   The output structure fluidTables has the following fields:
%   p      - pressure vector [MPa]
%   liquid - structure of liquid property tables
%   vapor  - structure of vapor property tables
%   u_min  - minimum valid specific internal energy [kJ/kg]
%   u_max  - maximum valid specific internal energy [kJ/kg]
%   p_min  - minimum valid pressure [MPa]
%   p_max  - maximum valid pressure [MPa]
%   p_crit - critical pressure [MPa]
%   u_crit - critical point specific internal energy [kJ/kg]
%   n_sub  - Number of elements in p that is less than p_crit
%
%   The structure fluidTables.liquid contains the following fields:
%   unorm - normalized liquid internal energy vector
%   v     - liquid specific volume table [m^3/kg]
%   s     - liquid specific entropy table [kJ/(kg*K)]
%   T     - liquid temperature table [K]
%   nu    - liquid kinematic viscosity table [mm^2/s]
%   k     - liquid thermal conductivity table [W/(m*K)]
%   Pr    - liquid Prandtl number
%   u_sat - saturated liquid specific internal energy vector [kJ/kg]
%   u     - liquid specific internal energy table [kJ/kg]
%
%   The structure fluidTables.vapor contains the following fields:
%   unorm - normalized vapor internal energy vector
%   v     - vapor specific volume table [m^3/kg]
%   s     - vapor specific entropy table [kJ/kg/K]
%   T     - vapor temperature table [K]
%   nu    - vapor kinematic viscosity table [mm^2/s]
%   k     - vapor thermal conductivity table [W/(m*K)]
%   Pr    - vapor Prandtl number
%   u_sat - saturated vapor specific internal energy vector [kJ/kg]
%   u     - vapor specific internal energy table [kJ/kg]

%   Copyright 2013-2019 The MathWorks, Inc.

% for extrap of properties
py.CoolProp.CoolProp.set_config_bool(py.CoolProp.CoolProp.DONT_CHECK_PROPERTY_LIMITS,1)

% Assign inputs
if nargin == 7
    nargoutchk(0, 1)
    
    uRange      = varargin{1};
    pRange      = varargin{2};
    mLiquid     = varargin{3};
    mVapor      = varargin{4};
    n           = varargin{5};
    substance   = varargin{6};
    installPath = varargin{7};
    
    % Validate inputs
    validateattributes(uRange, {'numeric'}, {'numel', 2, 'nonempty', 'real', 'finite', 'increasing'}, '', 'uRange')
    validateattributes(pRange, {'numeric'}, {'numel', 2, 'nonempty', 'real', 'finite', 'positive', 'increasing'}, '', 'pRange')
    validateattributes(mLiquid, {'numeric'}, {'scalar', 'nonempty', 'integer', 'real', 'finite', '>=', 3}, '', 'mLiquid')
    validateattributes(mVapor, {'numeric'}, {'scalar', 'nonempty', 'integer', 'real', 'finite', '>=', 3}, '', 'mVapor')
    validateattributes(n, {'numeric'}, {'scalar', 'nonempty', 'integer', 'real', 'finite', '>=', 3}, '', 'n')
    validateattributes(substance, {'char', 'string'}, {'scalartext'}, '', 'substance')
    validateattributes(installPath, {'char', 'string'}, {'scalartext'}, '', 'installPath')
    substance = char(substance);
    installPath = char(installPath);
    validateattributes(substance, {'char'}, {'nonempty'}, '', 'substance')
    validateattributes(installPath, {'char'}, {'nonempty'}, '', 'installPath')
    
    % Obtain functions to compute fluid properties from either REFPROP or
    % CoolProp
    [criticalTriplePressure, saturationProperties, fluidProperties, specificHeat, objCleanup] ...
        = initialize(installPath, substance); %#ok<ASGLU>
    
    % Check that pressure is above the triple point pressure
%     [p_crit, u_crit, p_triple] = criticalTriplePressure();
    [p_crit, u_crit, p_triple] = criticalTriplePressure();
%     assert(pRange(1) > p_triple, ...
%         message('physmod:simscape:utils:twoPhaseFluidTables:MinPressureGreaterThanTriple', [num2str(pRange(1)) ' MPa'], [num2str(p_triple), ' MPa'], substance))
%     assert(pRange(1) < p_crit, ...
%         message('physmod:simscape:utils:twoPhaseFluidTables:MinPressureLessThanCritical', [num2str(pRange(1)) ' MPa'], [num2str(p_crit), ' MPa'], substance))
    
    % Create uniform grid in transformed space
    unorm_liq = linspace(-1, 0, mLiquid)';
    unorm_vap = linspace( 1, 2, mVapor)';
    p = logspace(log10(pRange(1)), log10(pRange(2)), n);
    n_sub = sum(p < p_crit);

    % Preallocate arrays
    u_sat_liq = zeros(1, n);
    v_liq     = zeros(mLiquid, n);
    s_liq     = zeros(mLiquid, n);
    T_liq     = zeros(mLiquid, n);
    nu_liq    = zeros(mLiquid, n);
    k_liq     = zeros(mLiquid, n);
    Pr_liq    = zeros(mLiquid, n);
    u_sat_vap = zeros(1, n);
    v_vap     = zeros(mVapor, n);
    s_vap     = zeros(mVapor, n);
    T_vap     = zeros(mVapor, n);
    nu_vap    = zeros(mVapor, n);
    k_vap     = zeros(mVapor, n);
    Pr_vap    = zeros(mVapor, n);
    
    % Obtain fluid properties along saturation curve
    for j = 1 : n_sub
        i = mLiquid;
        %Only define for above triple point
%         if(p(j) > p_triple)
            [u_sat_liq(j), v_liq(i,j), s_liq(i,j), T_liq(i,j), nu_liq(i,j), k_liq(i,j), Pr_liq(i,j)] ...
                = saturationProperties(p(j), 0);
            i = 1;
            [u_sat_vap(j), v_vap(i,j), s_vap(i,j), T_vap(i,j), nu_vap(i,j), k_vap(i,j), Pr_vap(i,j)] ...
                = saturationProperties(p(j), 1);
%         else
            %Set invalid values
%             u_sat_liq(j) = 0;
%             u_sat_vap(j) = 0;
%         end
    end
    
    % Check that uRange covers the saturation boundaries
%     assert(uRange(1) < min(u_sat_liq(1:n_sub)), ...
%         message('physmod:simscape:utils:twoPhaseFluidTables:MinInternalEnergyLessThanSaturation', [num2str(uRange(1)) ' kJ/kg'], [num2str(min(u_sat_liq(1:n_sub))) ' kJ/kg']))
    assert(uRange(2) > max(u_sat_vap(1:n_sub)), ...
        message('physmod:simscape:utils:twoPhaseFluidTables:MaxInternalEnergyGreaterThanSaturation', [num2str(uRange(2)) ' kJ/kg'], [num2str(max(u_sat_vap(1:n_sub))) ' kJ/kg']))
    
    % Extend saturation boundary above critical point along the
    % pseudocritical line
    tolx = 1e-4;
    opts = optimset('Display', 'off', 'MaxFunEvals', 100, 'TolX', tolx);
    u_mid = (uRange(1) + uRange(2))/2;
    delta_u = (uRange(2) - uRange(1));
    u_last = u_crit;
    for j = n_sub+1 : n
        % Search for specific internal energy at peak specific heat
        % If search fails, continue with the last specific internal energy
        try
            [u_scaled, ~, exitflag] = fminbnd(@(u_scaled) -specificHeat(p(j), u_scaled*delta_u/2 + u_mid), -1, 1, opts);
            if exitflag == 1
                % If search returns min or max specific internal energy,
                % then there is no more peak specific heat
                tol_bnd = 2*(tolx + 3*abs(u_scaled)*sqrt(eps));
                if (u_scaled + 1 <= tol_bnd) || (1 - u_scaled <= tol_bnd)
                    u_sat_liq(j:n) = u_last;
                    break
                else
                    u_sat_liq(j) = u_scaled*delta_u/2 + u_mid;
                end
            else
                u_sat_liq(j) = u_last;
            end
        catch
            u_sat_liq(j) = u_last;
        end
        u_last = u_sat_liq(j);
    end
    
    % Fill in fluid properties along the extended saturation boundary
    for j = n_sub+1 : n
        [v_liq(mLiquid,j), s_liq(mLiquid,j), T_liq(mLiquid,j), nu_liq(mLiquid,j), k_liq(mLiquid,j), Pr_liq(mLiquid,j)] ...
            = fluidProperties(p(j), u_sat_liq(j));
        v_vap(1,j)   = v_liq(mLiquid,j);
        s_vap(1,j)   = s_liq(mLiquid,j);
        T_vap(1,j)   = T_liq(mLiquid,j);
        nu_vap(1,j)  = nu_liq(mLiquid,j);
        k_vap(1,j)   = k_liq(mLiquid,j);
        Pr_vap(1,j)  = Pr_liq(mLiquid,j);
        u_sat_vap(j) = u_sat_liq(j);
    end
    
    % Transform grid back to original space
    u_liq = (unorm_liq + 1)*(u_sat_liq - uRange(1)) + uRange(1);
    u_vap = (unorm_vap - 2)*(uRange(2) - u_sat_vap) + uRange(2);
    
    % Fill in arrays with fluid properties
    for j = 1 : n
        for i = 1 : mLiquid-1
%             if(p(j) > p_triple)
            [v_liq(i,j), s_liq(i,j), T_liq(i,j), nu_liq(i,j), k_liq(i,j), Pr_liq(i,j)] ...
                = fluidProperties(p(j), u_liq(i,j));
%             else
%                 %TODO???
%                 %Set invalid but non zero values
%                 v_liq(i,j) = 1e-12;
%                 s_liq(i,j) = 1e-12;
%                 T_liq(i,j) = 1e-12;
%                 nu_liq(i,j) = 1e-12;
%                 k_liq(i,j) = 1e-12;
%                 Pr_liq(i,j) = 1e-12;
%             end
        end
        for i = 2 : mVapor
            try
                [v_vap(i,j), s_vap(i,j), T_vap(i,j), nu_vap(i,j), k_vap(i,j), Pr_vap(i,j)] ...
                    = fluidProperties(p(j), u_vap(i,j));
            catch err
                %Display error but proceed anyway
                disp(err);
                v_vap(i,j) = 1e-12;
                s_vap(i,j) = 1e-12;
                T_vap(i,j) = 1e-12;
                nu_vap(i,j) = 1e-12;
                k_vap(i,j) = 1e-12;
                Pr_vap(i,j) = 1e-12;
            end
        end
    end
    
    % Pack fluid property tables into structure
    fluidTables.p            = p;
    fluidTables.liquid.unorm = unorm_liq;
    fluidTables.liquid.v     = v_liq;
    fluidTables.liquid.s     = s_liq;
    fluidTables.liquid.T     = T_liq;
    fluidTables.liquid.nu    = nu_liq;
    fluidTables.liquid.k     = k_liq;
    fluidTables.liquid.Pr    = Pr_liq;
    fluidTables.liquid.u_sat = u_sat_liq;
    fluidTables.liquid.u     = u_liq;
    fluidTables.vapor.unorm  = unorm_vap;
    fluidTables.vapor.v      = v_vap;
    fluidTables.vapor.s      = s_vap;
    fluidTables.vapor.T      = T_vap;
    fluidTables.vapor.nu     = nu_vap;
    fluidTables.vapor.k      = k_vap;
    fluidTables.vapor.Pr     = Pr_vap;
    fluidTables.vapor.u_sat  = u_sat_vap;
    fluidTables.vapor.u      = u_vap;
    fluidTables.u_min        = uRange(1);
    fluidTables.u_max        = uRange(2);
    fluidTables.p_min        = pRange(1);
    fluidTables.p_max        = pRange(2);
    fluidTables.p_crit       = p_crit;
    fluidTables.u_crit       = u_crit;
    fluidTables.n_sub        = n_sub;
    
    varargout{1} = fluidTables;
    
elseif nargin == 2
    nargoutchk(0, 0)
    
    block = varargin{1};
    fluidTables = varargin{2};
    
    % Validate inputs
    validateattributes(fluidTables, {'struct', 'char', 'string'}, {}, '', 'fluidTables')
    if isstruct(fluidTables)
        validateattributes(fluidTables, {'struct'}, {'nonempty'}, '', 'fluidTables')
        varName = inputname(2);
        assert(strlength(varName) > 0, message('physmod:simscape:utils:twoPhaseFluidTables:InvalidVariableName'))
    else
        validateattributes(fluidTables, {'char', 'string'}, {'scalartext'}, '', 'fluidTables')
        varName = char(fluidTables);
    end
    
    % Set block parameters
    set_param(block, 'u_min', [varName '.u_min'])
    set_param(block, 'u_min_unit', 'kJ/kg')
    set_param(block, 'u_max', [varName '.u_max'])
    set_param(block, 'u_max_unit', 'kJ/kg')
    set_param(block, 'p_TLU', [varName '.p'])
    set_param(block, 'p_TLU_unit', 'MPa')
    set_param(block, 'p_crit', [varName '.p_crit'])
    set_param(block, 'p_crit_unit', 'MPa')
    set_param(block, 'unorm_liq', [varName '.liquid.unorm'])
    set_param(block, 'unorm_liq_unit', '1')
    set_param(block, 'v_liq', [varName '.liquid.v'])
    set_param(block, 'v_liq_unit', 'm^3/kg')
    set_param(block, 's_liq', [varName '.liquid.s'])
    set_param(block, 's_liq_unit', 'kJ/(kg*K)')
    set_param(block, 'T_liq', [varName '.liquid.T'])
    set_param(block, 'T_liq_unit', 'K')
    set_param(block, 'nu_liq', [varName '.liquid.nu'])
    set_param(block, 'nu_liq_unit', 'mm^2/s')
    set_param(block, 'k_liq', [varName '.liquid.k'])
    set_param(block, 'k_liq_unit', 'W/(m*K)')
    set_param(block, 'Pr_liq', [varName '.liquid.Pr'])
    set_param(block, 'Pr_liq_unit', '1')
    set_param(block, 'u_sat_liq', [varName '.liquid.u_sat'])
    set_param(block, 'u_sat_liq_unit', 'kJ/kg')
    set_param(block, 'unorm_vap', [varName '.vapor.unorm'])
    set_param(block, 'unorm_vap_unit', '1')
    set_param(block, 'v_vap', [varName '.vapor.v'])
    set_param(block, 'v_vap_unit', 'm^3/kg')
    set_param(block, 's_vap', [varName '.vapor.s'])
    set_param(block, 's_vap_unit', 'kJ/(kg*K)')
    set_param(block, 'T_vap', [varName '.vapor.T'])
    set_param(block, 'T_vap_unit', 'K')
    set_param(block, 'nu_vap', [varName '.vapor.nu'])
    set_param(block, 'nu_vap_unit', 'mm^2/s')
    set_param(block, 'k_vap', [varName '.vapor.k'])
    set_param(block, 'k_vap_unit', 'W/(m*K)')
    set_param(block, 'Pr_vap', [varName '.vapor.Pr'])
    set_param(block, 'Pr_vap_unit', '1')
    set_param(block, 'u_sat_vap', [varName '.vapor.u_sat'])
    set_param(block, 'u_sat_vap_unit', 'kJ/kg')
    
else
    error(message('physmod:simscape:utils:twoPhaseFluidTables:WrongNumberOfInputs'))
end

end


% Prepares either REFPROP or CoolProp to perform calculations for the
% specified substance
function [criticalTriplePressure, saturationProperties, fluidProperties, specificHeat, objCleanup] ...
    = initialize(installPath, substance)

refpropFile = 'REFPRP64.dll';
coolpropFile = ['CoolPropMATLAB_wrap.' mexext];

if isfolder(installPath)
    % Look for REFPROP DLL or CoolProp MEX in the folder
    if isfile(fullfile(installPath, refpropFile))
        [criticalTriplePressure, saturationProperties, fluidProperties, specificHeat, objCleanup] = ...
            refpropInitialize(installPath, substance);
    elseif isfile(fullfile(installPath, coolpropFile))
        [criticalTriplePressure, saturationProperties, fluidProperties, specificHeat, objCleanup] = ...
            coolpropMexInitialize(installPath, substance);
    else
        error(message('physmod:simscape:utils:twoPhaseFluidTables:FileOrFileNotFound', refpropFile, coolpropFile, installPath))
    end
else
    % Check for valid Python path
    pathSplit = split(installPath, '.');
    assert(numel(pathSplit) > 1 && all(~strcmp(pathSplit, '')), message('physmod:simscape:utils:twoPhaseFluidTables:MustBeDirectoryOrPath', installPath))
    assert(strcmp(pathSplit{1}, 'py'), message('physmod:simscape:utils:twoPhaseFluidTables:PathBeginAndEnd', installPath, 'py', 'PropsSI'))
    assert(strcmp(pathSplit{end}, 'PropsSI'), message('physmod:simscape:utils:twoPhaseFluidTables:PathBeginAndEnd', installPath, 'py', 'PropsSI'))
    [criticalTriplePressure, saturationProperties, fluidProperties, specificHeat, objCleanup] = ...
        coolpropPyInitialize(installPath, substance);
end

end


% Prepares REFPROP to perform calculations on the specified substance
function [criticalTriplePressure, saturationProperties, fluidProperties, specificHeat, objCleanup] ...
    = refpropInitialize(installPath, substance)

libName = 'refprop';
dllName = 'REFPRP64.dll';
prototype = @mw_rp_proto;
fluidDir = 'fluids';
mixDir = 'mixtures';

% Only supported on 64-bit Windows
assert(ispc, message('physmod:simscape:utils:twoPhaseFluidTables:UnsupportedPlatform'))

% Check fluids folder
fluidPath = fullfile(installPath, fluidDir);
assert(isfolder(fluidPath), ...
    message('physmod:simscape:utils:twoPhaseFluidTables:DirectoryNotFound', fluidPath))

% Check mixtures folder
mixPath = fullfile(installPath, mixDir);
assert(isfolder(mixPath), ...
    message('physmod:simscape:utils:twoPhaseFluidTables:DirectoryNotFound', mixPath))

% VirtualStore location
% If users create custom fluids or mixtures in the REFPROP GUI and saves
% them, Windows may redirect the saved file to the VirtualStore. This
% happens if users do not have write access to installPath.
virtualPath = fullfile(getenv('LocalAppData'), 'VirtualStore', installPath(3:end));
fluidPathVirtual = fullfile(virtualPath, fluidDir);
mixPathVirtual = fullfile(virtualPath, mixDir);

% Check substance in fluids folder
[~, ~, fluidExt] = fileparts(substance);
if strlength(fluidExt) == 0
    
    % Check VirtualStore location first
    % Warns if file found in both VirtualStore and installPath locations
    if isfile(fullfile(mixPathVirtual, [substance '.mix']))
        fluidFile = fullfile(mixPathVirtual, [substance '.mix']);
        mixFlag = true;
        if isfile(fullfile(mixPath, [substance '.mix']))
            warning(message('physmod:simscape:utils:twoPhaseFluidTables:FluidFileIn2Directories', ...
                fullfile(mixPathVirtual, [substance '.mix']), fullfile(mixPath, [substance '.mix'])))
        end
    elseif isfile(fullfile(fluidPathVirtual, [substance '.fld']))
        fluidFile = fullfile(fluidPathVirtual, [substance '.fld']);
        mixFlag = false;
        if isfile(fullfile(fluidPath, [substance '.fld']))
            warning(message('physmod:simscape:utils:twoPhaseFluidTables:FluidFileIn2Directories', ...
                fullfile(fluidPathVirtual, [substance '.fld']), fullfile(fluidPath, [substance '.fld'])))
        end
    elseif isfile(fullfile(fluidPathVirtual, [substance '.ppf']))
        fluidFile = fullfile(fluidPathVirtual, [substance '.ppf']);
        mixFlag = false;
        if isfile(fullfile(fluidPath, [substance '.ppf']))
            warning(message('physmod:simscape:utils:twoPhaseFluidTables:FluidFileIn2Directories', ...
                fullfile(fluidPathVirtual, [substance '.ppf']), fullfile(fluidPath, [substance '.ppf'])))
        end
        
        % Now check installPath location
    elseif isfile(fullfile(mixPath, [substance '.mix']))
        fluidFile = fullfile(mixPath, [substance '.mix']);
        mixFlag = true;
    elseif isfile(fullfile(fluidPath, [substance '.fld']))
        fluidFile = fullfile(fluidPath, [substance '.fld']);
        mixFlag = false;
    elseif isfile(fullfile(fluidPath, [substance '.ppf']))
        fluidFile = fullfile(fluidPath, [substance '.ppf']);
        mixFlag = false;
    else
        error(message('physmod:simscape:utils:twoPhaseFluidTables:FileNotFound2', substance, fluidPath, mixPath))
    end
    
elseif strcmpi(fluidExt, '.mix')
    
    % Check VirtualStore location first
    % Warns if file found in both VirtualStore and installPath locations
    if isfile(fullfile(mixPathVirtual, substance))
        fluidFile = fullfile(mixPathVirtual, substance);
        mixFlag = true;
        if isfile(fullfile(mixPath, substance))
            warning(message('physmod:simscape:utils:twoPhaseFluidTables:FluidFileIn2Directories', ...
                fullfile(mixPathVirtual, substance), fullfile(mixPath, substance)))
        end
    else
        % Now check installPath location
        assert(isfile(fullfile(mixPath, substance)), ...
            message('physmod:simscape:utils:twoPhaseFluidTables:FileNotFound', substance, mixPath))
        fluidFile = fullfile(mixPath, substance);
        mixFlag = true;
    end
    
else
    
    % Check VirtualStore location first
    % Warns if file found in both VirtualStore and installPath locations
    if isfile(fullfile(fluidPathVirtual, substance))
        fluidFile = fullfile(fluidPathVirtual, substance);
        mixFlag = false;
        if isfile(fullfile(fluidPath, substance))
            warning(message('physmod:simscape:utils:twoPhaseFluidTables:FluidFileIn2Directories', ...
                fullfile(fluidPathVirtual, substance), fullfile(fluidPath, substance)))
        end
    else
        % Now check installPath location
        assert(isfile(fullfile(fluidPath, substance)), ...
            message('physmod:simscape:utils:twoPhaseFluidTables:FileNotFound', substance, fluidPath))
        fluidFile = fullfile(fluidPath, substance);
        mixFlag = false;
    end
    
end

% Load the REFPROP shared library
refpropFinalize(libName)
loadlibrary(fullfile(installPath, dllName), prototype, 'alias', libName);
objCleanup = onCleanup(@() refpropFinalize(libName));

% Prepare REFPROP to perform calculations on the specified substance
assert(strlength(fluidFile) <= 1e4, ...
    message('physmod:simscape:utils:twoPhaseFluidTables:BufferOverflow', fluidFile, '1e4'))
hFluid = pad(fluidFile, 1e4);
mixFile   = fullfile(fluidPath, 'hmx.bnc');
assert(strlength(mixFile) <= 255, ...
    message('physmod:simscape:utils:twoPhaseFluidTables:BufferOverflow', mixFile, '255'))
hMix = pad(mixFile, 255);
hRef = 'DEF';
hErr = pad('', 255);
hMixNme = pad('', 1e4);
if ~mixFlag
    nc = 1;
    z = 1;
    [~, ~, ~, ~, iErr, errTxt] ...
        = calllib(libName, 'SETUPdll', nc, hFluid, hMix, hRef, 0, hErr, 1e4, 255, 3, 255);
else
    [~, ~, ~, nc, ~, z, iErr, errTxt] ...
        = calllib(libName, 'SETMIXdll', hFluid, hMix, hRef, 0, hMixNme, zeros(1,20), 0, hErr, 1e4, 255, 3, 1e4, 255);
    [~, ~, ~] ...
        = calllib(libName, 'SATSPLNdll', z, 0, hErr, 255);
end

if iErr ~= 0
    ME = MException(message('physmod:simscape:utils:twoPhaseFluidTables:FailedToInitialize', 'REFPROP', substance));
    errMsg = replace(char(errTxt(:)'), '\', '\\');
    if (strlength(errMsg) > 0) && ~all(errMsg == ' ')
        ME = addCause(ME, MException('physmod:simscape:utils:twoPhaseFluidTables:RefpropError', errMsg));
    end
    throw(ME)
end

% Obtain molar mass from REFPROP
[~, molw] = calllib(libName, 'WMOLdll', z, 0);
molw = molw*1e-3;

% Function to obtain critical and triple point pressure from REFPROP
criticalTriplePressure = @() refpropCriticalTriplePressure(libName, z, nc, molw);

% Function to obtain saturated fluid properties from REFPROP
saturationProperties = @(p, q) refpropSaturationProperties(p, q, libName, z, nc, molw);

% Function to obtain fluid properties from REFPROP
fluidProperties = @(p, u) refpropFluidProperties(p, u, libName, z, nc, molw);

% Function to obtain specific heat from REFPROP
specificHeat = @(p, u) refpropSpecificHeat(p, u, libName, z, nc, molw);

end


% Releases REFPROP
function refpropFinalize(libName)

if libisloaded(libName)
    unloadlibrary(libName)
end

end


% Calls REFPROP to obtain the critical and triple point
function [p_crit, u_crit, p_triple] = refpropCriticalTriplePressure(libName, z, nc, molw)

hErr = pad('', 255);

% Call REFPROP function to obtain critical pressure and triple point
% temperature
if nc == 1
    [~, ~, T_triple, ~, ~, p_crit, D_crit, ~, ~, ~, ~] ...
        = calllib(libName, 'INFOdll', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
else
    %     [~, ~, ~] ...
    %         = calllib(libName, 'SATSPLNdll', z, 0, hErr, 255);
    [~, ~, p_crit, D_crit, ~, ~] ...
        = calllib(libName, 'CRITPdll', z, 0, 0, 0, 0, hErr, 255);
    T_triple = -1;
end

% Call REFPROP function to obtain critical specific internal energy
[~, ~, ~, ~, ~, ~, ~, ~, ~, e_crit, ~, ~, ~, ~, ~, ~, ~] ...
    = calllib(libName, 'PDFLSHdll', p_crit, D_crit, z, 0, 0, 0, zeros(1,nc), zeros(1,nc), 0, 0, 0, 0, 0, 0, 0, 0, hErr, 255);

% Call REFPROP function to obtain minimum temperature
[~, ~, T_min_EOS, ~, ~, ~] = calllib(libName, 'LIMITSdll', 'EOS', z, 0, 0, 0, 0, 3);
[~, ~, T_min_ETA, ~, ~, ~] = calllib(libName, 'LIMITSdll', 'ETA', z, 0, 0, 0, 0, 3);
[~, ~, T_min_TCX, ~, ~, ~] = calllib(libName, 'LIMITSdll', 'TCX', z, 0, 0, 0, 0, 3);
T_triple = max([T_triple, T_min_EOS, T_min_ETA, T_min_TCX]);

% Call REFPROP function to obtain minimum pressure
[~, ~, ~, ~, p_triple, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, iErr, ~] ...
    = calllib(libName, 'TQFLSHdll', T_triple, 0, z, 2, 0, 0, 0, 0, zeros(1,nc), zeros(1,nc), 0, 0, 0, 0, 0, 0, 0, hErr, 255);

if iErr ~= 0
    p_triple = 0;
end

% Calculate fluid properties
p_triple = p_triple    * 1e-3; % MPa
p_crit   = p_crit      * 1e-3; % MPa
u_crit   = e_crit/molw * 1e-3; % kJ/kg

end


% Calls REFPROP to obtain saturated fluid properties at pressure p [MPa].
% Specify q = 0 for saturated liquid or q = 1 for saturated vapor.
function [u, v, s, T, nu, k, Pr] = refpropSaturationProperties(p, q, libName, z, nc, molw)

hErr = pad('', 255);

% Call REFPROP function to obtain fluid properties
[~, ~, ~, ~, T, D, ~, ~, ~, ~, e, ~, s, ~, cp, ~, iErr, errTxt] ...
    = calllib(libName, 'PQFLSHdll', p*1e3, q, z, 2, 0, 0, 0, 0, zeros(1,nc), zeros(1,nc), 0, 0, 0, 0, 0, 0, 0, hErr, 255);

if iErr ~= 0
    errInfo = ['P = ' num2str(p) ' MPa, Q = ' num2str(q)];
    ME = MException(message('physmod:simscape:utils:twoPhaseFluidTables:FailedFluidProperties', 'REFPROP', errInfo));
    errMsg = replace(char(errTxt(:)'), '\', '\\');
    if (strlength(errMsg) > 0) && ~all(errMsg == ' ')
        ME = addCause(ME, MException('physmod:simscape:utils:twoPhaseFluidTables:RefpropError', errMsg));
    end
    throw(ME)
end

% Call REFPROP function to obtain transport properties
assert((q <= 0) || (q >= 1), ...
    message('physmod:simscape:utils:twoPhaseFluidTables:TransportPropertiesUnavailable'))
[~, ~, ~, eta, tcx, iErr, errTxt] = calllib(libName, 'TRNPRPdll', T, D, z, 0, 0, 0, hErr, 255);

if iErr ~= 0
    errInfo = ['P = ' num2str(p) ' MPa, Q = ' num2str(q)];
    ME = MException(message('physmod:simscape:utils:twoPhaseFluidTables:FailedFluidProperties', 'REFPROP', errInfo));
    errMsg = replace(char(errTxt(:)'), '\', '\\');
    if (strlength(errMsg) > 0) && ~all(errMsg == ' ')
        ME = addCause(ME, MException('physmod:simscape:utils:twoPhaseFluidTables:RefpropError', errMsg));
    end
    throw(ME)
end

% Calculate fluid properties
u   = e/molw * 1e-3;             % kJ/kg
v   = 1/(D*1e3*molw);            % m^3/kg
s   = s/molw * 1e-3;             % kJ/(kg*K)
% T                              % K
nu  = eta/D/molw/100/1000 * 1e2; % mm^2/s
k   = tcx;                       % W/(m*K)
Pr  = eta*cp/tcx/molw/1000/1000; % --

end


% Calls REFPROP to obtain fluid properties at the pressure p [MPa] and
% specific internal energy u [kJ/kg].
function [v, s, T, nu, k, Pr] = refpropFluidProperties(p, u, libName, z, nc, molw)

hErr = pad('', 255);

% Call REFPROP function to obtain fluid properties
[~, ~, ~, T, D, ~, ~, ~, ~, q, ~, s, ~, cp, ~, iErr, errTxt] ...
    = calllib(libName, 'PEFLSHdll', p*1e3, u*molw*1e3, z, 0, 0, 0, 0, zeros(1,nc), zeros(1,nc), 0, 0, 0, 0, 0, 0, 0, hErr, 255);

if iErr ~= 0
    errInfo = ['P = ' num2str(p) ' MPa and U = ' num2str(u) ' kJ/kg'];
    ME = MException(message('physmod:simscape:utils:twoPhaseFluidTables:FailedFluidProperties', 'REFPROP', errInfo));
    errMsg = replace(char(errTxt(:)'), '\', '\\');
    if (strlength(errMsg) > 0) && ~all(errMsg == ' ')
        ME = addCause(ME, MException('physmod:simscape:utils:twoPhaseFluidTables:RefpropError', errMsg));
    end
    throw(ME)
end

if (q > 0) && (q < 1)
    errInfo = ['P = ' num2str(p) ' MPa and U = ' num2str(u) ' kJ/kg'];
    ME = MException(message('physmod:simscape:utils:twoPhaseFluidTables:FailedFluidProperties', 'REFPROP', errInfo));
    ME = addCause(ME, MException(message('physmod:simscape:utils:twoPhaseFluidTables:TransportPropertiesUnavailable')));
    throw(ME)
end

% Call REFPROP function to obtain transport properties
[~, ~, ~, eta, tcx, iErr, errTxt] = calllib(libName, 'TRNPRPdll', T, D, z, 0, 0, 0, hErr, 255);

if iErr ~= 0
    errInfo = ['P = ' num2str(p) ' MPa and U = ' num2str(u) ' kJ/kg'];
    ME = MException(message('physmod:simscape:utils:twoPhaseFluidTables:FailedFluidProperties', 'REFPROP', errInfo));
    errMsg = replace(char(errTxt(:)'), '\', '\\');
    if (strlength(errMsg) > 0) && ~all(errMsg == ' ')
        ME = addCause(ME, MException('physmod:simscape:utils:twoPhaseFluidTables:RefpropError', errMsg));
    end
    throw(ME)
end

% Calculate desired fluid properties
v   = 1/(D*1e3*molw);            % m^3/kg
s   = s/molw * 1e-3;             % kJ/(kg*K)
% T                              % K
nu  = eta/D/molw/100/1000 * 1e2; % mm^2/s
k   = tcx;                       % W/(m*K)
Pr  = eta*cp/tcx/molw/1000/1000; % --

end


% Calls REFPROP to obtain specific heat at constant pressure at the
% pressure p [MPa] and specific internal energy u [kJ/kg].
function cp = refpropSpecificHeat(p, u, libName, z, nc, molw)

hErr = pad('', 255);

% Call REFPROP function to obtain fluid properties
[~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, cp, ~, iErr, errTxt] ...
    = calllib(libName, 'PEFLSHdll', p*1e3, u*molw*1e3, z, 0, 0, 0, 0, zeros(1,nc), zeros(1,nc), 0, 0, 0, 0, 0, 0, 0, hErr, 255);

if iErr ~= 0
    errInfo = ['P = ' num2str(p) ' MPa and U = ' num2str(u) ' kJ/kg'];
    ME = MException(message('physmod:simscape:utils:twoPhaseFluidTables:FailedFluidProperties', 'REFPROP', errInfo));
    errMsg = replace(char(errTxt(:)'), '\', '\\');
    if (strlength(errMsg) > 0) && ~all(errMsg == ' ')
        ME = addCause(ME, MException('physmod:simscape:utils:twoPhaseFluidTables:RefpropError', errMsg));
    end
    throw(ME)
end

cp = cp/molw * 1e-3; % kJ/(kg*K)

end


% Prepares CoolProp MEX interface to perform calculations on the specified substance
function [criticalTriplePressure, saturationProperties, fluidProperties, specificHeat, objCleanup] ...
    = coolpropMexInitialize(installPath, substance)

% Change to CoolProp directory
currentPath = pwd;
objCleanup = onCleanup(@() cd(currentPath));
cd(installPath)

% Check for CoolProp package function
assert(isfile(fullfile('+CoolProp', 'PropsSI.m')), ...
    message('physmod:simscape:utils:twoPhaseFluidTables:FileNotFound', ...
    fullfile('+CoolProp', 'PropsSI.m'), installPath))

% Check if substance is valid by attempting to obtain molar mass
coolpropFun = @CoolProp.PropsSI;
try
    [~] = coolpropFun('M', 'P', 0, 'T', 0, substance);
catch errCoolProp
    ME = MException(message('physmod:simscape:utils:twoPhaseFluidTables:FailedToInitialize', 'CoolProp', substance));
    ME = addCause(ME, errCoolProp);
    throw(ME)
end

% Function to obtain critical and triple point pressure from CoolProp
criticalTriplePressure = @() coolpropCriticalTriplePressure(substance, coolpropFun);

% Function to obtain saturated fluid properties from CoolProp
saturationProperties = @(p, q) coolpropSaturationProperties(p, q, substance, coolpropFun);

% Function to obtain fluid properties from CoolProp
fluidProperties = @(p, u) coolpropFluidProperties(p, u, substance, coolpropFun);

% Function to obtain specific heat from CoolProp
specificHeat = @(p, u) coolpropFun('C', 'P', p*1e6, 'U', u*1e3, substance)*1e-3;

end


% Prepares CoolProp Python interface to perform calculations on the specified substance
function [criticalTriplePressure, saturationProperties, fluidProperties, specificHeat, objCleanup] ...
    = coolpropPyInitialize(installPath, substance)

objCleanup = [];

% Check Python availability
assert(~isempty(pyversion), message('physmod:simscape:utils:twoPhaseFluidTables:CannotLocatePython'))

% Check that installPath is a valid path to CoolProp Python package
% Also check if substance is valid by attempting to obtain molar mass
coolpropFun = str2func(installPath);
try
    [~] = coolpropFun('M', 'P', 0, 'T', 0, substance);
catch errCoolProp
    if isa(errCoolProp, 'matlab.exception.PyException')
        ME = MException(message('physmod:simscape:utils:twoPhaseFluidTables:FailedToInitialize', 'CoolProp', substance));
        ME = addCause(ME, errCoolProp);
        throw(ME)
    elseif strcmp(errCoolProp.identifier, 'MATLAB:UndefinedFunction') ...
            || strcmp(errCoolProp.identifier, 'MATLAB:undefinedVarOrClass')
        error(message('physmod:simscape:utils:twoPhaseFluidTables:CannotLocatePackage', installPath))
    else
        rethrow(errCoolProp)
    end
end

% Function to obtain critical and triple point pressure from CoolProp
criticalTriplePressure = @() coolpropCriticalTriplePressure(substance, coolpropFun);

% Function to obtain saturated fluid properties from CoolProp
saturationProperties = @(p, q) coolpropSaturationProperties(p, q, substance, coolpropFun);

% Function to obtain fluid properties from CoolProp
fluidProperties = @(p, u) coolpropFluidProperties(p, u, substance, coolpropFun);

% Function to obtain specific heat from CoolProp
specificHeat = @(p, u) coolpropFun('C', 'P', p*1e6, 'U', u*1e3, substance)*1e-3;

end


% Calls CoolProp to obtain the critical and triple point
function [p_crit, u_crit, p_triple] = coolpropCriticalTriplePressure(substance, coolpropFun)

p_crit = coolpropFun('PCRIT', 'P', 0, 'T', 0, substance);

try
    % Try to compute critical specific internal energy from quality
    u_crit1 = coolpropFun('U', 'P', p_crit, 'Q', 0, substance);
    u_crit2 = coolpropFun('U', 'P', p_crit, 'Q', 1, substance);
    u_crit = (u_crit1 + u_crit2)/2;
catch
    % Try to compute critical specific internal energy from critical
    % density
    rho_crit = coolpropFun('RHOCRIT', 'P', 0, 'T', 0, substance);
    u_crit = coolpropFun('U', 'P', p_crit, 'D', rho_crit, substance);
end

T_triple = coolpropFun('TTRIPLE', 'P', 0, 'T', 0, substance);

T_min = coolpropFun('TMIN', 'P', 0, 'T', 0, substance);
if T_min > T_triple
    T_triple = T_min;
end

try
    p_triple = coolpropFun('P', 'T', T_triple, 'Q', 0, substance);
catch
    p_triple = 0;
end

if isinf(p_triple)
    p_triple = 0;
end

% Unit conversions
p_triple = p_triple * 1e-6; % MPa
p_crit   = p_crit   * 1e-6; % MPa
u_crit   = u_crit   * 1e-3; % kJ/kg

end


% Calls CoolProp to obtain saturated fluid properties at pressure p [MPa].
% Specify q = 0 for saturated liquid or q = 1 for saturated vapor.
function [u, v, s, T, nu, k, Pr] = coolpropSaturationProperties(p, q, substance, coolpropFun)

p_Pa = p*1e6;

errInfo = ['P = ' num2str(p) ' MPa, Q = ' num2str(q)];

p_Pa = p_Pa + 1e-6;

% Call CoolProp function to obtain fluid properties
try
    u   = coolpropFun('U', 'P', p_Pa, 'Q', q, substance);
    rho = coolpropFun('D', 'P', p_Pa, 'Q', q, substance);
    s   = coolpropFun('S', 'P', p_Pa, 'Q', q, substance);
    T   = coolpropFun('T', 'P', p_Pa, 'Q', q, substance);
    mu = coolpropFun("V", "P", p_Pa, "Q", q, substance);
    k  = coolpropFun("L", "P", p_Pa, "Q", q, substance);
    Cp = coolpropFun('Cpmass', 'P', p_Pa, 'Q', q, substance);
    Pr = (Cp * mu) / k; %Using Prandtl number = (Cp * dynamic viscosity) / thermal conductivity = (Cp*mu)/k
    
catch errCoolProp
    disp(getReport(errCoolProp,'extended'));
    ME = MException(message('physmod:simscape:utils:twoPhaseFluidTables:FailedFluidProperties', 'CoolProp', errInfo));
    ME = addCause(ME, errCoolProp);
    throw(ME)
end

assert(all(isfinite([u rho s T mu k Pr])), ...
    message('physmod:simscape:utils:twoPhaseFluidTables:FailedFluidProperties', 'CoolProp', errInfo))

% Unit conversions
u  = u * 1e-3;     % kJ/kg
v  = 1/rho;        % m^3/kg
s  = s * 1e-3;     % kJ/(kg*K)
% T                % K
nu = mu/rho * 1e6; % mm^2/s
% k                % W/(m*K)
% Pr               % --

end


% Calls CoolProp to obtain fluid properties at the pressure p [MPa] and
% specific internal energy u [kJ/kg].
function [v, s, T, nu, k, Pr] = coolpropFluidProperties(p, u, substance, coolpropFun)

p_Pa = p*1e6;
u_Jkg = u*1e3;

% errInfo = ['P = ' num2str(p) ' MPa, U = ' num2str(u) ' kJ/kg, T = ' num2str(T) " K"];
errInfo = ['P = ' num2str(p) ' MPa, U = ' num2str(u) ' kJ/kg'];

% Call CoolProp function to obtain fluid properties
try
    rho = coolpropFun('D', 'P', p_Pa, 'U', u_Jkg, substance);
    s   = coolpropFun('S', 'P', p_Pa, 'U', u_Jkg, substance);
    T   = coolpropFun('T', 'P', p_Pa, 'U', u_Jkg, substance);
    mu  = coolpropFun('V', 'P', p_Pa, 'U', u_Jkg, substance);
    k   = coolpropFun('L', 'P', p_Pa, 'U', u_Jkg, substance);
    Pr  = coolpropFun('PRANDTL', 'P', p_Pa, 'U', u_Jkg, substance);

catch errCoolProp
    try 
        clear errCoolProp
        T = fsolve(@solveTfromU, 170);
        uSol = coolpropFun('U', 'P', p_Pa, 'T', T, substance);
        tempUT = [];
        tempUP = [];
        Tspan = linspace(100,220,1e3);
        Pspan = linspace(8e4,5e5,1e3);
        for i = Tspan tempUT(end+1) = coolpropFun("U", 'P', p_Pa, 'T', i, substance); end
        for i = Pspan
            tempUP(end+1) = coolpropFun("U", 'P', i, 'T', T, substance);
        end
        figure(1)
        hold on
        xlabel("T")
        ylabel("U")
        plot(Tspan,tempUT)
        plot(T,u_Jkg,"r*")
        hold off
        figure(2)
        hold on
        xlabel("P")
        ylabel("U")
        plot(Pspan,tempUP)
        plot(p_Pa,u_Jkg,"r*")
        hold off
        rho = coolpropFun('D', 'P', p_Pa, 'T', T, substance);
        s   = coolpropFun('S', 'P', p_Pa, 'T', T, substance);
        mu  = coolpropFun('V', 'P', p_Pa, 'T', T, substance);
        k   = coolpropFun('L', 'P', p_Pa, 'T', T, substance);
        Pr  = coolpropFun('PRANDTL', 'P', p_Pa, 'T', T, substance);
    catch errCoolProp
        disp(getReport(errCoolProp,'extended'));
    %     ME = MException(message('physmod:simscape:utils:twoPhaseFluidTables:FailedFluidProperties', 'CoolProp', errInfo));
    %     ME = addCause(ME, errCoolProp);
    %     throw(ME)
    %     disp(errInfo)
    %     error("error prop det")
        rho = 1e-12;
        s = 1e-12;
        mu = 1e-12;
        k = 1e-12;
    %     Cp = 1e-12;
        Pr = 1e-12;
        T = 1e-12;
    end
end

assert(all(isfinite([rho s T mu k Pr])), ...
      errInfo)
%     message('physmod:simscape:utils:twoPhaseFluidTables:FailedFluidProperties', 'CoolProp', errInfo))

% Unit conversions
v  = 1/rho;        % m^3/kg
s  = s * 1e-3;     % kJ/(kg*K)
% T                % K
nu = mu/rho * 1e6; % mm^2/s
% if nu > 10
%     pass
% end
% k                % W/(m*K)
% Pr               % --

function err = solveTfromU(TGuess)
% uses fsolve to find T at for a given U, as coolprop refuses to allow
% extrapolation using U as a term

uIter = py.CoolProp.CoolProp.PropsSI("U","T",TGuess,"P",p_Pa,substance);

err = u_Jkg - uIter;
end
end
