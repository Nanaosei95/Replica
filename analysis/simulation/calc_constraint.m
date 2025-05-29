
function constraint = calc_constraint(price,param)
    c = 1;
    matrix_R = calc_R(price,param);
    matrix_R = matrix_R(1:5,1:5);
    matrix_F_index = calc_F_index(price,param);

    % Penalties
    constraint1 = 1000*(param < 0).*abs(param);
    constraint2 = 1*sum(sum(matrix_R));
    constraint3 = 100*sum(sum((matrix_F_index(1:5,1:5) > .95).*(matrix_F_index(1:5,1:5) - .95)));
    constraint4 = 1*(price - c < 0).*abs(price - c);
    constraint = [constraint1' constraint2' constraint3' constraint4]';

end