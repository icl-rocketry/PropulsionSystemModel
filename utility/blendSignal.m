function y = blendSignal(y1,y2,x1,x2,x)
% y = blend(y1,y2,x1,x2,x)
% Blend between two values y1 and y2 as x varies between x1 and x2. The
% blending function ensures y is continuous and differentiable in the
% range x1 <= x <= x2.
u = (x-x1)/(x2-x1);
transition = 3*u^2 - 2*u^3;
if x<= x1
    y = y1;
elseif x>= x2
    y = y2;
else
    y = (1-transition)*y1 + transition*y2;
end

end