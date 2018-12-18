function b = winsorize(a, q, flag)

%flag is 0 for low end only, 1 for high end only, 2 for both tails

if flag == 2 q = q/2; end

b = a; 

qhigh = quantile(a, 1 - q);
qlow = quantile(a, q);

if flag > 0 b(a > qhigh) = qhigh; end
if flag ~= 1 b(a < qlow) = qlow; end