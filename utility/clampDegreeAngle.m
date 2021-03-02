function angle = clampDegreeAngle(angle)
while (angle < 0)
    angle = angle + 360;
end
while (angle >= 360)
    angle = angle - 360;
end
end