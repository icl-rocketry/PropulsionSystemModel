%Equations:
%https://drive.google.com/file/d/1_zj3OY_a849cnpBU75GDf2Nkq8yYU9WD/view?usp=sharing
%       g; %Distance between pivots
%       b; %Length of bar connected to right pivot
%       a; %Length of bar connected to left pivot
%       h; %Length of bar connecting the other two bars
function angles = getPossibleAnglesOfRightLinkageDegrees(g, b, a, h, angleOfLeftLinkageDegrees)
theta = deg2rad(angleOfLeftLinkageDegrees);
A = getACoefficient(theta);
B = getBCoefficient(theta);
C = getCCoefficient(theta);
%As defined in paper
delta = atan2(B,A);
psi1 = delta + acos(-C./sqrt(A.^2 + B.^2));
psi2 = delta - acos(-C./sqrt(A.^2 + B.^2));
angles = [clampDeg(rad2deg(psi1)),clampDeg(rad2deg(psi2))];


%Coefficient A as defined in paper
    function A = getACoefficient(thetaRad)
        A = 2.*b.*g - 2.*a.*b.*cos(thetaRad);
    end

%Coefficient B as defined in paper
    function B = getBCoefficient(thetaRad)
        B = -2.*a.*b.*sin(thetaRad);
    end

%Coefficient C as defined in paper
    function C = getCCoefficient(thetaRad)
        C = a.^2 + b.^2 + g.^2 - h.^2 - 2.*a.*g.*cos(thetaRad);
    end

    function angle = clampDeg(angle)
        while (angle < 0)
            angle = angle + 360;
        end
        while (angle > 360)
            angle = angle - 360;
        end
    end

end