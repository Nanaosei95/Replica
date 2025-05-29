function pi1out = pi1fcn43(pi1,p1,R2,R4,R5)
    p2 = R2(p1);
    R4out = R4(p1,p2);
    p3 = R4out(1);
    p4 = R4out(2);
    p5 = R5(p1,p2,p3,p4);
    pi1out = pi1(p1,p2,p3,p4,p5);
end

