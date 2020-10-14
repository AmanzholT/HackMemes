function [obj_val, max_val, min_val, x] = objective_modified(filename, crv)
fp = load(filename);
n=length(fp);
d=zeros(1,n);
for i=1:n
    [ t, d(i) ] = pt2NURBS(fp(i,:), crv, i/n);
    p = nrbeval(crv,t);
    if p(1)<0.2 
        d(i) = 2*d(i);
    end
end
obj_val = sum(d);
[max_d, ix] = max(d);
max_val = sqrt(max_d);
x = fp(ix,1);
min_val = sqrt(min(d));
end
