function pi2out = pi2fcn13(pi2,p2,R3,R4,R5)
    R3out = R3(p2);
    p1 = R3out(1);
    p3 = R3out(2);
    p4 = R4(p1,p2,p3);
    p5 = R5(p1,p2,p3,p4);
    pi2out = pi2(p1,p2,p3,p4,p5);
end

