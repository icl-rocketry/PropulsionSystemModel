function angles = getPossibleAnglesOfLeftLinkageDegrees(g, b, a, h, angleOfRightLinkageDegrees)
%Use the mirror image of this four bar linkage to determine
angleOfRightLinkageDegrees2 = 180-angleOfRightLinkageDegrees;
roots = Mechanical.FourBarLinkage.getPossibleAnglesOfRightLinkageDegrees(g, a, b, h, angleOfRightLinkageDegrees2);
angles(1) = clampDeg(180-roots(1));
angles(2) = clampDeg(180-roots(2));

    function angle = clampDeg(angle)
        while (angle < 0)
            angle = angle + 360;
        end
        while (angle > 360)
            angle = angle - 360;
        end
    end
end