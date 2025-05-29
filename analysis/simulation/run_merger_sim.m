clear all
%folder = '~/Dropbox/AlgorithmsAndCompetition/analysis/simulation_aug16_1221pm/'; 
%folder = 'D:/Dropbox/Papers/016 Pricing Algorithms/analysis/simulation'; 
%cd(folder)
addpath(genpath(pwd));


% Simulates possible mergers with firm 3


%%%%%%%%%%%%%%%%%%%%%%%%%%
% Import prices and shares
%%%%%%%%%%%%%%%%%%%%%%%%%%

priceindex = readtable('prices_shares.csv','Range','B1:B6');
priceindex = flipud(priceindex{:,:})/100;
share = readtable('prices_shares.csv','Range','C1:C6');
share = flipud(share{:,:});

%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load Estimates
%%%%%%%%%%%%%%%%%%%%%%%%%%

load('param_est.mat')

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
[estpstar_sbn; estpstar_sbn2;estpstar]


% Data match
disp('How close are prices and shares?')
[estpriceindex' priceindex]
[estshare' share]

disp('Shares from each segment')
calc_F_index(estpstar_sbn,param_est)

% Welfare
[eq_agg eq_firm] = calc_welfare(estpstar,param_est);
cs = eq_agg(2,8);
ps = eq_agg(2,9);

[eq_agg_sbn eq_firm_sbn] = calc_welfare(estpstar_sbn,param_est);
cs_sbn = eq_agg_sbn(2,8);
ps_sbn = eq_agg_sbn(2,9);





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Run Merger Simulation Assuming Algorithmic Competition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

load('start_ap.mat')

estpstar_start = estpstar_merger13;
[estpstar_merger13,pi_merger13,share_merger13,quant_merger13,cs_merger13,ps_merger13] = calc_prices_merger13(param_est,estpstar_start);
[estpstar; estpstar_start; estpstar_merger13]

estpstar_start = estpstar_merger23;
[estpstar_merger23,pi_merger23,share_merger23,quant_merger23,cs_merger23,ps_merger23] = calc_prices_merger23(param_est,estpstar_start);
[estpstar; estpstar_start; estpstar_merger23]

estpstar_start = estpstar_merger43;
[estpstar_merger43,pi_merger43,share_merger43,quant_merger43,cs_merger43,ps_merger43] = calc_prices_merger43(param_est,estpstar_start);
[estpstar; estpstar_start; estpstar_merger43]

estpstar_start = estpstar_merger53;
[estpstar_merger53,pi_merger53,share_merger53,quant_merger53,cs_merger53,ps_merger53] = calc_prices_merger53(param_est,estpstar_start);
[estpstar; estpstar_start; estpstar_merger53]


mergedfirm = [1,0,1,0,0;0,1,1,0,0;0,0,1,1,0;0,0,1,0,1];

%Prices
allprices = [flip(estpstar); flip(estpstar_merger53); flip(estpstar_merger43); flip(estpstar_merger23);flip(estpstar_merger13)]
allshare = [flip(estshare); flip(share_merger53); flip(share_merger43); flip(share_merger23);flip(share_merger13)]

% Share weighted price
allprice_agg_pre = sum(repmat(allprices(1,:),4,1).*repmat(allshare(1,:),4,1),2)
allprice_agg = sum(allprices(2:end,:).*allshare(2:end,:),2)

% Share weighted price merged firms
allprice_merged_pre = sum((mergedfirm.*repmat(allprices(1,:),4,1)).*(allshare(2:end,:)./repmat(sum(mergedfirm.*allshare(2:end,:),2),1,5)),2)
allprice_merged = sum((mergedfirm.*allprices(2:end,:)).*(allshare(2:end,:)./repmat(sum(mergedfirm.*allshare(2:end,:),2),1,5)),2)

%Profit
allprofit = [flip(estpi); flip(pi_merger53); flip(pi_merger43); flip(pi_merger23);flip(pi_merger13)]
allprofit_agg_pre = sum(repmat(allprofit(1,:),4,1),2)
allprofit_agg = sum(allprofit(2:end,:),2)
allprofit_merged_pre = sum((mergedfirm.*repmat(allprofit(1,:),4,1)),2)
allprofit_merged = sum(mergedfirm.*allprofit(2:end,:),2)


% Consumer surplus
allcs= [flip(cs); flip(cs_merger53); flip(cs_merger43); flip(cs_merger23);flip(cs_merger13)]


pct_price_merged = cellfun(@(x)num2str(x,'%8.1f'),num2cell(100*(allprice_merged-allprice_merged_pre)./allprice_merged_pre),'uniformoutput',0);
pct_profit_merged = cellfun(@(x)num2str(x,'%8.1f'),num2cell(100*(allprofit_merged-allprofit_merged_pre)./allprofit_merged_pre),'uniformoutput',0);
pct_price_agg = cellfun(@(x)num2str(x,'%8.1f'),num2cell(100*(allprice_agg - allprice_agg_pre)./allprice_agg_pre),'uniformoutput',0);
pct_profit_agg = cellfun(@(x)num2str(x,'%8.1f'),num2cell(100*(allprofit_agg - allprofit_agg_pre)./allprofit_agg_pre),'uniformoutput',0);
pct_cs_agg = cellfun(@(x)num2str(x,'%8.1f'),num2cell(100*(allcs(2:end) - allcs(1))/allcs(1)),'uniformoutput',0);
values = [pct_price_merged pct_profit_merged pct_price_agg pct_profit_agg pct_cs_agg];
values


load('start_sbn.mat')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Run Merger Simulation Assuming Bertrand Nash Competition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%fsolveopt = optimoptions('fsolve','Display','off','TolFun',1e-20,'TolX',1e-20,'OptimalityTolerance',1e-20,'Algorithm','levenberg-marquardt','MaxFunEvals',100000);
fsolveopt = optimoptions('fsolve','Display','off','TolFun',1e-20,'TolX',1e-20,'OptimalityTolerance',1e-20,'MaxFunEvals',100000);
startval = estpstar_sbn;

pstar_sbn_merge13 = fsolve(@(p)calc_bnprices_merger13(p,param_est,startval),start_sbn13,fsolveopt);
pstar_sbn_merge23 = fsolve(@(p)calc_bnprices_merger23(p,param_est,startval),start_sbn23,fsolveopt);
pstar_sbn_merge43 = fsolve(@(p)calc_bnprices_merger43(p,param_est,startval),start_sbn43,fsolveopt);
pstar_sbn_merge53 = fsolve(@(p)calc_bnprices_merger53(p,param_est,startval),start_sbn53,fsolveopt);

[pi_sbn_merger13,share_sbn_merger13,quant_sbn_merger13,cs_sbn_merger13,ps_sbn_merger13] = calc_bn_eqm(param_est,pstar_sbn_merge13);
[pi_sbn_merger23,share_sbn_merger23,quant_sbn_merger23,cs_sbn_merger23,ps_sbn_merger23] = calc_bn_eqm(param_est,pstar_sbn_merge23);
[pi_sbn_merger43,share_sbn_merger43,quant_sbn_merger43,cs_sbn_merger43,ps_sbn_merger43] = calc_bn_eqm(param_est,pstar_sbn_merge43);
[pi_sbn_merger53,share_sbn_merger53,quant_sbn_merger53,cs_sbn_merger53,ps_sbn_merger53] = calc_bn_eqm(param_est,pstar_sbn_merge53);

%Prices
allprices_sbn = [flip(estpstar_sbn); flip(pstar_sbn_merge53); flip(pstar_sbn_merge43); flip(pstar_sbn_merge23);flip(pstar_sbn_merge13)]
allprice_sbn_agg_pre = sum(repmat(allprices_sbn(1,:),4,1).*repmat(allshare(1,:),4,1),2)
allprice_sbn_agg = sum(allprices_sbn(2:end,:).*allshare(2:end,:),2)
allprice_sbn_merged_pre = sum((mergedfirm.*repmat(allprices_sbn(1,:),4,1)).*(allshare(2:end,:)./repmat(sum(mergedfirm.*allshare(2:end,:),2),1,5)),2)
allprice_sbn_merged = sum((mergedfirm.*allprices_sbn(2:end,:)).*(allshare(2:end,:)./repmat(sum(mergedfirm.*allshare(2:end,:),2),1,5)),2)

%Profit
allprofit_sbn = [flip(estpi_sbn); flip(pi_sbn_merger53); flip(pi_sbn_merger43); flip(pi_sbn_merger23);flip(pi_sbn_merger13)]
allprofit_sbn_agg_pre = sum(repmat(allprofit_sbn(1,:),4,1),2)
allprofit_sbn_agg = sum(allprofit_sbn(2:end,:),2)
allprofit_sbn_merged_pre = sum((mergedfirm.*repmat(allprofit_sbn(1,:),4,1)),2)
allprofit_sbn_merged = sum(mergedfirm.*allprofit_sbn(2:end,:),2)

%Shares
allshare_sbn = [flip(estshare_sbn); flip(share_sbn_merger53); flip(share_sbn_merger43); flip(share_sbn_merger23);flip(share_sbn_merger13)]
sum(allprices_sbn.*allshare_sbn,2) % Share weighted price

% Consumer surplus
allcs_sbn= [flip(cs_sbn); flip(cs_sbn_merger53); flip(cs_sbn_merger43); flip(cs_sbn_merger23);flip(cs_sbn_merger13)]

pct_price_sbn_merged = cellfun(@(x)num2str(x,'%8.1f'),num2cell(100*(allprice_sbn_merged-allprice_sbn_merged_pre)./allprice_sbn_merged_pre),'uniformoutput',0);
pct_profit_sbn_merged = cellfun(@(x)num2str(x,'%8.1f'),num2cell(100*(allprofit_sbn_merged-allprofit_sbn_merged_pre)./allprofit_sbn_merged_pre),'uniformoutput',0);
pct_price_sbn_agg = cellfun(@(x)num2str(x,'%8.1f'),num2cell(100*(allprice_sbn_agg - allprice_sbn_agg_pre)./allprice_sbn_agg_pre),'uniformoutput',0);
pct_profit_sbn_agg = cellfun(@(x)num2str(x,'%8.1f'),num2cell(100*(allprofit_sbn_agg - allprofit_sbn_agg_pre)./allprofit_sbn_agg_pre),'uniformoutput',0);
pct_cs_sbn_agg = cellfun(@(x)num2str(x,'%8.1f'),num2cell(100*(allcs_sbn(2:end) - allcs_sbn(1))/allcs_sbn(1)),'uniformoutput',0);

values_sbn = [pct_price_sbn_merged pct_profit_sbn_merged pct_price_sbn_agg pct_profit_sbn_agg pct_cs_sbn_agg];
values_sbn

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Output for Latex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Panel A
full_name = {'Merger with A',...
			 'Merger with B', ...
			 'Merger with D',...
             'Merger with E',...
             };
           
input.data = table(values, 'RowNames', full_name);
%size(input.data)
%input.data

% Switch transposing/pivoting your table:
input.transposeTable = 0;
input.dataFormatMode = 'row'; % use 'column' or 'row'. if not set 'colum' is used
input.tableColumnAlignment = 'c'; % Column alignment in Latex table ('l'=left-justified, 'c'=centered,'r'=right-justified):
input.tableBorders = 1; % Switch table borders on/off:
input.booktabs = 1; % Use booktabs

latex = latexTable(input);
latex(1:6) = [];
latex((size(latex,1)-4):size(latex,1)) = [];

% save LaTex code as file
fid=fopen('../../paper/tables/stub_mergers_with_C_panel_b.tex','w');
[nrows,ncols] = size(latex);
for row = 1:nrows
fprintf(fid,'%s\n',latex{row,:});
end
fclose(fid); 


% Panel B
full_name = {'Merger with A',...
			 'Merger with B', ...
			 'Merger with D',...
             'Merger with E',...
             };
           
input.data = table(values_sbn, 'RowNames', full_name);
%size(input.data)
%input.data

% Switch transposing/pivoting your table:
input.transposeTable = 0;
input.dataFormatMode = 'row'; % use 'column' or 'row'. if not set 'colum' is used
input.tableColumnAlignment = 'c'; % Column alignment in Latex table ('l'=left-justified, 'c'=centered,'r'=right-justified):
input.tableBorders = 1; % Switch table borders on/off:
input.booktabs = 1; % Use booktabs

latex = latexTable(input);
latex(1:6) = [];
latex((size(latex,1)-4):size(latex,1)) = [];

% save LaTex code as file
fid=fopen('../../paper/tables/stub_mergers_with_C_panel_a.tex','w');
[nrows,ncols] = size(latex);
for row = 1:nrows
fprintf(fid,'%s\n',latex{row,:});
end
fclose(fid); 

