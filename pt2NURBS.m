function [ t, d ] = pt2NURBS(pt, crv, x0)
% Simple function computing the parameter value t corresponding to the
% closest point of the NURBS curve crv to the given point 2d pt. The actual
% distance |crv(t)-pt|^2=d is also computed. x0 is a estimation of t's
% value
d=Inf;
t=Inf;
%options = optimoptions(@fmincon,'Display','off');
%t = fmincon(@f,x0,[],[],[],[],crv.knots(1),crv.knots(end),[],options);
a = x0-0.25;
if (a<0) 
    a=0;
end
b = x0+0.25;
if (b>1) 
    b=1;
end
t = fminbnd(@f,a,b);    
%d=sqrt(f(t));
d = f(t);
function y = f(x)
 val = nrbeval(crv,x);
 y = (pt(1)-val(1)).^2+(pt(2)-val(2)).^2;
end
end