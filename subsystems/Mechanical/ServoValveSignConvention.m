classdef ServoValveSignConvention < Simulink.IntEnumType
   enumeration
       POSITIVE_AWAY_FROM_VALVE(0) %Servo turns away from the valve when you increase it's angle (that is sent to it)
       POSITIVE_TOWARDS_VALVE(1) %Servo turns towards from the valve when you increase it's angle (that is sent to it)
   end
   
   methods (Static = true)
    function retVal = getDefaultValue()
      retVal = ServoValveSignConvention.POSITIVE_AWAY_FROM_VALVE;
    end
    
   end
end