
function matrix_R = calc_R(price,param)
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


end
