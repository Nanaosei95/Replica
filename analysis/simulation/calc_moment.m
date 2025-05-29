function mom = calc_moment(param,priceindex,share)
 
c = 1;

[estpstar_sbn,estpstar,estpi,estshare,estshare_sbn,estpi_sbn,estquant,estquant_sbn] = calc_prices(param);

% Match price index
estpriceindex = estpstar/estpstar(5);

% Moments
share_moment = 100*(estshare' - share);
price_moment = 100*(estpriceindex' - priceindex);

% Penalties
constraint = calc_constraint(estpstar,param);

% Objective function
mom = sum(price_moment.^2) + sum(share_moment.^2) + sum(constraint.^2);

end

