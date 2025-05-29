
function [pi,share,quant,cs,ps] = calc_bn_eqm(param,pstar)


% Params
run('set_parameters.m')

% Contested segments
conF = @(alphai, alphaj, pi, pj) max(min(1/2 + 1/(2*tau)*((alphai - pi) - (alphaj - pj)), 1),0);

% Uncontested segments
unconF = @(alphai, alphaj, pi, pj) max(1/tau*((alphai - pi)),0);


s1 = @(p1,p2,p3,p4,p5) (mu10*unconF(alpha1, alpha0, p1, 0) + mu11*conF(alpha1, alpha1, p1, p1) + mu12*conF(alpha1, alpha1, p1, p2) + mu13*conF(alpha1, alpha1, p1, p3) + mu14*conF(alpha1, alpha1, p1, p4) + mu15*conF(alpha1, alpha1, p1, p5));
s2 = @(p1,p2,p3,p4,p5) (mu20*unconF(alpha1, alpha0, p2, 0) + mu21*conF(alpha1, alpha1, p2, p1) + mu22*conF(alpha1, alpha1, p2, p2) + mu23*conF(alpha1, alpha1, p2, p3) + mu24*conF(alpha1, alpha1, p2, p4) + mu25*conF(alpha1, alpha1, p2, p5));
s3 = @(p1,p2,p3,p4,p5) (mu30*unconF(alpha1, alpha0, p3, 0) + mu31*conF(alpha1, alpha1, p3, p1) + mu32*conF(alpha1, alpha1, p3, p2) + mu33*conF(alpha1, alpha1, p3, p3) + mu34*conF(alpha1, alpha1, p3, p4) + mu35*conF(alpha1, alpha1, p3, p5));
s4 = @(p1,p2,p3,p4,p5) (mu40*unconF(alpha1, alpha0, p4, 0) + mu41*conF(alpha1, alpha1, p4, p1) + mu42*conF(alpha1, alpha1, p4, p2) + mu43*conF(alpha1, alpha1, p4, p3) + mu44*conF(alpha1, alpha1, p4, p4) + mu45*conF(alpha1, alpha1, p4, p5));
s5 = @(p1,p2,p3,p4,p5) (mu50*unconF(alpha1, alpha0, p5, 0) + mu51*conF(alpha1, alpha1, p5, p1) + mu52*conF(alpha1, alpha1, p5, p2) + mu53*conF(alpha1, alpha1, p5, p3) + mu54*conF(alpha1, alpha1, p5, p4) + mu55*conF(alpha1, alpha1, p5, p5));

% Profit
pi(1) = (pstar(1)-c)*s1(pstar(1),pstar(2),pstar(3),pstar(4),pstar(5));
pi(2) = (pstar(2)-c)*s2(pstar(1),pstar(2),pstar(3),pstar(4),pstar(5));
pi(3) = (pstar(3)-c)*s3(pstar(1),pstar(2),pstar(3),pstar(4),pstar(5));
pi(4) = (pstar(4)-c)*s4(pstar(1),pstar(2),pstar(3),pstar(4),pstar(5));
pi(5) = (pstar(5)-c)*s5(pstar(1),pstar(2),pstar(3),pstar(4),pstar(5));

% share
tot = s1(pstar(1),pstar(2),pstar(3),pstar(4),pstar(5)) + s2(pstar(1),pstar(2),pstar(3),pstar(4),pstar(5)) + s3(pstar(1),pstar(2),pstar(3),pstar(4),pstar(5)) + s4(pstar(1),pstar(2),pstar(3),pstar(4),pstar(5)) + s5(pstar(1),pstar(2),pstar(3),pstar(4),pstar(5));
share(1) = s1(pstar(1),pstar(2),pstar(3),pstar(4),pstar(5)) / tot;
share(2) = s2(pstar(1),pstar(2),pstar(3),pstar(4),pstar(5)) / tot;
share(3) = s3(pstar(1),pstar(2),pstar(3),pstar(4),pstar(5)) / tot;
share(4) = s4(pstar(1),pstar(2),pstar(3),pstar(4),pstar(5)) / tot;
share(5) = s5(pstar(1),pstar(2),pstar(3),pstar(4),pstar(5)) / tot;

% Quantities
quant(1) = s1(pstar(1),pstar(2),pstar(3),pstar(4),pstar(5));
quant(2) = s2(pstar(1),pstar(2),pstar(3),pstar(4),pstar(5));
quant(3) = s3(pstar(1),pstar(2),pstar(3),pstar(4),pstar(5));
quant(4) = s4(pstar(1),pstar(2),pstar(3),pstar(4),pstar(5));
quant(5) = s5(pstar(1),pstar(2),pstar(3),pstar(4),pstar(5));

% Aggregate consumer surplus and producer surplus
[eq_agg eq_firm] = calc_welfare(pstar,param);
cs = eq_agg(2,8);
ps = eq_agg(2,9);

end
