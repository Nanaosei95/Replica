% Finds elasticity of demand matrix

function e = elasticities(param,estpstar)

% Params
run('set_parameters.m')


% Contested segments
conF = @(alphai, alphaj, pi, pj) 1/2 + 1/(2*tau)*((alphai - pi) - (alphaj - pj));

% Uncontested segments
unconF = @(alphai, alphaj, pi, pj)  1/tau*((alphai - pi) - (alphaj - pj));

syms p1 p2 p3 p4 p5
s1 = (mu10*unconF(alpha1, alpha0, p1, 0) + mu11*conF(alpha1, alpha1, p1, p1) + mu12*conF(alpha1, alpha1, p1, p2) + mu13*conF(alpha1, alpha1, p1, p3) + mu14*conF(alpha1, alpha1, p1, p4) + mu15*conF(alpha1, alpha1, p1, p5));
s2 =  (mu20*unconF(alpha1, alpha0, p2, 0) + mu21*conF(alpha1, alpha1, p2, p1) + mu22*conF(alpha1, alpha1, p2, p2) + mu23*conF(alpha1, alpha1, p2, p3) + mu24*conF(alpha1, alpha1, p2, p4) + mu25*conF(alpha1, alpha1, p2, p5));
s3 =  (mu30*unconF(alpha1, alpha0, p3, 0) + mu31*conF(alpha1, alpha1, p3, p1) + mu32*conF(alpha1, alpha1, p3, p2) + mu33*conF(alpha1, alpha1, p3, p3) + mu34*conF(alpha1, alpha1, p3, p4) + mu35*conF(alpha1, alpha1, p3, p5));
s4 = (mu40*unconF(alpha1, alpha0, p4, 0) + mu41*conF(alpha1, alpha1, p4, p1) + mu42*conF(alpha1, alpha1, p4, p2) + mu43*conF(alpha1, alpha1, p4, p3) + mu44*conF(alpha1, alpha1, p4, p4) + mu45*conF(alpha1, alpha1, p4, p5));
s5 =  (mu50*unconF(alpha1, alpha0, p5, 0) + mu51*conF(alpha1, alpha1, p5, p1) + mu52*conF(alpha1, alpha1, p5, p2) + mu53*conF(alpha1, alpha1, p5, p3) + mu54*conF(alpha1, alpha1, p5, p4) + mu55*conF(alpha1, alpha1, p5, p5));

e = zeros(5,5);

% Define elasticity function
elastij = @(si, pj)  double(subs(diff(si,pj)*pj/si,{p1,p2,p3,p4,p5},{estpstar(1),estpstar(2),estpstar(3),estpstar(4),estpstar(5)}));

% Elasticity of demand for firm 1 with respect to k
e(1,1) = elastij(s1,p1);
e(2,1) = elastij(s2,p1);
e(3,1) = elastij(s3,p1);
e(4,1) = elastij(s4,p1);
e(5,1) = elastij(s5,p1);

% Elasticity of demand for firm 2 with respect to k
e(1,2) = elastij(s1,p2);
e(2,2) = elastij(s2,p2);
e(3,2) = elastij(s3,p2);
e(4,2) = elastij(s4,p2);
e(5,2) = elastij(s5,p2);

% Elasticity of demand for firm 3 with respect to k
e(1,3) = elastij(s1,p3);
e(2,3) = elastij(s2,p3);
e(3,3) = elastij(s3,p3);
e(4,3) = elastij(s4,p3);
e(5,3) = elastij(s5,p3);

% Elasticity of demand for firm 4 with respect to k
e(1,4) = elastij(s1,p4);
e(2,4) = elastij(s2,p4);
e(3,4) = elastij(s3,p4);
e(4,4) = elastij(s4,p4);
e(5,4) = elastij(s5,p4);

% Elasticity of demand for firm 5 with respect to k
e(1,5) = elastij(s1,p5);
e(2,5) = elastij(s2,p5);
e(3,5) = elastij(s3,p5);
e(4,5) = elastij(s4,p5);
e(5,5) = elastij(s5,p5);

e = flip(flip(e,1),2);

% Output latex
full_name = {'& A',...
			 '& B', ...
			 '& C',...
			 '& D',...
             '& E',...
             };

% Digits
e2 = cellfun(@(x)num2str(x,'%8.2f'),num2cell(e),'uniformoutput',0)
         
input.data = table(e2, 'RowNames', full_name);
%size(input.data)
%input.data

% Switch transposing/pivoting your table:
input.transposeTable = 0;
input.dataFormatMode = 'row'; % use 'column' or 'row'. if not set 'colum' is used
input.tableColumnAlignment = 'c';
input.tableBorders = 1;
input.booktabs = 1;

latex = latexTable(input);
latex(1:5) = [];
latex((size(latex,1)-4):size(latex,1)) = [];

latex(1) = cellstr('\parbox[t]{2mm}{\multirow{5}{*}{\rotatebox[origin=c]{90}{Share}}} ');

% save LaTex code as file
fid=fopen('../../paper/tables/elast_pricing_alg.tex','w');
[nrows,ncols] = size(latex);
for row = 1:nrows
fprintf(fid,'%s\n',latex{row,:});
end
fclose(fid); 

end
