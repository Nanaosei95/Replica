function mom = calc_moment2(param,priceindex,share,alpha1)
    param = [alpha1 param']';
    mom = calc_moment(param,priceindex,share);

end

