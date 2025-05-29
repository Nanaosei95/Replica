
function matrix_F_index = calc_F_index(price,param)
    price = [price 0];
    alpha1 = param(1);
    alpha0 = 0;
    tau = param(2);
    price_j = [price' price' price' price' price' price'];
    price_k = price_j';

    alphas = [alpha1 alpha1 alpha1 alpha1 alpha1 alpha0];
    alpha_j = [alphas' alphas' alphas' alphas' alphas' alphas'];
    alpha_k = alpha_j';
    
    matrix_R = (alpha_j - price_j) + (alpha_k - price_k) - tau < 0;
    matrix_R(6,:) = [1 1 1 1 1 1];
    matrix_R(:,6) = [1 1 1 1 1 1]';
    matrix_conF_index = 1/2 + 1/(2*tau)*((alpha_j - price_j) - (alpha_k - price_k));
    matrix_unconF_index = 1/tau*((alpha_j - price_j));    
    matrix_F_index = (1 - matrix_R).*matrix_conF_index + matrix_R.*matrix_unconF_index;
    matrix_F_index = matrix_F_index - diag(diag(matrix_F_index));

end