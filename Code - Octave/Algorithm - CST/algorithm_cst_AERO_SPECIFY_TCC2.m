%% Algoritmo gen�tico CST - Otimizador de perfis espec�ficos

% Sobre o beta2: ele deve ter um valor que cumpra beta1+beta2>=L, onde L
% � a separa��o m�nima entre �ngulos -> beta2>=L-beta1


%% Corre��es a serem feitas

% - Aplicar a limita��o dos �ngulos em outros est�gios al�m da gera��o inicial
% - Aplicar uma especifica��o de perfis sim�tricos 
% - Adicionar uma forma de mudar a precis�o das vari�veis https://www.mathworks.com/matlabcentral/answers/308585-how-to-generate-non-integer-random-number-in-between-two-numbers

% - Na checagem de erros: seria bom enfatizar os sinais das extens�es de valores?
%   (primeira casa <= 0, segunda casa >= 0)


%%

clear,clc
fclose('all');
tic
%[y2,Fs2] = audioread('C:\Users\Guga Weffort\Documents\MATLAB\504 Finding a Treasure Box.wav');

%%

% Par�metros do algoritmo
dat.N = 150;                              % N�mero de indiv�duos na popula��o (deve ser par por hora)
dat.mu = 0.05;                           % Probabilidade de muta��o
dat.iter = 5;                         % N�mero de itera��es
dat.elite = 1;                         % Aplicar elitismo?
dat.subs = 1;                          % Substituir aerof�lios sem resultados? 
%dat.aero_M = zeros(dat.iter,4);  % [Tirar isto depois] (e apagar a fun��o make_vector tamb�m)

% Dados do aerof�lio a ser otimizado 
%op = 1;
dat.or_v_ex = [0.010000, 0.180472, 0.236104, 0.279989, 0.304271, 0.321324, 20.000057, 0.000000];
dat.or_v_in = [0.019999, 0.083345, 0.046642, 0.040038, 0.033295, 0.016689, -0.000479, -0.000000];

dat.symm_override = 0; % For�ar a identifica��o de perfil sim�trico caso o algoritmo n�o o reconhe�a como tal (devido a erros de precis�o)
                       % Isto efetivamente forma um perfil sim�trico fazendo o espelhamento do extradorso

% Par�metros da geometria CST
dat.BPn = length(dat.or_v_ex)-2;                  % Grau do polin�mio de Bernstein (n�mero de vari�veis de design = BPn+1, desconsiderando o delta_z)
dat.np = 80;                          % N�mero de pontos a serem usados na gera��o de ordenadas
dat.p_op = 0;                % Op��o da gera��o de pontos (1 pra cosspace, outro valor pra cosspace_half)
dat.N1 = 0.5;
dat.N2 = 1;
dat.le_R_ext1 = [-0.01,0.01,0.005]; % Limite inferior (<=0), limite superior(>=0), valor m�nimo poss�vel (pois Rle > 0)
dat.le_R_ext2 = [-0.01,0.01,0.005]; % Limite inferior (<=0), limite superior(>=0), valor m�nimo poss�vel (pois Rle > 0)
dat.A_ext1 = [-0.05,0.05]; % Limite inferior (<=0) e superior (>=0)
dat.A_ext2 = [-0.05,0.05]; % Limite inferior (<=0) e superior (>=0)
dat.B_ext1 = [-5,5]; % Limite inferior (<=0) e superior (>=0)
dat.B_ext2 = [dat.or_v_ex(end-1) + dat.or_v_in(end-1),5]; % O primeiro n�mero � a separa��o m�nima do extradorso, o segundo � o limite superior
dat.chord = 1;

% Par�metros das simula��es
dat.cases = 1;                          % N�mero de condi��es de voo a serem analisadas
dat.reynolds = [1e6,1e6,1e6];           % Valores dos n�meros de Reynolds para as simula��es
dat.aoa = [0,4,8];                     % �ngulos de ataque
dat.iter_sim = [10,10,10];             % N�meros de itera��es no XFOIL
dat.numNodes = 0;                      % N�mero de pain�is
dat.coeff_op = ['o','!','!','o';       % Uma linha para cada condi��o de voo
                '!','!','!','!';
                '!','!','!','!'];
dat.coeff_val = [0.5,0.01,60,0;
                 0.5,0,0,-0.08;
                 0,0,0,-0.08];
dat.coeff_F = [1,1,1,1;
               1,1,1,1;
               1,1,1,1];
% [CL CD L/D CM] Defini��o da matriz dat.coeff_op
% '!' -> n�o usar como fun��o objetivo
% '^' -> procurar por um valor m�ximo (CL e L/D) ou valor m�nimo (CD e CM)
% 'c'  -> buscar valor constante de coeficiente de momento (arbitr�rio)
% 'k' -> buscar valor constante de coeficiente de momento (espec�fico, de dat.coeff_val(1,4))
% 'o' -> procurar por um valor espec�fico (qualquer um dos par�metros). Nesse caso, definir o valor
% em sua respectiva casa no vetor dat.coeff_val
% O vetor dat.coeff_F d� os pesos de cada fun��o objetivo

