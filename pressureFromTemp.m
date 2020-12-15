function P = pressureFromTemp(T)
%takes T in deg C
%valid from -90.85 to 36.42 (triple point -> critical point)    
%antoine equation coefficients from Yaws handbook
A = 6.81488;
B = 550.604;
C = 228.438;
P = 10^(A - B/(C+T));
P = P*133.3; %mmHg to Pa
end