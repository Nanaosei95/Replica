function pi3out = pi3fcn32(pi3,p1,p2,p3,R4,R5)
    p4 = R4(p1,p2,p3);
    p5 = R5(p1,p2,p3,p4);
    pi3out = pi3(p1,p2,p3,p4,p5);
end

