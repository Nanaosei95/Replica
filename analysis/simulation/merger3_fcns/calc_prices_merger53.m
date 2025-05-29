% Runs pricing algorithm game with 5 firms
% Firm 1/2 move simultaneously
% Includes outside option (but no consumers "stay home")
% Cost is c

function [estpstar_merger53,pi,share,quant,cs,ps] = calc_prices_merger53(param,estpstar_start)

fminopt=optimset('Display','off','UseParallel',false,'TolFun',1e-20,'TolX',1e-10,'MaxFunEvals',10000,'MaxIter',10000);
fminopt2=optimset('Display','off','UseParallel',true,'TolFun',1e-16,'TolX',1e-10,'MaxFunEvals',10000,'MaxIter',10000);
fminsearchopt=optimset('Display','off','TolFun',1e-20,'TolX',1e-10,'MaxFunEvals',10000,'MaxIter',10000);
fminsearchopt2=optimset('Display','off','TolFun',1e-20,'TolX',1e-10,'MaxFunEvals',10000,'MaxIter',10000);
fzeropt1=optimset('Display','off','TolX',1e-20);
fzeropt2=optimset('Display','off','TolX',1e-20);

% Params
run('set_parameters.m')


% Contested segments
conF = @(alphai, alphaj, pi, pj) max(min(1/2 + 1/(2*tau)*((alphai - pi) - (alphaj - pj)), 1),0);

% Uncontested segments
% unconF = @(alphai, alphaj, pi, pj) max(min(1/tau*((alphai - pi)),1),0);
% No max length (for flexibility)
unconF = @(alphai, alphaj, pi, pj) max(1/tau*((alphai - pi)),0);

s1 = @(p1,p2,p3,p4,p5) (mu10*unconF(alpha1, alpha0, p1, 0) + mu11*conF(alpha1, alpha1, p1, p1) + mu12*conF(alpha1, alpha1, p1, p2) + mu13*conF(alpha1, alpha1, p1, p3) + mu14*conF(alpha1, alpha1, p1, p4) + mu15*conF(alpha1, alpha1, p1, p5));
s2 = @(p1,p2,p3,p4,p5) (mu20*unconF(alpha1, alpha0, p2, 0) + mu21*conF(alpha1, alpha1, p2, p1) + mu22*conF(alpha1, alpha1, p2, p2) + mu23*conF(alpha1, alpha1, p2, p3) + mu24*conF(alpha1, alpha1, p2, p4) + mu25*conF(alpha1, alpha1, p2, p5));
s3 = @(p1,p2,p3,p4,p5) (mu30*unconF(alpha1, alpha0, p3, 0) + mu31*conF(alpha1, alpha1, p3, p1) + mu32*conF(alpha1, alpha1, p3, p2) + mu33*conF(alpha1, alpha1, p3, p3) + mu34*conF(alpha1, alpha1, p3, p4) + mu35*conF(alpha1, alpha1, p3, p5));
s4 = @(p1,p2,p3,p4,p5) (mu40*unconF(alpha1, alpha0, p4, 0) + mu41*conF(alpha1, alpha1, p4, p1) + mu42*conF(alpha1, alpha1, p4, p2) + mu43*conF(alpha1, alpha1, p4, p3) + mu44*conF(alpha1, alpha1, p4, p4) + mu45*conF(alpha1, alpha1, p4, p5));
s5 = @(p1,p2,p3,p4,p5) (mu50*unconF(alpha1, alpha0, p5, 0) + mu51*conF(alpha1, alpha1, p5, p1) + mu52*conF(alpha1, alpha1, p5, p2) + mu53*conF(alpha1, alpha1, p5, p3) + mu54*conF(alpha1, alpha1, p5, p4) + mu55*conF(alpha1, alpha1, p5, p5));

% Post merger
pi1 = @(p1,p2,p3,p4,p5) (p1-c)*s1(p1,p2,p3,p4,p5);
pi2 = @(p1,p2,p3,p4,p5) (p2-c)*s2(p1,p2,p3,p4,p5);
%pi3 = @(p1,p2,p3,p4,p5) (p3-c)*s3(p1,p2,p3,p4,p5);
pi4 = @(p1,p2,p3,p4,p5) (p4-c)*s4(p1,p2,p3,p4,p5);
pi5 = @(p1,p2,p3,p4,p5) (p5-c)*s5(p1,p2,p3,p4,p5) + (p3-c)*s3(p1,p2,p3,p4,p5);

% Best response functions (Firm 5 is fastest/last mover)
R5 = @(p1,p2,p4) fminunc(@(p53) (-pi5(p1,p2,p53(1),p4,p53(2))),[estpstar_start(3),estpstar_start(5)],fminopt);

R4 = @(p1,p2) fminunc(@(p4) (-pi4fcn53(pi4,p1,p2,p4,R5)),estpstar_start(4),fminopt);

%R3 = @(p1,p2) fminunc(@(p3) (-pi3(p1,p2,p3,R4(p1,p2,p3),R5(p1,p2,p3,R4(p1,p2,p3)))),estpstar_start(3),fminopt);
R2 = @(p1) fminunc(@(p2) (-pi2fcn53(pi2,p1,p2,R4,R5)),estpstar_start(2),fminopt);

estpstar_merger53(1) = fminunc(@(p1) (-pi1fcn53(pi1,p1,R2,R4,R5)),estpstar_start(1),fminopt);   

% Now solve for remaining equilibrium prices
estpstar_merger53(2) = R2(estpstar_merger53(1));

estpstar_merger53(4) = R4(estpstar_merger53(1),estpstar_merger53(2));

R5out = R5(estpstar_merger53(1),estpstar_merger53(2),estpstar_merger53(4));
estpstar_merger53(3) = R5out(1);
estpstar_merger53(5) = R5out(2);


pstar = estpstar_merger53;

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