% Checagem de erros
dat = error_check_cst_TCC2(dat);

% Template dos structs                                        
empty.v_ex = zeros(1,dat.BPn+2);
empty.v_in = zeros(1,dat.BPn+2);
empty.symm = [];
empty.aero = [];
empty.score = 0;

% Vetor que define os perfis:
% v = [ RLe A1 A2 A3 ... A(N) beta Dz]
pop = repmat(empty,dat.N,1);
chi = pop;

% Gerar popula��o inicial
disp('<< Gera��o da popula��o inicial >>')
for i = 1:dat.N
    disp(['Indiv�duo ' num2str(i)])
    
    check = 0;
    while check == 0
    
        if isequal(dat.or_v_ex,dat.or_v_in) || dat.symm_override == 1 % Perfil sim�trico
            % Vetor com informa��es do extradorso
            pop(i).v_ex(1) = dat.or_v_ex(1) + rand*dat.le_R_ext1(randi(2));    % Raio do bordo de ataque
            for a = 2:dat.BPn
                pop(i).v_ex(a) = dat.or_v_ex(a) + rand*dat.A_ext1(randi(2));        % Pesos intermedi�rios
            end
            pop(i).v_ex(dat.BPn+1) = dat.or_v_ex(dat.BPn+1) + rand*dat.B_ext1(randi(2));     % �ngulo do bordo de fuga
            pop(i).v_ex(dat.BPn+2) = dat.or_v_ex(dat.BPn+2); %randi(dat.delta_range)*0.1*rand;   % delta_z
            
            % Vetor com informa��es do intradorso
            pop(i).v_in = pop(i).v_ex;
        
            % Checar o raio do bordo de ataque
            if pop(i).v_ex(1) < dat.le_R_ext1(3)
                pop(i).v_ex(1) = dat.le_R_ext1(3);
                pop(i).v_in(1) = pop(i).v_ex(1);
            end
            
            % Checar separa��o do bordo de fuga
            if pop(i).v_ex(dat.BPn+1) + pop(i).v_in(dat.BPn+1) < dat.B_ext2(1)
                pop(i).v_ex(dat.BPn+1) = dat.B_ext2(1)/2;
                pop(i).v_in(dat.BPn+1) = dat.B_ext2(1)/2;
            end
            
            pop(i).symm = 1;
            
        else % perfil assim�trico
            % Vetor com informa��es do extradorso
            pop(i).v_ex(1) = dat.or_v_ex(1) + rand*dat.le_R_ext1(randi(2));    % Raio do bordo de ataque
            for a = 2:dat.BPn
                pop(i).v_ex(a) = dat.or_v_ex(a) + rand*dat.A_ext1(randi(2));        % Pesos intermedi�rios
            end
            pop(i).v_ex(dat.BPn+1) = dat.or_v_ex(dat.BPn+1) + rand*dat.B_ext1(randi(2));     % �ngulo do bordo de fuga
            pop(i).v_ex(dat.BPn+2) = dat.or_v_ex(dat.BPn+2);  % delta_z
            
            % Vetor com informa��es do intradorso
            pop(i).v_in(1) = dat.or_v_in(1) + rand*dat.le_R_ext2(randi(2));                     % Raio do bordo de ataque
            for a = 2:dat.BPn
                pop(i).v_in(a) = dat.or_v_in(a) + rand*dat.A_ext2(randi(2));        % Pesos intermedi�rios
            end
            pop(i).v_in(dat.BPn+1) = (dat.B_ext2(1) - pop(i).v_ex(dat.BPn+1)) + rand*dat.B_ext2(2);     % �ngulo do bordo de fuga
            pop(i).v_in(dat.BPn+2) = dat.or_v_in(dat.BPn+2); 
            
            % Checar o raio do bordo de ataque
            if pop(i).v_ex(1) < dat.le_R_ext1(3)
                pop(i).v_ex(1) = dat.le_R_ext1(3);
            end
            if pop(i).v_in(1) < dat.le_R_ext2(3)
                pop(i).v_in(1) = dat.le_R_ext2(3);
            end
            
            % Checar separa��o do bordo de fuga (beta2>=L-beta1)
            if pop(i).v_in(dat.BPn+1) < dat.B_ext2(1) - pop(i).v_ex(dat.BPn+1)
                pop(i).v_in(dat.BPn+1) = dat.B_ext2(1) - pop(i).v_ex(dat.BPn+1);
            end
            
            % Checar os pesos (soma de pesos do intradorso deve ser menor ou
            % igual � soma de pesos do extradorso - pesos intermedi�rios)
            sum1 = sum(pop(i).v_ex(2:dat.BPn));
            sum2 = sum(pop(i).v_in(2:dat.BPn));
            if sum2 > sum1,continue,end
            
            pop(i).symm = 0;
        end
        
        % Checagem de qualidade
        check = quality(run_cst_TCC2(pop(i).v_ex,pop(i).v_in,dat),dat);
        
    end
