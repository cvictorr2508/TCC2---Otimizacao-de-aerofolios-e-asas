% Modifica��o (TCC2): capacidade para simular m�ltiplas condi��es de voo
clc,clear

% Par�metros do algoritmo
dat.N = 500;                              % N�mero de indiv�duos na popula��o (deve ser par por hora)
dat.mu = 0.05;                           % Probabilidade de muta��o
dat.iter = 5;                           % N�mero de itera��es
dat.aero = zeros(dat.iter,4);          % Matriz usada no gr�fico final
dat.aero_m = dat.aero;
dat.elite = 1;                         % Aplicar elitismo?
dat.subs = 1;                          % Substituir aerof�lios sem resultados? 

% Par�metros da geometria
dat.m_ext = [0 9];
dat.p_ext = [1 9];
dat.t_ext = [10 30];

% Par�metros das simula��es
dat.cases = 2;                          % N�mero de condi��es de voo a serem analisadas
dat.reynolds = [1e6,1e6,1e7];           % Valores dos n�meros de Reynolds para as simula��es
dat.aoa = [0,2,0];                     % �ngulos de ataque
dat.iter_sim = [50,50,50];             % N�meros de itera��es no XFOIL
%dat.coeff_op = ['!','!','!','^';       % Uma linha para cada condi��o de voo
%                '!','!','!','^';
%                '!','!','!','^'];
%dat.coeff_val = [0.6,0,120,0;
%                 0,0,0,0;
%                 0,0,0,0];
%dat.coeff_F = [1,1,1,1;
%               1,1,1,1;
%               1,1,1,1];

naca_num = '0013';



reynolds = dat.reynolds;
aoa = dat.aoa;
iter_sim = dat.iter_sim;
%coeff_op = dat.coeff_op;
cases = dat.cases;


%fclose('all');





% Apagar arquivos caso existam
for i = 1:cases
    a_polar = ['polar' num2str(i) '.txt'];
    if (exist(a_polar,'file'))
        delete(a_polar);
    end
end

%if (exist('xfoil_input.txt','file'))
%    delete('xfoil_input.txt');
%end


%% Cria��o do arquivo de input do Xfoil
fid = fopen('xfoil_input.txt','w');


% Mudar uma op��o dos gr�ficos do XFOIL (desativar a apari��o 
% da janela com o desenho da simula��o)
fprintf(fid,'PLOP\n');
fprintf(fid,'G\n\n');

% Gerar o aerof�lio
fprintf(fid, 'NACA %s\n', naca_num);

% Simula��es 
fprintf(fid,'OPER\n');
if cases == 1 % Apenas uma condi��o de voo
    
    fprintf(fid,'VISC %d\n', reynolds(1)); % Aplicar o modo viscoso e determinar n�mero de Reynolds 
    fprintf(fid,'PACC\n');              % Estabelecer arquivo de output
    fprintf(fid,['polar' num2str(1) '.txt\n\n']);
    fprintf(fid,'ITER %d\n', iter_sim(1)); % Mudar o n�mero de itera��es      
    fprintf(fid,'ALFA %f\n', aoa(1));        % Estabelecer �ngulo de ataque

else % Duas ou mais condi��es de voo

    for i = 1:cases
        
        if i == 1
            fprintf(fid,'VISC %d\n', reynolds(i)); % Aplicar o modo viscoso e determinar n�mero de Reynolds
        elseif i ~= 1 && reynolds(i) ~= reynolds(i-1)
            fprintf(fid,'RE %d\n',reynolds(i)); % Mudar n�mero de Reynolds (ap�s primeira simula��o)
%        else
%            fprintf(fid,'RE %d\n',reynolds(i)); % Mudar n�mero de Reynolds (ap�s primeira simula��o)
        end
        fprintf(fid,'PACC\n');              % Estabelecer arquivo de output
        fprintf(fid,['polar' num2str(i) '.txt\n\n']);
        if i == 1
            fprintf(fid,'ITER %d\n', iter_sim(i)); % Mudar o n�mero de itera��es    
        elseif i~= 1 && iter_sim(i) ~= iter_sim(i-1)
            fprintf(fid,'ITER %d\n', iter_sim(i));
        end
        fprintf(fid,'ALFA %f\n', aoa(i));        % Estabelecer �ngulo de ataque
        fprintf(fid,'PACC\n'); % Fechar a polar para come�ar a pr�xima simula��o
        
    end
end

% Fechar arquivo
fprintf(fid,'\nQUIT\n');
fclose(fid);

% Executar XFOIL com o arquivo de entrada
cmd = 'xfoil.exe < xfoil_input.txt' ;
system(cmd);


%% Ler o arquivo de output
aero = zeros(cases,4);
for i = 1:cases

    % Contar o n�mero de linhas
    fidpolar = fopen(['polar' num2str(i) '.txt']); 
    tline = fgetl(fidpolar);
    nl = 0;
    while ischar(tline)	
        nl = nl+1; % N�mero de linhas
        tline = fgetl(fidpolar);
    end
    fclose(fidpolar);
    
    if nl == 13
        fidpolar = fopen(['polar' num2str(i) '.txt']);
        dataBuffer = textscan(fidpolar,'%f %f %f %f %f %f %f','HeaderLines',12,...
            'CollectOutput',1,...
            'Delimiter','');
        fclose(fidpolar);
        
        % Valores dos coeficientes
        CL = dataBuffer{1,1}(1,2);
        CD = dataBuffer{1,1}(1,3);
        CM = dataBuffer{1,1}(1,5);
%        delete(a_polar);
        
        aero(i,:) = [CL CD CL/CD CM];
        
    else
        aero = 'n'; break
    end

    
end

disp(''),disp(aero)

%fclose(fidpolar);

