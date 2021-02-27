classdef NistNitrous
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
               numCols = 4; 
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
        
        function val = interpScattered2D(x,y,z,xStep,yStep,xq,yq)
            [Xq,Yq] = meshgrid(min(x):xStep:max(x), min(y):yStep:max(y));
            Zq = griddata(x,y,z,Xq,Yq);
            try
                val = interp2(Xq,Yq,Zq,xq,yq,'spline');
            catch
                val = interp2(Xq,Yq,Zq,xq,yq);
            end
        end
    end
    
    methods (Static)
        
        %Function to get the thermal conductivity (W/m/K) for the gas
        %at a given Temp (K) and Pressure (Pa)
        function val = getGasThermalConductivity(T,P)
            P1 = P/1000; %Need gas in kPa using tabulated data
            data = NitrousFluidProps.NistNitrous...
                .getDataFromFile(['+NitrousFluidProps',filesep,'rawData',filesep,'gasThermalConductivity.txt']); 
            val = NitrousFluidProps.NistNitrous.interpScattered2D(...
                data(:,1),data(:,2),data(:,3),1,200,T,P1);
            if isnan(val)
                warning('Interpolating outside of dataset');
                val = NitrousFluidProps.fallbackInterp2D(data,T,P1);
            end
            val = val/1000; %Convert to 1/Pa
        end
        
        %Function to get the thermal conductivity (W/m/K) for the liquid
        %at a given Temp (K) and Pressure (Pa)
        function val = getLiquidThermalConductivity(T,P)
            P1 = P/1000; %Need gas in kPa using tabulated data
            data = NitrousFluidProps.NistNitrous...
                .getDataFromFile(['+NitrousFluidProps',filesep,'rawData',filesep,'liquidThermalConductivity.txt']); 
            val = NitrousFluidProps.NistNitrous.interpScattered2D(...
                data(:,1),data(:,2),data(:,3),1,200,T,P1);
            if isnan(val)
                warning('Interpolating outside of dataset');
                val = NitrousFluidProps.fallbackInterp2D(data,T,P1);
            end
            val = val/1000; %Convert to 1/Pa
        end
        
        %Function to get the dynamic viscosity (Pa s) for the gas
        %at a given Temp (K) and Pressure (Pa)
        function val = getGasViscosity(T,P)
            P1 = P/1000; %Need gas in kPa using tabulated data
            data = NitrousFluidProps.NistNitrous...
                .getDataFromFile(['+NitrousFluidProps',filesep,'rawData',filesep,'gasViscosity.txt']); 
            val = NitrousFluidProps.NistNitrous.interpScattered2D(...
                data(:,1),data(:,2),data(:,3),1,200,T,P1);
            if isnan(val)
                warning('Interpolating outside of dataset');
                val = NitrousFluidProps.fallbackInterp2D(data,T,P1);
            end
            val = val/1000; %Convert to 1/Pa
        end
        
        %Function to get the dynamic viscosity (Pa s) for the liquid
        %at a given Temp (K) and Pressure (Pa)
        function val = getLiquidViscosity(T,P)
            P1 = P/1000; %Need gas in kPa using tabulated data
            data = NitrousFluidProps.NistNitrous...
                .getDataFromFile(['+NitrousFluidProps',filesep,'rawData',filesep,'liquidViscosity.txt']); 
            val = NitrousFluidProps.NistNitrous.interpScattered2D(...
                data(:,1),data(:,2),data(:,3),1,200,T,P1);
            if isnan(val)
                warning('Interpolating outside of dataset');
                val = NitrousFluidProps.fallbackInterp2D(data,T,P1);
            end
            val = val/1000; %Convert to 1/Pa
        end
        
        %Function to get the isobaric expansion constant (1/K) for the gas
        %at a given temp (K) and Pressure (Pa)
        function val = getGasIsobaricExpansion(T,P)
            P1 = P/1000; %Need gas in kPa using tabulated data
            data = NitrousFluidProps.NistNitrous...
                .getDataFromFile(['+NitrousFluidProps',filesep,'rawData',filesep,'gasIsobaricExpansion.txt']); 
            val = NitrousFluidProps.NistNitrous.interpScattered2D(...
                data(:,1),data(:,2),data(:,3),1,200,T,P1);
            if isnan(val)
                warning('Interpolating outside of dataset');
                val = NitrousFluidProps.fallbackInterp2D(data,T,P1);
            end
        end
        
        %Function to get the isobaric expansion constant (1/K) for the
        %liquid at a given temp (K) and Pressure (Pa)
        function val = getLiquidIsobaricExpansion(T,P)
            P1 = P/1000; %Need gas in kPa using tabulated data
            data = NitrousFluidProps.NistNitrous...
                .getDataFromFile(['+NitrousFluidProps',filesep,'rawData',filesep,'liquidIsobaricExpansion.txt']); 
            val = NitrousFluidProps.NistNitrous.interpScattered2D(...
                data(:,1),data(:,2),data(:,3),1,200,T,P1);
            if isnan(val)
                warning('Interpolating outside of dataset');
                val = NitrousFluidProps.fallbackInterp2D(data,T,P1);
            end
        end
    end
end