end

if isequal(dat.or_v_ex,dat.or_v_in) || dat.symm_override == 1
    dat.symm_op = 1;
else
    dat.symm_op = 0;
end

% Gerar struct que guarda o melhor perfil de cada gera��o
archive = repmat(empty,dat.iter,1);

% Montar arquivo de input pro XFOIL
run_xfoil_cst_TCC2(dat,1);

%% Loop principal ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
for loop = 1:dat.iter
    
    % Simular os perfis e obter dados
    select = ones(1,dat.N);
    disp('<< Simula��o dos aerof�lios >>')
    for i = 1:dat.N
        disp(['Indiv�duo ' num2str(i)])
        
        run_cst_TCC2(pop(i).v_ex,pop(i).v_in,dat,1); 
        pop(i).aero = run_xfoil_cst_TCC2(dat,2);clc % Simula��o
        
        % Marcar indiv�duos que n�o tenham convergido na simula��o
        if pop(i).aero == 'n'
            select(i) = 0;
        end 
    end
        
    % Encontrar indiv�duos problem�ticos para j� ignor�-los durante a atribui��o
    % de pontua��o
    % select cont�m os indiv�duos com aero = 'n'; select2 cont�m os outros, que
    % convergiram nas simula��es
    select = find(select == 0); select2 = 1:dat.N;
    select2(select) = [];
    
    if length(select) == dat.N
        error('Nenhum aerof�lio convergiu nas simula��es')
    end
    
    % Atribuir pontua��es (fitnesses)
    pop = fitness_cst(pop,dat,select2);
    
    % Isto serve pra p�r todas as pontua��es em um vetor
    weights = [pop.score];

    % Mostrar o melhor perfil e comparar com o original
    [~,pos] = max(weights);
    figure(1),clf
    if dat.cases == 1 % Mostrar no t�tulo o n�mero da itera��o e os dados aerodin�micos
        plot_airfoil_cst_TCC2(2,run_cst_TCC2(pop(pos).v_ex,pop(pos).v_in,dat),loop,pop(pos)),hold on
    else % Mostrar no t�tulo apenas o n�mero da itera��o
        plot_airfoil_cst_TCC2(1,run_cst_TCC2(pop(pos).v_ex,pop(pos).v_in,dat),loop),hold on
    end
    plot_airfoil_cst_TCC2(3,run_cst_TCC2(dat.or_v_ex,dat.or_v_in,dat))
    legend('Otimizado','Original'),axis equal,grid on
    
    % Guardar o melhor perfil de cada itera��o
    archive(loop) = pop(pos);
