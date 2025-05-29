
function F = calc_bnprices_merger53(p,param,startval)


fminopt=optimset('Display','off','UseParallel',false,'TolFun',1e-20,'TolX',1e-20,'MaxFunEvals',100000);

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

pi1 = @(p1,p2,p3,p4,p5) (p1-c)*s1(p1,p2,p3,p4,p5);
pi2 = @(p1,p2,p3,p4,p5) (p2-c)*s2(p1,p2,p3,p4,p5);
pi4 = @(p1,p2,p3,p4,p5) (p4-c)*s4(p1,p2,p3,p4,p5);
pi5 = @(p1,p2,p3,p4,p5) (p5-c)*s5(p1,p2,p3,p4,p5)+ (p3-c)*s3(p1,p2,p3,p4,p5);


R1 = @(p2,p3,p4,p5) fminunc(@(p1) -pi1(p1,p2,p3,p4,p5),startval(1),fminopt); % Best response function
R2 = @(p1,p3,p4,p5) fminunc(@(p2) -pi2(p1,p2,p3,p4,p5),startval(2),fminopt); % Best response function

R4 = @(p1,p2,p3,p5) fminunc(@(p4) -pi4(p1,p2,p3,p4,p5),startval(4),fminopt); % Best response function

R5 = @(p1,p2,p4) fminunc(@(p53) -pi5(p1,p2,p53(1),p4,p53(2)),[startval(3),startval(5)],fminopt); % Best response function

% Solver finds prices that make F=0
R5out = R5(p(1),p(2),p(4));

F(1) = R1(p(2),p(3),p(4),p(5))-p(1);
F(2) = R2(p(1),p(3),p(4),p(5))-p(2);
F(3) = R5out(1)-p(3);
F(4) = R4(p(1),p(2),p(3),p(5))-p(4);
F(5) = R5out(2)-p(5);


end
