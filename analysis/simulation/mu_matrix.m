
function m_mu = mu_matrix(price,param)
    run('set_parameters.m');

    m_mu = [mu11 mu12 mu13 mu14 mu15 mu10; ...
            mu21 mu22 mu23 mu24 mu25 mu20; ...
            mu31 mu32 mu33 mu34 mu35 mu30; ...
            mu41 mu42 mu43 mu44 mu45 mu40; ...
            mu51 mu52 mu53 mu54 mu55 mu50];

     m_mu_output = m_mu(:,1:5);
     m_mu_output = flip(flip(m_mu_output,2),1);
     
     matrix_F_index = calc_F_index(price,param);
     outside_F_index = matrix_F_index(1:5,6);
     outside_mass = flip(m_mu(:,6).*outside_F_index);
 
     m_mu_output = [m_mu_output outside_mass];
     
     % Output latex
    row_names = {'& A',...
                 '& B', ...
                 '& C',...
                 '& D',...
                 '& E',...
                 };
    m_mu_output = cellfun(@(x)num2str(x,'%8.2f'),num2cell(m_mu_output),'uniformoutput',0);

    input.data = table(m_mu_output, 'RowNames', row_names);
    %size(input.data)
    %input.data

    % Switch transposing/pivoting your table:
    input.transposeTable = 0;

    % Determine whether input.dataFormat is applied column or row based:
    input.dataFormatMode = 'row'; % use 'column' or 'row'. if not set 'colum' is used

    % Column alignment in Latex table ('l'=left-justified, 'c'=centered,'r'=right-justified):
    input.tableColumnAlignment = 'c';

    % Switch table borders on/off:
    input.tableBorders = 1;

    % Use booktabs
    input.booktabs = 1;

    latex = latexTable(input);
    latex(1:5) = [];
    latex((size(latex,1)-4):size(latex,1)) = [];
    
    latex(1) = cellstr('\parbox[t]{2mm}{\multirow{5}{*}{\rotatebox[origin=c]{90}{Retailer $j$}}} ');
    
    % save LaTex code as file
    fid=fopen('../../paper/tables/stub_calibrated_mass.tex','w');
    [nrows,ncols] = size(latex);
    for row = 1:nrows
    fprintf(fid,'%s\n',latex{row,:});
    end
    fclose(fid); 

end