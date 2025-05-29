function pi1out = pi1fcn53(pi1,p1,R2,R4,R5)
    p2 = R2(p1);
    p4 = R4(p1,p2);
    R5out = R5(p1,p2,p4);
    p3 = R5out(1);
    p5 = R5out(2);
    pi1out = pi1(p1,p2,p3,p4,p5);
end

