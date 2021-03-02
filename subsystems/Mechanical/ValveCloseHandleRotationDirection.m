classdef ValveCloseHandleRotationDirection < Simulink.IntEnumType
   enumeration
       TOWARDS_SERVO(0)
       AWAY_FROM_SERVO(1)
   end
   
   methods (Static = true)
    function retVal = getDefaultValue()
      retVal = ValveCloseHandleRotationDirection.TOWARDS_SERVO;
    end
    
   end
end