%    for i = 1:4 % [apagar isto depois]
%        % As m�dias contabilizam apenas os indiv�duos que convergiram nas simula��es
%        temp = make_vector(pop,i,select2);
%        dat.aero_M(loop,i) = mean(temp(find(temp~=0)));
%    end

    % Parar o c�digo aqui na �ltima itera��o, j� que nesse cen�rio o resto
    % do c�digo � in�til
    if loop == dat.iter
        break
    end
    
    % Substituir indiv�duos com pontua��o nula ou negativa por aqueles com as
    % pontua��es mais altas
    if dat.subs == 1
        % Agora o vetor select tamb�m inclui indiv�duos que convergiram na
        % simula��o, mas que s�o extremamente inaptos (pontua��o negativa)
        select = find(weights <= 0);
        if length(select) <= length(select2) % Se o n�mero de aerof�lios com aero = 'n' for menor ou igual que o n�mero de aerof�lios com pontua��o
            % Preencher o vetor ind com os �ndices dos indiv�duos de maior pontua��o
            ind = zeros(1,length(select));
            temp = weights;
            for i = 1:length(ind)
                [~,ind(i)] = max(temp);
                temp(ind(i)) = -Inf;
            end
            % Substituir os indiv�duos
            k = 1;
            for i = [select]
                pop(i) = pop(ind(k));
                k = k + 1;
            end
            
        else 
            % Preencher o vetor ind com os �ndices dos indiv�duos de maior pontua��o (que acabam sendo todos aqueles apontados por select2)
            ind = select2;
            % Substituir os indiv�duos
            k = 1;
            for i = [select]
                pop(i) = pop(ind(k));
                k = k + 1;
                if k > length(ind),k = 1;end
            end
        end
    end
    
    % Escolher membros da popula��o pra reprodu��o
    c = 1;
    disp('<< Reprodu��o >>')
    for f = 1:dat.N/2
        fprintf('%.2f%% completo\n',f/(dat.N/2)*100)
        
        % Crossover, gerando dois filhos de cada dois pais
        % Aqui ignora-se os �ltimos dois par�metros (f e delta_z) porque eles
        % sempre ser�o iguais
        check = 0;
        while check == 0
            
            % Isto seleciona dois pais por meio de uma sele��o via roleta
            % (indiv�duos com pesos maiores t�m  mais chance de serem selecionados)
            par = [0,0]; % Vetor que indica a numera��o dos pais escolhidos
            par(1) = selection_crossover(weights);
            par(2) = selection_crossover(weights);
            
            % v = [ RLe A1 A2 A3 ... A(N) beta Dz ]
            if pop(par(1)).symm == 0 && pop(par(2)).symm == 0 % Se ambos forem assim�tricos
                n = randi([1,4]);
                switch n
                    case 1 % Trocar os extradorsos e intradorsos inteiros
                        chi(c).v_ex = pop(par(1)).v_ex;
                        chi(c).v_in = pop(par(2)).v_in;
                        chi(c+1).v_ex = pop(par(2)).v_ex;
                        chi(c+1).v_in = pop(par(1)).v_in;
                        
                    case 2 % Trocar o raio do bordo de ataque
                        chi(c).v_ex = [pop(par(1)).v_ex(1),pop(par(2)).v_ex(2:end)];
                        chi(c).v_in = [pop(par(1)).v_in(1),pop(par(2)).v_in(2:end)];
                        chi(c+1).v_ex = [pop(par(2)).v_ex(1),pop(par(1)).v_ex(2:end)];
                        chi(c+1).v_in = [pop(par(2)).v_in(1),pop(par(1)).v_in(2:end)];
                        
                    case 3 % Trocar os pesos intermedi�rios
                        if dat.BPn == 2
                            op = 1
                        else
                            op = randi([1 2]);
                        end
                        if op == 1 % Trocar tudo    
                            chi(c).v_ex = [pop(par(2)).v_ex(1),pop(par(1)).v_ex(2:dat.BPn),pop(par(2)).v_ex(dat.BPn+1:end)];
                            chi(c).v_in = [pop(par(2)).v_in(1),pop(par(1)).v_in(2:dat.BPn),pop(par(2)).v_in(dat.BPn+1:end)];
                            chi(c+1).v_ex = [pop(par(1)).v_ex(1),pop(par(2)).v_ex(2:dat.BPn),pop(par(1)).v_ex(dat.BPn+1:end)];
                            chi(c+1).v_in = [pop(par(1)).v_in(1),pop(par(2)).v_in(2:dat.BPn),pop(par(1)).v_in(dat.BPn+1:end)];
                        else % Trocar cortes
                            num1 = randi(2:dat.BPn);
                            num2 = randi(2:dat.BPn);
                            temp1_1 = [pop(par(1)).v_ex(2:num1),pop(par(2)).v_ex(num1+1:dat.BPn)];
                            temp1_2 = [pop(par(1)).v_in(2:num2),pop(par(2)).v_in(num2+1:dat.BPn)];
                            temp2_1 = [pop(par(2)).v_ex(2:num1),pop(par(1)).v_ex(num1+1:dat.BPn)];
                            temp2_2 = [pop(par(2)).v_in(2:num2),pop(par(1)).v_in(num2+1:dat.BPn)];
                            chi(c).v_ex = [pop(par(1)).v_ex(1),temp2_1,pop(par(1)).v_ex(dat.BPn+1:end)];
                            chi(c).v_in = [pop(par(1)).v_in(1),temp2_2,pop(par(1)).v_in(dat.BPn+1:end)];
                            chi(c+1).v_ex = [pop(par(2)).v_ex(1),temp1_1,pop(par(2)).v_ex(dat.BPn+1:end)];
                            chi(c+1).v_in = [pop(par(2)).v_in(1),temp1_2,pop(par(2)).v_in(dat.BPn+1:end)]; 
                        end
                        
                    case 4 % Trocar os �ngulos do bordo de fuga
                        chi(c).v_ex = [pop(par(2)).v_ex(1:dat.BPn),pop(par(1)).v_ex(dat.BPn+1),pop(par(2)).v_ex(dat.BPn+2)];
                        chi(c).v_in = [pop(par(2)).v_in(1:dat.BPn),pop(par(1)).v_in(dat.BPn+1),pop(par(2)).v_in(dat.BPn+2)];
                        chi(c+1).v_ex = [pop(par(1)).v_ex(1:dat.BPn),pop(par(2)).v_ex(dat.BPn+1),pop(par(1)).v_ex(dat.BPn+2)];
                        chi(c+1).v_in = [pop(par(1)).v_in(1:dat.BPn),pop(par(2)).v_in(dat.BPn+1),pop(par(1)).v_in(dat.BPn+2)];
                end
                
                if n == 1
                    % Checar a separa��o dos bordos de fuga. Se n�o cumprirem o 
                    % requisito de separa��o, alterar o �ngulo do bordo de fuga
                    % do intradorso
                    if chi(c).v_in(dat.BPn+1) < (dat.B_ext2(1)-chi(c).v_ex(dat.BPn+1))
                        chi(c).v_in(dat.BPn+1) = dat.B_ext2(1)-chi(c).v_ex(dat.BPn+1);
                    end
                    if chi(c+1).v_in(dat.BPn+1) < (dat.B_ext2(1)-chi(c+1).v_ex(dat.BPn+1))
                        chi(c+1).v_in(dat.BPn+1) = dat.B_ext2(1)-chi(c+1).v_ex(dat.BPn+1);
                    end
                    % Decis�o de alterar o intradorso em base de uma nota na p�gina
                    % 57(87) do Raymer (2018)
                end
                
                % Checar os pesos
                sum1 = sum(chi(c).v_ex(2:dat.BPn));
                sum2 = sum(chi(c).v_in(2:dat.BPn));
                if sum2 > sum1,continue,end
                sum1 = sum(chi(c+1).v_ex(2:dat.BPn));
                sum2 = sum(chi(c+1).v_in(2:dat.BPn));
                if sum2 > sum1,continue,end
                
                % Consertar o alinhamento do bordo de fuga (descomentar se o delta_z
                % for usado como vari�vel)
                %chi(c).v_in(dat.BPn) = -chi(c).v_ex(dat.BPn)*chi(c).v_ex(dat.BPn-1)/chi(c).v_in(dat.BPn-1);
                %chi(c+1).v_in(dat.BPn) = -chi(c+1).v_ex(dat.BPn)*chi(c+1).v_ex(dat.BPn-1)/chi(c+1).v_in(dat.BPn-1);
            
                chi(c).symm = 0;
                chi(c+1).symm = 0;
        
            elseif pop(par(1)).symm == 1 && pop(par(2)).symm == 1 % Se ambos forem sim�tricos
				n = randi([1,3]);
                switch n                        
                    case 1 % Trocar o raio do bordo de ataque
                        chi(c).v_ex = [pop(par(1)).v_ex(1),pop(par(2)).v_ex(2:end)];
                        chi(c).v_in = chi(c).v_ex;
                        chi(c+1).v_ex = [pop(par(2)).v_ex(1),pop(par(1)).v_ex(2:end)];
                        chi(c+1).v_in = chi(c+1).v_ex;
                        
                    case 2 % Trocar os pesos intermedi�rios
                        if dat.BPn == 2
                            op = 1
                        else
                            op = randi([1 2]);
                        end
                        if op == 1 % Trocar tudo    
                            chi(c).v_ex = [pop(par(2)).v_ex(1),pop(par(1)).v_ex(2:dat.BPn),pop(par(2)).v_ex(dat.BPn+1:end)];
                            chi(c).v_in = chi(c).v_ex;
                            chi(c+1).v_ex = [pop(par(1)).v_ex(1),pop(par(2)).v_ex(2:dat.BPn),pop(par(1)).v_ex(dat.BPn+1:end)];
                            chi(c+1).v_in = chi(c+1).v_ex;
                        else % Trocar cortes
                            num1 = randi(2:dat.BPn);
                            temp1_1 = [pop(par(1)).v_ex(2:num1),pop(par(2)).v_ex(num1+1:dat.BPn)];
                            temp2_1 = [pop(par(2)).v_ex(2:num1),pop(par(1)).v_ex(num1+1:dat.BPn)];
                            chi(c).v_ex = [pop(par(1)).v_ex(1),temp2_1,pop(par(1)).v_ex(dat.BPn+1:end)];
                            chi(c).v_in = chi(c).v_ex;
                            chi(c+1).v_ex = [pop(par(2)).v_ex(1),temp1_1,pop(par(2)).v_ex(dat.BPn+1:end)];
                            chi(c+1).v_in = chi(c+1).v_ex;
                        end
                        
                    case 3 % Trocar os �ngulos do bordo de fuga
                        chi(c).v_ex = [pop(par(2)).v_ex(1:dat.BPn),pop(par(1)).v_ex(dat.BPn+1),pop(par(2)).v_ex(dat.BPn+2)];
                        chi(c).v_in = [pop(par(2)).v_in(1:dat.BPn),pop(par(1)).v_in(dat.BPn+1),pop(par(2)).v_in(dat.BPn+2)];
                        chi(c+1).v_ex = [pop(par(1)).v_ex(1:dat.BPn),pop(par(2)).v_ex(dat.BPn+1),pop(par(1)).v_ex(dat.BPn+2)];
                        chi(c+1).v_in = [pop(par(1)).v_in(1:dat.BPn),pop(par(2)).v_in(dat.BPn+1),pop(par(1)).v_in(dat.BPn+2)];
                end
                
                chi(c).symm = 1;
                chi(c+1).symm = 1;
            
            else % Se um for sim�trico e o outro for assim�trico 
                % Transformar o sim�trico em um assim�trico e vice-versa
                % chi(c) � sim�trico e chi(c+1) � assim�trico
                if pop(par(1)).symm == 0 
                    chi(c).v_ex = pop(par(1)).v_ex;
                    chi(c).v_in = pop(par(1)).v_ex;
                    chi(c+1).v_ex = pop(par(2)).v_ex;
                    chi(c+1).v_in = pop(par(1)).v_in;
                else
                    chi(c).v_ex = pop(par(2)).v_ex;
                    chi(c).v_in = pop(par(2)).v_ex;
                    chi(c+1).v_ex = pop(par(1)).v_ex;
                    chi(c+1).v_in = pop(par(2)).v_in;
                end
                         
                
                % Checar a separa��o dos bordos de fuga. Se n�o cumprirem o 
                % requisito de separa��o, alterar o �ngulo do bordo de fuga
                % do intradorso
                if chi(c).v_in(dat.BPn+1) < (dat.B_ext2(1)-chi(c).v_ex(dat.BPn+1))
                    chi(c).v_ex = dat.B_ext2(1)/2;
                    chi(c).v_in = dat.B_ext2(1)/2;
                end
                if chi(c+1).v_in(dat.BPn+1) < (dat.B_ext2(1)-chi(c+1).v_ex(dat.BPn+1))
                    chi(c+1).v_in(dat.BPn+1) = dat.B_ext2(1)-chi(c+1).v_ex(dat.BPn+1);
                end
                % Decis�o de alterar o intradorso em base de uma nota na p�gina
                % 57(87) do Raymer (2018)
                
                
                % Checar os pesos
