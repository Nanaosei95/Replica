function pi4out = pi4fcn53(pi4,p1,p2,p4,R5)
    R5out = R5(p1,p2,p4);
    p3 = R5out(1);
    p5 = R5out(2);
    pi4out = pi4(p1,p2,p3,p4,p5);
end

