classdef NistCO2
    methods (Static,Access=private) %Static private methods: Methods that don't need object instance that can't be called remotely
              
        %Function to read contents of file, ignoring the first 2 lines, that contains 4 columns and then put into matrix and then
        %return. Implements a cache internally for much faster execution
        %speeds when repeated calls are necessary
        function data = getDataFromFile(fName,numCols)
           persistent cachedData; %Map that caches contents read from files, to speed up execution massively
           if isempty(cachedData) %If variable not initialized
               cachedData = containers.Map('KeyType','char','ValueType','any'); %Initialize it to our map
           end
           if ~exist('numCols','var')
               numCols = 3; 
           end
           if ~isKey(cachedData,fName) %If map does not contain the contents of the file
               if(endsWith(fName,'.mat'))
                   fileData = load(fName);
                   cachedData(fName) = fileData.data;
                   data = fileData.data;
                   return;
               end
               
               %Load data from the file and put into map
               fileHandle = fopen(fName,'r'); %Open file with read perms
               
               fileData = zeros(1,numCols);
               fgetl(fileHandle); %Ignore first line
               fgetl(fileHandle); %Ignore second line
               lineNum = 1;
               %Regex (.+?)\s(.+?)\s(.+?)\s(.+?) for parsing columns,
               %lookup regular expressions in programming if not sure
               %what this is
               regex = '(.+?)';
               for j=1:numCols-1
                   regex = [regex,'\s+(.+'];
                   if(j ~= numCols-1)
                       regex = [regex,'?)'];
                   else
                       regex = [regex,')'];
                   end
               end
               while true %Until loop breaks
                   lineRead = fgetl(fileHandle); %Read next line from file
                   if ~ischar(lineRead) %If this line does not exist (reached end of file)
                       break; %Exit loop
                   end
                   
                   tokens = regexp(lineRead,regex,'tokens'); %Capture groups from the regex as an array
                   for i=1:numCols %For each col, 1 to 4
                        %Put into matrix the numeric value captured by this
                        %token
                        fileData(lineNum,i) = str2double(tokens{1}{i});
%                         if isnan(fileData(lineNum,i))
%                            disp(tokens{1}{i});
%                         end
                   end
                   lineNum = lineNum+1;
               end
               fclose(fileHandle);
               cachedData(fName) = fileData;
           end
           data = cachedData(fName); %Data is what we loaded from this file
        end
        
        function [Xq,Yq,Zq] = genGridDataFromScattered(x,y,z,xStep,yStep)
            [Xq,Yq] = meshgrid(min(x):xStep:max(x), min(y):yStep:max(y));
            Zq = griddata(x,y,z,Xq,Yq,"v4");
        end
        
        function val = interpScattered2DFromGrid(Xq,Yq,Zq,xq,yq)
            try
                val = interp2(Xq,Yq,Zq,xq,yq,"spline");
            catch
                val = interp2(Xq,Yq,Zq,xq,yq);
            end
        end
        
        function val = interpScattered2D(x,y,z,xStep,yStep,xq,yq)
            [Xq,Yq,Zq] = CO2FluidProps.NistCO2.genGridDataFromScattered(x,y,z,xStep,yStep);
            val = CO2FluidProps.NistCO2.interpScattered2DFromGrid(Xq,Yq,Zq,xq,yq);
        end
    end
    
    methods (Static)
        
        function val = getIdealGasCp(T)
            data = CO2FluidProps.NistCO2...
                .getDataFromFile(['+CO2FluidProps',filesep,'rawData',filesep,'idealGasCp.txt']);
            val = interp1(data(:,1),data(:,2),T);
            
            if isnan(val)
                error("probably extrapolating outside of data range");
            end
        end
        
        % Function to return enthalpy of an ideal gas (J/mol)
        function val = getIdealGasEnthalpy(T)
            data = CO2FluidProps.NistCO2...
                .getDataFromFile(['+CO2FluidProps',filesep,'rawData',filesep,'idealGasEnthalpy.txt']);
            val = interp1(data(:,1),data(:,2),T);
            val = val*1e3; % changes to J/mol
%             val = val - 8.4584e+03 + 18963.53; %+ 200e3*44.01e-3; % changes to IIR reference state (200 kJ/kg @ 0C)
            if isnan(val)
                error("probably extrapolating outside of data range");
            end
        end
        
        function val = getIdealGasSVPressure(T)
            data = CO2FluidProps.NistCO2...
                .getDataFromFile(['+CO2FluidProps',filesep,'rawData',filesep,'SVBoundaryP.txt']);
            val = interp1(data(:,1),data(:,2),T,"pchip");
            val = val*1e3;
            if isnan(val)
                error("probably extrapolating outside of data range");
            end
        end
        
        function val = getIdealGasLVPressure(T)
            data = CO2FluidProps.NistCO2...
                .getDataFromFile(['+CO2FluidProps',filesep,'rawData',filesep,'LVBoundaryP.txt']);
            val = interp1(data(:,1),data(:,2),T,"pchip");
            val = val*1e3;
            if isnan(val)
                error("probably extrapolating outside of data range");
            end
        end
    end
end