%                sum1 = sum(chi(c).v_ex(2:dat.BPn));
%                sum2 = sum(chi(c).v_in(2:dat.BPn));
%                if sum2 > sum1,continue,end
                sum1 = sum(chi(c+1).v_ex(2:dat.BPn));
                sum2 = sum(chi(c+1).v_in(2:dat.BPn));
                if sum2 > sum1,continue,end
                
                chi(c).symm = 1;
                chi(c+1).symm = 0;
                
            end
            
			% Checagem de qualidade
            check = quality(run_cst_TCC2(chi(c).v_ex,chi(c).v_in,dat),dat);
            if check == 0,continue,end
            check = quality(run_cst_TCC2(chi(c+1).v_ex,chi(c+1).v_in,dat),dat); 
			
        end
        c = c + 2;
    end
    
    % Muta��o
    select1 = (rand(size(pop)) <= dat.mu);
    if sum(select1) ~= 0
		clc,disp('<< Muta��o >>')
        select2 = find(select1 == 1);
        k = 1;
        for i = select2
            s = select2(k);
            disp(['Indiv�duo ' num2str(k) ' de ' num2str(length(select2))])
            
            
            
%            pop(i).v_ex(1) = dat.or_v_ex(1) + rand*dat.le_R_ext1(randi(2));    % Raio do bordo de ataque
%            for a = 2:dat.BPn
%                pop(i).v_ex(a) = dat.or_v_ex(a) + rand*dat.A_ext1(randi(2));        % Pesos intermedi�rios
%            end
%            pop(i).v_ex(dat.BPn+1) = dat.or_v_ex(dat.BPn+1) + rand*dat.B_ext1(randi(2));     % �ngulo do bordo de fuga
%            pop(i).v_ex(dat.BPn+2) = dat.or_v_ex(dat.BPn+2);  % delta_z
            
            
            
            check = 0;
            while check == 0
                
                temp = chi(s);
                if temp.symm == 1 % Caso o perfil seja sim�trico
                    n = [1,4,5](randi(3));
                else % Caso o perfil seja assim�trico
                    n = randi(5);
                end
                switch n
                    case 1 % Alterar o raio do bordo de ataque
                        if temp.symm == 1
                            P = 1;
                        else
                            p = randi([1,4]);
                        end
                        if p == 1 % Mudar ambos para o mesmo valor
                            temp.v_ex(1) = dat.or_v_ex(1) + rand*dat.le_R_ext1(randi(2));
                            temp.v_in(1) = temp.v_ex(1);
                        elseif p == 2 % Mudar ambos independentemente 
                            temp.v_ex(1) = dat.or_v_ex(1) + rand*dat.le_R_ext1(randi(2));
                            temp.v_in(1) = dat.or_v_in(1) + rand*dat.le_R_ext2(randi(2));
                        elseif p == 3 % Mudar do extradorso
                            temp.v_ex(1) = dat.or_v_ex(1) + rand*dat.le_R_ext1(randi(2));
                        else % Mudar do intradorso
                            temp.v_in(1) = dat.or_v_in(1) + rand*dat.le_R_ext2(randi(2));
                        end
                        
                        % Checar o raio do bordo de ataque (sim�tricos)
                        if temp.symm == 1 && temp.v_ex(1) < dat.le_R_ext1(3)
                            temp.v_ex(1) = dat.le_R_ext1(3);
                            temp.v_in(1) = temp.v_ex(1);
                        end
                        
                        % Checar o raio do bordo de ataque (assim�tricos)
                        if temp.symm == 0 && temp.v_ex(1) < dat.le_R_ext1(3)
                            temp.v_ex(1) = dat.le_R_ext1(3);
                        end
                        if temp.symm == 0 && temp.v_in(1) < dat.le_R_ext2(3)
                            temp.v_in(1) = dat.le_R_ext2(3);
                        end
                        
                    case 2 % Alterar os pesos intermedi�rios (extradorso) dentro de uma extens�o pr�xima aos valores originais
