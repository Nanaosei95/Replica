function pi2out = pi2fcn53(pi2,p1,p2,R4,R5)
    p4 = R4(p1,p2);
    R5out = R5(p1,p2,p4);
    p3 = R5out(1);
    p5 = R5out(2);
    pi2out = pi2(p1,p2,p3,p4,p5);
end

