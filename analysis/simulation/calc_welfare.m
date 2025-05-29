function [eq_agg eq_firm] = calc_welfare(price,param)

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
    
 
    run('set_parameters.m');
    matrix_F = matrix_F_index(1:5,:);
    m_mu = [mu11 mu12 mu13 mu14 mu15 mu10; ...
        mu21 mu22 mu23 mu24 mu25 mu20; ...
        mu31 mu32 mu33 mu34 mu35 mu30; ...
        mu41 mu42 mu43 mu44 mu45 mu40; ...
        mu51 mu52 mu53 mu54 mu55 mu50];

    m_quant = m_mu.*matrix_F;
    sum(sum(m_quant));
    
    m_weight = m_quant./sum(sum(m_quant));
    mean_dist = sum(sum(0.5.*matrix_F.*m_weight));
    
    m_price = repmat(price(1:5)',1,6);
    m_quant_firm = repmat(sum(m_quant')',1,6);
    m_weight_firm = m_quant./m_quant_firm;
    
    % Check matrix math
    sum(m_weight_firm');
    price(1:5);
    sum((m_weight_firm.*m_price)') == price(1:5);
    
    % Travel cost
    m_mean_dist = 0.5.*matrix_F;
    mean_dist_firm = sum((m_weight_firm.*m_mean_dist)');
    mean_dist = sum(sum(m_weight.*m_mean_dist));
    
  
    eq_firm = [price(1:5)' sum(m_weight')' mean_dist_firm' repmat(alpha1,5,1) tau.*mean_dist_firm' repmat(1,5,1) ];
    eq_firm(:,7) = (eq_firm(:,4) - eq_firm(:,5) - eq_firm(:,6)); % Total welfare
    eq_firm(:,8) = (eq_firm(:,4) - eq_firm(:,5) - eq_firm(:,1)); % Consumer surplus
    eq_firm(:,9) = (eq_firm(:,1) - eq_firm(:,6)); % Producer surplus
    eq_firm = [eq_firm; repmat(sum(m_quant')',1,9).*eq_firm];
 
    
    eq_agg = [sum(sum(m_weight.*m_price)) sum(sum(m_weight')') sum(sum(m_weight.*m_mean_dist)) alpha1 tau.*sum(sum(m_weight.*m_mean_dist)) 1];
    eq_agg(7) = (eq_agg(4) - eq_agg(5) - eq_agg(6)); % Total welfare
    eq_agg(8) = (eq_agg(4) - eq_agg(5) - eq_agg(1)); % Consumer surplus
    eq_agg(9) = (eq_agg(1) - eq_agg(6)); % Producer surplus
    
    eq_agg2 =  sum(sum(m_quant')').*eq_agg;
    eq_agg = [eq_agg; eq_agg2];
    
    
end