%                        num = rand(1,dat.BPn-1)*0.1;
                        for a = 2:dat.BPn
                            temp.v_ex(a) = dat.or_v_ex(a) + rand*dat.A_ext1(randi(2));
                        end
                        
                    case 3 % Alterar os pesos intermedi�rios (intradorso) dentro de uma extens�o pr�xima aos valores originais
%                        num = rand(1,dat.BPn-1)*0.1;
                        for a = 2:dat.BPn
                            temp.v_in(a) = dat.or_v_in(a) + rand*dat.A_ext2(randi(2));
                        end
                        
                    case 4 % Alterar os pesos intermedi�rios (extradorso e intradorso) dentro de uma extens�o pr�xima aos valores originais
                        if temp.symm == 1
%                            num = rand(1,dat.BPn-1)*0.1;
                            for a = 2:dat.BPn
                                temp.v_ex(a) =dat.or_v_ex(a) + rand*dat.A_ext1(randi(2));
                                temp.v_in(a) = temp.v_ex(a);
                            end
                        else
%                            num = rand(1,dat.BPn-1)*0.1;
                            for a = 2:dat.BPn
                                temp.v_ex(a) = dat.or_v_ex(a) + rand*dat.A_ext1(randi(2));
                            end
                            
%                            num = rand(1,dat.BPn-1)*0.1;
                            for a = 2:dat.BPn
                                temp.v_in(a) = dat.or_v_in(a) + rand*dat.A_ext2(randi(2));
                            end
                        end
                        
                    case 5 % Alterar o �ngulo do bordo de fuga 
                        if temp.symm == 1 % Se for sim�trico
                            temp.v_ex(dat.BPn+1) = dat.or_v_ex(dat.BPn+1) + rand*dat.B_ext1(randi(2));
                            temp.v_in(dat.BPn+1) = temp.v_ex(dat.BPn+1);
                            
                            % Checar separa��o do bordo de fuga
                            if temp.v_ex(dat.BPn+1) + temp.v_in(dat.BPn+1) < dat.B_ext2(1)
                                temp.v_ex(dat.BPn+1) = dat.B_ext2(1)/2;
                                temp.v_in(dat.BPn+1) = dat.B_ext2(1)/2;
                            end
                        else % Se for assim�trico
                            temp.v_ex(dat.BPn+1) = dat.or_v_ex(dat.BPn+1) + rand*dat.B_ext1(randi(2));
                            temp.v_in(dat.BPn+1) = (dat.B_ext2(1) - temp.v_ex(dat.BPn+1)) + rand*dat.B_ext2(2)
                            
                            % Checar separa��o do bordo de fuga (beta2>=L-beta1)
                            if temp.v_in(dat.BPn+1) < dat.B_ext2(1) - temp.v_ex(dat.BPn+1)
                                temp.v_in(dat.BPn+1) = dat.B_ext2(1) - temp.v_ex(dat.BPn+1);
                            end
                        end
                        
                end
                 
                % Checar os pesos (soma de pesos do intradorso deve ser menor ou
                % igual � soma de pesos do extradorso)
                sum1 = sum(temp.v_ex(2:dat.BPn));
                sum2 = sum(temp.v_in(2:dat.BPn));
                if sum2 > sum1
                    continue
                end
                
                % Checagem de qualidade
                check = quality(run_cst_TCC2(temp.v_ex,temp.v_in,dat),dat); 
                


                
                % Debugging: checar se o requisito de valor m�nimo dos raios do bordo de ataque est� sendo cumprido
                if temp.v_ex(1) < dat.le_R_ext1(3) || temp.v_in(1) < dat.le_R_ext2(3)
                    error('Valor m�nimo de raio de bordo de ataque n�o cumprido')
                end
                
            end
            chi(s) = temp;
            k = k + 1;
        end
    end

    % substituir a popula��o inicial pelos filhos
    pop = chi;
    
    % Aplicar elitismo
    if dat.elite == 1
        % Passar o melhor indiv�duo pra nova popula��o
        pop(1) = archive(loop);
        pop(1).score = 0;
    end
    
