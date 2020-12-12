function T = tempFromPressure(P)
%takes P in Pa
%valid from -90.85 to 36.42 (triple point -> critical point)    
%antoine equation coefficients from Yaws handbook
A = 6.81488;
B = 550.604;
C = 228.438;
P = P/133.3; %Pa to mmHg
T = B/(A - log10(P)) - C;
end