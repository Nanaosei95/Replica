n_params = 8;
alpha1 = param(1);
tau = param(2);
c = 1;
alpha0 = 0;
mus = param(3:n_params);

mu10 = 1;        mu11 = 0;      mu12 = mus(1);  mu13 = mus(1);  mu14 = mus(1);          mu15 = mus(1); 
mu20 = mus(4);   mu21 = mu12;   mu22 = 0;       mu23 = mus(1);  mu24 = mus(1);          mu25 = mus(1);
mu30 = mus(5);   mu31 = mu13;	mu32 = mu23;	mu33 = 0;       mu34 = mus(2);          mu35 = mus(2);
mu40 = mus(6);   mu41 = mu14;	mu42 = mu24;	mu43 = mu34;	mu44 = 0;               mu45 = mus(3);
mu50 = 0;        mu51 = mu15;	mu52 = mu25;	mu53 = mu35;	mu54 = mu45;            mu55 = 0;
