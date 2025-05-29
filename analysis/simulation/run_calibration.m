clear all
addpath(genpath(pwd));


%%%%%%%%%%%%%%%%%%%%%%%%%%
% Import prices and shares
%%%%%%%%%%%%%%%%%%%%%%%%%%

priceindex = readtable('prices_shares.csv','Range','B1:B6');
priceindex = flipud(priceindex{:,:})/100;
share = readtable('prices_shares.csv','Range','C1:C6');
share = flipud(share{:,:});

%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initial values
%%%%%%%%%%%%%%%%%%%%%%%%%%

tau = 1;
c = 1;
alpha0 = 0;
n_params = 8;
mus = ones(n_params-2,1);
param2 = [tau;mus];

%%%%%%%%%%%%%%%%%%%%%%%%%%
% Estimation
%%%%%%%%%%%%%%%%%%%%%%%%%%

% First Step: Run method of moments, with a grid search over alpha1
grid_min = 2;
grid_max = 20;
grid_size = 100;
fmin_options = optimset('Display','off','UseParallel',false,'TolFun',1e-12,'TolX',1e-12,'MaxIter',5000,'MaxFunEvals',5000);
m_params = zeros(grid_size, n_params);
m_objective = zeros(grid_size, 4);

tic
parfor i = 1:grid_size 
    alpha1 = grid_min + i./(grid_size)*(grid_max-grid_min);

    param_est = fminunc(@(param2)calc_moment2(param2,priceindex,share,alpha1),param2,fmin_options);
    param_est = [alpha1 param_est']';
    m_params(i,:) = param_est;

    [estpstar_sbn,estpstar,estpi,estshare,estshare_sbn,estpi_sbn,estquant,estquant_sbn] = calc_prices(param_est);
    objective = calc_moment(param_est,priceindex,share);
    constraint = sum(abs(calc_constraint(estpstar,param_est)));
    m_objective(i,:) = [alpha1 objective constraint i];

end
toc

m_params(1:10,:)
m_objective(1:10,:)

results = [m_objective m_params];

% Global minimum from grid search
min_m_obj = min(m_objective);
min_m_i = find(m_objective(:,2) == min(m_objective(:,2)));
param_step2 = m_params(min_m_i,:)';
min_m_obj;

% Second step: method of moments from grid search result 
param_step2 = param_step2.*1.05; % Small deviation so optimizer does not get stuck
param_est = fminunc(@(param)calc_moment(param,priceindex,share),param_step2,fmin_options);
save('param_est.mat','param_est')

% Examine estimates
calc_moment(param_est,priceindex,share);
param_est;
[estpstar_sbn,estpstar,estpi,estshare,estshare_sbn,estpi_sbn,estquant,estquant_sbn] = calc_prices(param_est);
estpriceindex = estpstar/estpstar(5);
(estpstar_sbn-estpstar)./estpstar;

disp('Parameter vector')
param_est

disp('Estimated Margins')
margin = (estpstar-1) ./ estpstar

% Check conditions and constraints
calc_R(estpstar,param_est)
calc_F_index(estpstar,param_est)
sum(abs(calc_constraint(estpstar,param_est)))

% Recalculate estpstar_sbn using numerical approach
estpstar_sbn2 = bnfcn_numerical(param_est,estpstar_sbn);
[estpstar_sbn; estpstar_sbn2;estpstar];


% Data match
disp('How close are prices and shares?')
[estpriceindex' priceindex]
[estshare' share]

disp('Shares from each segment')
calc_F_index(estpstar_sbn,param_est)

%%%%%%%%%%%%%%%%%%%%%%%%%%
% Export
%%%%%%%%%%%%%%%%%%%%%%%%%%

% Export csv for Stata
firm = [1:5]';
output = [firm, estshare', share,estpstar',estpriceindex',priceindex,estpstar_sbn',estshare_sbn',margin',estpi',estpi_sbn',estquant',estquant_sbn',ones(5,1)*c];

cHeader = {'firm' 'estshare' 'share' 'estprice' 'estpriceindex' 'priceindex' 'estpstar_sbn' 'estshare_sbn' 'margin' 'estpi' 'estpi_sbn' 'quant' 'quant_sbn' 'cost'}; 
commaHeader = [cHeader;repmat({','},1,numel(cHeader))]; %insert commaas
commaHeader = commaHeader(:)';
textHeader = cell2mat(commaHeader); %cHeader in text with commas
fid = fopen('sim_output.csv','w');  %write header to file
fprintf(fid,'%s\n',textHeader);
fclose(fid);
dlmwrite('sim_output.csv',output,'-append'); %write data to end of file


%%%%%%%%%%%%%%%%%%%%%%%%%%
% Parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%

disp('Consumer valuation')
param_est(1)

disp('Travel cost parameter')
param_est(2)

mu_matrix(estpstar,param_est);

%%%%%%%%%%%%%%%%%%%%%%%%%%
% Elasticities
%%%%%%%%%%%%%%%%%%%%%%%%%%

% Elasticities at pricing algorithm prices
disp('Elasticities at pricing algorithm prices')
e = elasticities(param_est,estpstar);

% Elasticities at bertrand nash prices
%disp('Elasticities at Bertrand-Nash prices')
%e = elasticities(param_est,estpstar_sbn);

disp('Welfare calculations')

[eq_sbn eq_sbn_firm] = calc_welfare(estpstar_sbn, param_est);
[eq_alg eq_alg_firm] = calc_welfare(estpstar, param_est);
eq_delta = 100*(eq_alg - eq_sbn)./eq_sbn;
aggregates = [{num2str(eq_sbn(1,1),'%8.2f')} {num2str(eq_sbn(1,2),'%8.0f')} {num2str(eq_sbn(2,9),'%8.1f')} {' '} {num2str(eq_alg(1,1),'%8.2f')} {num2str(eq_alg(1,2),'%8.0f')} {num2str(eq_alg(2,9),'%8.1f')} {' '} {num2str(eq_delta(1,1),'%8.1f')} {num2str(eq_delta(2,9),'%8.1f')}];

disp('Aggregate measures: Algorithms')
eq_alg

disp('Aggregate measures: Bertrand-Nash')
eq_sbn

disp('Counterfactual effects table')

delta_pstar = cellfun(@(x)num2str(x,'%8.1f'),num2cell(100*(estpstar -  estpstar_sbn)./estpstar_sbn),'uniformoutput',0);
delta_share = cellfun(@(x)num2str(x,'%8.1f'),num2cell(100*(estshare -  estshare_sbn)./estshare_sbn),'uniformoutput',0);
delta_pi = cellfun(@(x)num2str(x,'%8.1f'),num2cell(100*(estpi -  estpi_sbn)./estpi_sbn),'uniformoutput',0);

price_sbn = cellfun(@(x)num2str(x,'%8.2f'),num2cell(estpstar_sbn),'uniformoutput',0);
share_sbn = cellfun(@(x)num2str(x,'%8.3f'),num2cell(estshare_sbn),'uniformoutput',0);
profit_sbn = cellfun(@(x)num2str(x,'%8.1f'),num2cell(estpi_sbn),'uniformoutput',0);
price = cellfun(@(x)num2str(x,'%8.2f'),num2cell(estpstar),'uniformoutput',0);
share = cellfun(@(x)num2str(x,'%8.3f'),num2cell(estshare),'uniformoutput',0);
profit = cellfun(@(x)num2str(x,'%8.1f'),num2cell(estpi),'uniformoutput',0);

blank = {' ', ' ', ' ', ' ', ' '};

values = flip([price_sbn' share_sbn' profit_sbn' blank' price' share' profit' blank' delta_pstar' delta_pi']);
values = [values; aggregates];
% Output latex
full_name = {'A',...
			 'B', ...
			 'C',...
			 'D',...
             'E',...
             'Aggregate',...
             };
         
 
input.data = table(values, 'RowNames', full_name);

input.transposeTable = 0;
input.dataFormatMode = 'row'; % use 'column' or 'row'. if not set 'colum' is used
input.tableColumnAlignment = 'c';
input.tableBorders = 1;
input.booktabs = 1;

latex = latexTable(input);

latex(1:6) = [];
latex((size(latex,1)-4):size(latex,1)) = [];

latex(size(latex,1)+1) = latex(size(latex,1));
latex(size(latex,1)-1) = cellstr('\midrule');

% save LaTex code as file
fid=fopen('../../paper/tables/stub_welfare.tex','w');
[nrows,ncols] = size(latex);
for row = 1:nrows
fprintf(fid,'%s\n',latex{row,:});
end
fclose(fid); 


