clear
nitrousFluidTable = getNitrousFluidTable();
nitrousTankVolume = 0.8*(0.25*pi*(150e-3).^2); %m^3
injectorSingleHoleA = 0.25*pi*(1.5e-3)^2; %m^2
feedSystemStartPressure = 59.99e5;
nominalFeedSysPipeDiam = 7e-3;
tankInletA = 0.25*pi*(11e-2)^2;%m^2; Area used after injector for modelled reservoir (Shouldn't matter)
nominalFeedSysPipeCrossSection = 0.25*pi*(nominalFeedSysPipeDiam)^2;