end



%% Final ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% Fazer simula��o do aerof�lio original para fins de compara��o
run_cst_TCC2(dat.or_v_ex,dat.or_v_in,dat,1);
original.aero = run_xfoil_cst_TCC2(dat,2);

clc,    %sound(y2,Fs2)
t = toc;
min = fix(t/60); s = rem(t,60);
fprintf('Tempo: %d min e %.2f s\n', min, s)

% Fazer gr�ficos dos coeficientes dos melhores indiv�duos de cada gera��o
for i = 1:dat.cases
    aero_m = zeros(dat.iter,4);
    for j = 1:dat.iter
        aero_m(j,:) = archive(j).aero(i,:);
    end
    figure(i+1),clf,hold on,grid on
    h1 = plot(1:dat.iter,aero_m(:,1)','g-*');
    h2 = plot(1:dat.iter,aero_m(:,2)','r-*');
    [hax,h4,h3] = plotyy(1:dat.iter,aero_m(:,4)',1:dat.iter,aero_m(:,3)');
    set(h3,'color','k'),set(h3,'marker','*'),set(h4,'color','b'),set(h4,'marker','*')
    lines = [h1,h2,h3,h4]; legend(lines,'CL','CD','CM','L/D');
    legend([h1,h2,h3,h4],'CL','CD','L/D','CM');
    xlabel(hax(1),'Itera��o')
    ylabel(hax(1),'CL, CD e CM')
    ylabel(hax(2),'L/D')
    title(['Melhores resultados - Condi��o de voo ' num2str(i) ':  Re ' num2str(dat.reynolds(i)) ', AoA ' num2str(dat.aoa(i)) '�'])
    
    % Trocar espa�ador decimal
    xl = get(gca,'XTickLabel'); yl = get(gca,'YTickLabel');
    new_xl = strrep(xl(:),'.',','); new_yl = strrep(yl(:),'.',',');
    set(gca,'XTickLabel',new_xl), set(gca,'YTickLabel',new_yl)

end

%% Pegar o struct de arquivo e imprimir todos
fprintf('Grau do polin�mio: %d\n',dat.BPn)
for i = 1:length(archive)
    disp(['<< Itera��o ' num2str(i) ' >>'])
    
    fprintf('v_ex = [%.4f, ', archive(i).v_ex(1))
    for j = 2:(length(pop(1).v_ex)-3)
        fprintf('%.4f, ',archive(i).v_ex(j))
    end
    fprintf('%.4f, ', archive(i).v_ex(end-2))
    fprintf('%.4f, ', archive(i).v_ex(end-1))
    fprintf('%.4f];\n', archive(i).v_ex(end))
    
    fprintf('v_in = [%.4f, ', archive(i).v_in(1))
    for j = 2:(length(pop(1).v_in)-3)
        fprintf('%.4f, ',archive(i).v_in(j))
    end
    fprintf('%.4f, ', archive(i).v_in(end-2))
    fprintf('%.4f, ', archive(i).v_in(end-1))
    fprintf('%.4f];\n', archive(i).v_in(end))
    for j = 1:dat.cases
        fprintf('Condi��o de voo %d (CL,CD,L/D,CM)\nOriginal: ',j),disp(original.aero(j,:))
        fprintf('Otimizado: '),disp(archive(i).aero(j,:))
    end
    fprintf('Pontua��o: '),disp(archive(i).score)
    disp('')
end




% Fazer gr�fico das m�dias dos coeficientes [apagar isto depois]
%figure(10),clf
%h1 = plot(1:dat.iter,dat.aero_M(:,1)','g-*');hold on,grid on
%h2 = plot(1:dat.iter,dat.aero_M(:,2)','r-*');
%[hax,h4,h3] = plotyy(1:dat.iter,dat.aero_M(:,4)',1:dat.iter,dat.aero_M(:,3)');
%set(h3,'color','k'),set(h3,'marker','*'),set(h4,'color','b'),set(h4,'marker','*')
%legend([h1,h2,h3,h4],'CL','CD','L/D','CM');
%xlabel(hax(1),'Itera��o')
%ylabel(hax(1),'CL, CD e CM')
%ylabel(hax(2),'L/D')
%title('M�dias dos coeficientes em cada itera��o')

% Template de comando pra pegar coordenadas e um gr�fico de determinado perfil
%clf,plot_airfoil_cst_TCC2(4,run_cst_TCC2(v_ex,v_in,dat,0)),grid on,axis equal

%figure(2),saveas(gcf,'fig1.png')
%figure(3),saveas(gcf,'fig2.png')
%dat.or_v_ex = [0.019257, 0.186300, 0.249870, 0.157309, 0.235440, 0.188924, 12.410294, -0.000000]; % Este � um perfil NACA 4 d�gitos
%dat.or_v_in = [0.011473, 0.115911, 0.093905, 0.101085, 0.080645, 0.078528, 4.450847, -0.000000];
%figure(10),saveas(gcf,'aoba.png')