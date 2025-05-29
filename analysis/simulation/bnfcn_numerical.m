% Finds simultaneous Bertrand Nash solution numerically

function pstar_sbn = bnfcn_numerical(param,startval)

options = optimoptions('fsolve','Display','off','TolFun',1e-15,'TolX',1e-15,'OptimalityTolerance',1e-15,'Algorithm','levenberg-marquardt','MaxFunEvals',100000);
fun = @(p)bnfcn_numerical_sub(p,param,startval);
pstar_sbn = fsolve(fun,startval,options);

end

