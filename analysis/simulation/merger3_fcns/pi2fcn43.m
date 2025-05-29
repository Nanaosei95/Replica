function pi2out = pi2fcn43(pi2,p1,p2,R4,R5)
    R4out = R4(p1,p2);
    p3 = R4out(1);
    p4 = R4out(2);
    p5 = R5(p1,p2,p3,p4);
    pi2out = pi2(p1,p2,p3,p4,p5);
end

