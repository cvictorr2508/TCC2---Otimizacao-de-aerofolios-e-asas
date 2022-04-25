% Nota: modifica��o na fun��o run_apame: altera��o do L/D pra L^(3/2)/D




%% Algoritmo gen�tico
% Otimiza��o de asas trapezoidais simples ou duplas, com perfis NACA 4 d�gitos

% O APAME calcula apenas escoamentos inv�scidos, portanto, estimativas de arrasto
% n�o ser�o precisas. Adicionalmente, devido � natureza de escoamentos inv�scidos,
% os par�metros de velocidade de refer�ncia, press�o atmosf�rica e densidade do
% ar n�o afetam os coeficientes considerados na otimiza��o, e seriam relevantes
% para a obten��o de dados como distribui��o de velocidades e press�o. Finalmente,
% o n�mero de mach tem um ligeiro efeito nos resultados dos coeficientes devido
% �s corre��es dos efeitos de compressibilidade. Mais detalhes podem ser encontrdos
% na documenta��o do APAME.





% Nota pra posterioridade: grandes quantidades de pontos nos aerof�lios (np)
% tendem a fazer o apame travar de vez em quando


% A fazer:
% P�r na checagem de erros tudo o que for referente �s op��es 'L'
% P�r na checagem de erro tudo referente �s fun��es objetivas 'q' e '|'
% Retirar o n�mero de reynolds deste algoritmo?




clear,clc
fclose('all');
tic

% Par�metros do algoritmo
dat.N = 500;                              % N�mero de indiv�duos na popula��o
dat.mu = 0.05;                           % Probabilidade de muta��o (definida entre zero e um)
dat.iter = 5;                           % N�mero de itera��es
dat.elite = 1;                         % Aplicar elitismo?
dat.subs = 1;                          % Substituir asas sem resultados? (ver ainda se isto ser� necess�rio)
dat.aero_M = zeros(dat.iter,4);  % [Tirar isto depois] (e apagar a fun��o make_vector tamb�m)

% Par�metros da geometria: planta da asa
dat.planf_op = 0.5; % Propor��o de asas trapezoidais simples e bitrapezoidais (0->todas trapezoidais simples, 1->todas bitrapezoidais)
dat.b_ext_in = [10,15]; % Envergadura completa [m] (extens�o inicial)
dat.b_step = 0.5; % Valor do passo para defini��o das extens�es de envergadura [m]
dat.b1_ext_in = [8,14,0.5]; % Envergadura da raiz ao meio [m] (asas bitrapezoidais apenas) (valor m�nimo,valor m�ximo,separa��o m�nima da ponta da asa (considerando apenas uma metade)) (extens�o inicial)
dat.b1_step = 0.5; % Valor do passo para defini��o das extens�es da envergadura da primeira se��o [m]
dat.c_r_ext_in = [1,2]; % Corda da raiz [m] (extens�o inicial)
dat.c_r_step = 0.1; % Valor do passo para defini��o das extens�es da corda da raiz [m]
dat.c_m_ext_in = [0.5,2]; % Corda do meio [m] (asas bitrapezoidais apenas) (extens�o inicial) (a op��o 'L' for�a o formato trapezoidal simples)
dat.c_m_step = 0.1; % Valor do passo para defini��o das extens�es da corda do meio [m]
dat.c_t_ext_in = [0.5,2]; % Corda da ponta [m] (extens�o inicial)
dat.c_t_step = 0.1; % Valor do passo para defini��o das extens�es da corda da raiz [m]
dat.sweep_ext_in = [0,15]; % Enflechamento de asas trapezoidais simples (extens�o inicial) (op��o 'Z' faz com que a linha c/2 tenha enflechamento zero)
dat.sweep_step = 1; % Valor do passo para defini��o das extens�es do enflechamento
dat.sweep1_ext_in = [0,15]; % Enflechamento da primeira se��o de asas trapezoidais duplas(extens�o inicial) (op��o 'Z' faz com que a linha c/2 tenha enflechamento zero)
dat.sweep1_step = 1; % Valor do passo para defini��o das extens�es do enflechamento
dat.sweep2_ext_in = [0,15]; % Enflechamento da segunda se��o de asas trapezoidais duplas(extens�o inicial) (op��o 'Z' faz com que a linha c/2 tenha enflechamento zero)
dat.sweep2_step = 1; % Valor do passo para defini��o das extens�es do enflechamento
% Par�metros da geometria: aerof�lio da raiz
dat.m_ext_r = [0,4]; % Curvatura m�xima
dat.p_ext_r = [1,4]; % Local da curvatura m�xima
dat.t_ext_r = [10,20]; % Espessura m�xima 
% Par�metros da geometria: aerof�lio do meio (asas bitrapezoidais apenas) 
dat.m_ext_m = [0,4]; % (a op��o 'L' aqui gera o perfil do meio linearmente em fun��o dos perfis da raiz e da ponta)
dat.p_ext_m = [1,4];
dat.t_ext_m = [10,20];
% Par�metros da geometria: aerof�lio da ponta
dat.m_ext_t = [0,4];
dat.p_ext_t = [1,4];
dat.t_ext_t = [10,20];
dat.tw_t_ext_in = [-5,0]; % Tor��o geom�trica [�]
dat.tw_t_step = 0.5; % Valor do passo para defini��o das extens�es da tor��o geom�trica na ponta [�]

% Par�metros da malha
dat.np = 30; % N�mero de pontos na gera��o de ordenadas nos aerof�lios
dat.np_op = 1; % 1 -> cosspace, 0 -> cosspace_half
dat.nb = [2,1]; % N�mero de se��es intermedi�rias (raiz/ponta) [n�mero de se��es,0] ou [concentra��o por metro,1]
dat.nb1 = 'L'; % N�mero de se��es intermedi�rias (raiz/meio) (asas bitrapezoidais apenas) (op��o 'L' faz com que nb1 e nb2 sejam uniformemente determinados ao longo da envergadura)
dat.nb2 = []; % N�mero de se��es intermedi�rias (meio/ponta) (asas bitrapezoidais apenas)

% Par�metros das simula��es
dat.cases = 2;                          % N�mero de condi��es de voo a serem analisadas
dat.v_ref = [100,100,100]; % Velocidades de refer�ncia [m/s] 
dat.rho = [1.225,1.225,1.225]; % Densidades do ar [kg/m^3] 
dat.p_atm = [101325,101325,101325]; % Press�es do ar [Pa] (irrelevante neste algoritmo)
dat.mach = [0,0.,0.2]; % N�meros de Mach
dat.reynolds = [1e6,1e6,1e6];           % Valores dos n�meros de Reynolds para as simula��es (irrelevante neste algoritmo))
dat.aoa = [0,4,4];                     % �ngulos de ataque
dat.coeff_op = ['o','^','!','c';       % Uma linha para cada condi��o de voo
                '!','!','!','!';
                '!','!','!','!'];
dat.coeff_val = [0.2,7e-3,90,-1e-1;
                 0.5,0,0,-0.08;
                 0,0,0,-0.08];
dat.coeff_F = [1,1,1,1;
               1,1,1,1;
               1,1,1,1];
% [CL CD L/D CM] Defini��o de cada linha da matriz dat.coeff_op
% '!' -> n�o usar como fun��o objetiva
% '^' -> procurar por um valor m�ximo (CL e L/D) ou valor m�nimo (CD)
% 'c' -> buscar valor constante de coeficiente de momento (arbitr�rio)
% 'k' -> buscar valor constante de coeficiente de momento (espec�fico, de dat.coeff_val(1,4))
% 'o' -> procurar por um valor espec�fico (qualquer um dos par�metros). Nesse caso, definir o valor
% em sua respectiva casa na matriz dat.coeff_val
% 'q' -> procurar por um valor espec�fico de for�a de sustenta��o, for�a de arrasto
% ou momento de arfagem (CL, CD e CM). Nesse caso, definir o valor em sua casa na matriz dat.coeff_val
% '#' -> procurar por um valor m�ximo (L) ou m�nimo (D)
% A matriz dat.coeff_F d� os pesos de cada fun��o objetiva

% Checagem de erros
dat = error_check_naca4_3D(dat);

% Template dos structs
% Forma da planta
empty.type = [];
empty.b = [];
empty.b1 = []; 
empty.c_r = []; 
empty.c_m = []; 
empty.c_t = [];
empty.mac = [];
empty.S = [];
empty.sweep = [];
empty.sweep1 = [];
empty.sweep2 = [];
% Aerof�lios (todos ser�o definidos com vetores [m,p,t])
empty.af_r = zeros(1,3);
empty.af_m = zeros(1,3);
empty.af_t = zeros(1,3);
empty.tw_m = [];
empty.tw_t = [];
% Dados da malha
empty.NODE = [];
empty.PANEL = [];
empty.sec_N = [];
% Dados aerodin�micos e pontua��o
empty.aero = []; % Ter� o mesmo formato que a matriz coeff_op
empty.score = 0;

% Inicializar
pop = repmat(empty,dat.N,1);
chi = pop;

% Redefinir as extens�es dos valores das vari�veis a partir das extens�es iniciais
% (precis�o dos valores podem ser alteradas aqui)
dat.b_ext = dat.b_ext_in(1):dat.b_step:dat.b_ext_in(2);
dat.c_r_ext = dat.c_r_ext_in(1):dat.c_r_step:dat.c_r_ext_in(2);
dat.tw_t_ext = dat.tw_t_ext_in(1):dat.tw_t_step:dat.tw_t_ext_in(2);
if ~ismember('Z',dat.sweep_ext_in),dat.sweep_ext = dat.sweep_ext_in(1):dat.sweep_step:dat.sweep_ext_in(2);end
if ~ismember('Z',dat.sweep1_ext_in),dat.sweep1_ext = dat.sweep1_ext_in(1):dat.sweep1_step:dat.sweep1_ext_in(2);end
if ~ismember('Z',dat.sweep2_ext_in),dat.sweep2_ext = dat.sweep2_ext_in(1):dat.sweep2_step:dat.sweep2_ext_in(2);end
% As demais extens�es de valores ser�o definidos para cada indiv�duo a seguir 
% de modo a cumprir os seguintes requisitos:
% b1 < b
% c_r >= c_m >= c_t
% ATEN��O: P�R ISTO NA CHECAGEM DE ERROS DEPOIS

% Gerar popula��o inicial
disp('<< Gera��o da popula��o inicial >>')
for i = 1:dat.N
    disp(['Indiv�duo ' num2str(i)])
    
    % Estabelecer tipo da planta
    % 0 -> trapezoidal simples, 1 -> bitrapezoidal
    pop(i).type = rand <= dat.planf_op;
    
    % Gerar forma da planta
    pop(i).b = dat.b_ext(randi(length(dat.b_ext)));
    pop(i).c_r = dat.c_r_ext(randi(length(dat.c_r_ext)));
    if dat.c_t_ext_in(2) > pop(i).c_r
        % Caso, nesta asa, o valor m�ximo da extens�o da corda da ponta seja 
        % maior do que a corda da raiz, usar a corda da raiz atual como 
        % o valor m�ximo da extens�o
        dat.c_t_ext = dat.c_t_ext_in(1):dat.c_t_step:pop(i).c_r;
    else
        % Caso contr�rio, usar os valores definidos pelo usu�rio em dat.c_t_ext_in
        dat.c_t_ext = dat.c_t_ext_in(1):dat.c_t_step:dat.c_t_ext_in(2);
    end
    pop(i).c_t = dat.c_t_ext(randi(length(dat.c_t_ext)));
    pop(i).tw_t = dat.tw_t_ext(randi(length(dat.tw_t_ext)));
    
    % Gerar aerof�lio da raiz
    pop(i).af_r(1) = randi(dat.m_ext_r); % Curvatura m�xima
    if pop(i).af_r(1) == 0 % Perfis sim�tricos
        pop(i).af_r(2) = 0;
    else % Perfis assim�tricos
        pop(i).af_r(2) = randi(dat.p_ext_r);
    end
    pop(i).af_r(3) = randi(dat.t_ext_r); % Espessura m�xima
    
    % Gerar aerof�lio da ponta
    pop(i).af_t(1) = randi(dat.m_ext_t); % Curvatura m�xima
    if pop(i).af_t(1) == 0 % Perfis sim�tricos
        pop(i).af_t(2) = 0;
    else % Perfis assim�tricos
        pop(i).af_t(2) = randi(dat.p_ext_t);
    end
    pop(i).af_t(3) = randi(dat.t_ext_t); % Espessura m�xima
    
    % Dados adicionais para asas bitrapezoidais
    if pop(i).type == 1 
        % Mais dados da planta
        if ismember('L',dat.c_m_ext_in)
            % Caso c_m seja definido como 'L', seu valor real ser� atrib�ido pela
            % fun��o run_apame_mesher_naca4
            pop(i).c_m = 'L';
        else    
            % Caso contr�rio, � realizado o processo abaixo
            dat.c_m_ext = [0,0];
            if dat.c_m_ext_in(1) < pop(i).c_t
                % Caso o valor m�nimo da extens�o da corda do meio seja menor do que
                % a corda da ponta da asa atual, usar o valor da corda da ponta da
                % asa como o valor m�nimo da extens�o
                dat.c_m_ext(1) = pop(i).c_t;
            else   
                % Caso contr�rio, usar o valor original
                dat.c_m_ext(1) = dat.c_m_ext_in(1);
            end
            if dat.c_m_ext_in(2) > pop(i).c_t
                % Caso o valor mpaximo da extens�o da corda do meio seja maior do que
                % a corda da raiz da asa atual, usar o valor da corda da raiz da
                % asa como o valor m�nimo da extens�o
                dat.c_m_ext(2) = pop(i).c_r;
            else
                % Caso contr�rio, usar o valor original
                dat.c_m_ext(2) = dat.c_m_ext_in(2);
            end
            pop(i).c_m = dat.c_m_ext(randi(length(dat.c_m_ext)));
        end
        
        if dat.b1_ext_in(2) > pop(i).b-dat.b1_ext_in(3)*2
            % Se, nesta asa, o valor m�ximo da extens�o de b1 for maior do que
            % o valor m�ximo permitido pelo requisito de separa��o, utilizar
            % a envergadura da asa atual menos a separa��o m�nima como valor
            % m�ximo da extens�o
            % O valor da separa��o m�nima � utilizado para garantir que b1 ~= b
            dat.b1_ext = dat.b1_ext_in(1):dat.b1_step:pop(i).b-dat.b1_ext_in(3)*2;
        else
            % Caso contr�rio, utilizar a extens�o original definida em dat.b1_ext_in
            dat.b1_ext = dat.b1_ext_in(1):dat.b1_step:dat.b1_ext_in(2);
        end
        pop(i).b1 = dat.b1_ext(randi(length(dat.b1_ext)));

        % Aerof�lio do meio
        pop(i).tw_m = 'L'; % Essa sempre ser� a configura��o deste algoritmo, mas isso pode ser alterado (com as devidas altera��es no resto do c�digo)
        pop(i).af_m(1) = randi(dat.m_ext_m); % Curvatura m�xima
        if pop(i).af_m(1) == 0 % Perfis sim�tricos
            pop(i).af_m(2) = 0;
        else % Perfis assim�tricos
            pop(i).af_m(2) = randi(dat.p_ext_m);
        end
        pop(i).af_m(3) = randi(dat.t_ext_m); % Espessura m�xima
    
        % Enflechamento da primeira se��o
        if ~ismember('Z',dat.sweep1_ext_in)
            pop(i).sweep1 = dat.sweep1_ext(randi(length(dat.sweep1_ext)));
        else
            pop(i).sweep1 = 'Z';
        end
        % Enflechamento da segunda se��o
        if ~ismember('Z',dat.sweep2_ext_in)
            pop(i).sweep2 = dat.sweep2_ext(randi(length(dat.sweep2_ext)));
        else
            pop(i).sweep2 = 'Z';
        end
        
    else % Estabelecer enflechamento da asa trapezoidal simples
        if ~ismember('Z',dat.sweep_ext_in)
            pop(i).sweep = dat.sweep_ext(randi(length(dat.sweep_ext)));
        else
            pop(i).sweep = 'Z';
        end
    
    end
    
end

% Gerar struct que guarda a melhor asa de cada gera��o
archive = repmat(empty,dat.iter,1);

%% Loop principal ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
for loop = 1:dat.iter
    
    % Simular as asas e obter dados
    select = ones(1,dat.N);
    disp('<< Simula��o das asas >>')
    for i = 1:dat.N
        disp(['Indiv�duo ' num2str(i)])
        pop(i) = run_apame_mesher_naca4(pop(i),dat); % Obter malha
        pop(i).aero = run_apame(pop(i),dat); % Simula��o
        
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
        error('Nenhuma asa convergiu nas simula��es')
	end
    
    % Atribuir pontua��es (fitnesses)
    pop = fitness_naca4_3D(pop,dat,select2);
    
    % Isto serve pra p�r todas as pontua��es em um vetor
    weights = [pop.score];
    
    % Guardar a melhor asa de cada itera��o
    [~,pos] = max(weights);
    archive(loop) = pop(pos);
    for i = 1:4 % [apagar isto depois]
        % As m�dias contabilizam apenas os indiv�duos que convergiram nas simula��es
        temp = make_vector(pop,i,select2);
        dat.aero_M(loop,i) = mean(temp(find(temp~=0)));
    end
    
    % Mostrar a melhor asa
    figure(1),clf,figure(2),clf
    text = ['Itera��o ' num2str(loop)];
    run_apame_mesher_naca4(pop(pos),dat,2,2,1,2,text);
    
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
		
        % Isto seleciona dois pais por meio de uma sele��o via roleta
        % (indiv�duos com pesos maiores t�m  mais chance de serem selecionados)
        par = [0,0]; % Vetor que indica a numera��o dos pais escolhidos
        par(1) = selection_crossover(weights);
        par(2) = selection_crossover(weights);
        
        % Crossover, gerando dois filhos de cada dois pais
        % Genes a serem trocados
        % Envergadura b
        % Envergadura b1 (asas bitrapezoidais apenas)
        % Corda da raiz
        % Corda do meio (asas bitrapezoidais apenas)
        % Corda da ponta
        % - aerof�lio da raiz
        % - aerof�lio do meio (asas bitrapezoidais apenas)
        % - aerof�lio da ponta
        % Tor��o geom�trica na ponta
        % Enflechamento total (asas trapezoidais simples)
        % Enflechamento da primeira se��o (asas bitrapezoidais)
        % Enflechamento da segunda se��o (asas bitrapezoidais)

        if pop(par(1)).type ~= pop(par(2)).type % Caso as asas sejam de tipos diferentes
            op = randi([1,2]);
        else
            op = 1; % Caso as asas sejam de tipos iguais
        end
        
        if op == 1 % Fazer crossover normalmente (trocar genes gerais)
            % Escrever um vetor de op��es:
            % [b,b1,c_r,c_m,c_t,airfoil_r,airfoil_m,airfoil_t,tw_t]
            cross_op_v = randi([0,1],1,12);
            
            chi(c) = pop(par(1));
            chi(c+1) = pop(par(2));
            
            % Envergadura b
            if cross_op_v(1) == 1
                chi(c).b = pop(par(2)).b;                
                chi(c+1).b = pop(par(1)).b;
            end 
        
            % Envergadura da primeira se��o b1 (asas bitrapezoidais apenas) (deve cumprir o requisito de separa��o m�nima)
            if cross_op_v(2) == 1 && pop(par(1)).type == 1 && pop(par(2)).type == 1 %&& pop(par(1)).b1 <= pop(par(2)).b - dat.b1_ext_in(3)*2 && pop(par(2)).b1 <= pop(par(1)).b - dat.b1_ext_in(3)*2
                chi(c).b1 = pop(par(2)).b1;
                chi(c+1).b1 = pop(par(1)).b1;
            end
            
            % Corda da raiz c_r (deve cumprir o requisito c_r >= c_t)
%            if cross_op_v(3) == 1 && pop(par(1)).c_r >= pop(par(2)).c_t && pop(par(2)).c_r >= pop(par(1)).c_t
			if cross_op_v(3) == 1 && chi(c).c_r >= chi(c+1).c_t && chi(c+1).c_r >= chi(c).c_t
                chi(c).c_r = pop(par(2)).c_r;
                chi(c+1).c_r = pop(par(1)).c_r;
            end
            
            % Corda da ponta c_t (deve cumprir o requisito c_r >= c_t)
%            if cross_op_v(4) == 1 && pop(par(1)).c_r >= pop(par(2)).c_t && pop(par(2)).c_r >= pop(par(1)).c_t 
			if cross_op_v(4) == 1 && chi(c).c_r >= chi(c+1).c_t && chi(c+1).c_r >= chi(c).c_t
                chi(c).c_t = pop(par(2)).c_t;
                chi(c+1).c_t = pop(par(1)).c_t;
            end
            
            % Corda do meio c_m (asas bitrapezoidais apenas) (deve cumprir o requisito c_r >= c_m >= c_t) (ignorar caso a op��o 'L' seja aplicada a c_m)
            if cross_op_v(5) == 1 && pop(par(1)).type == 1 && pop(par(2)).type == 1 && ~ismember('L',dat.c_m_ext_in) %&& pop(par(1)).c_r >= pop(par(2)).c_m && pop(par(1)).c_m >= pop(par(2)).c_t && pop(par(2)).c_r >= pop(par(1)).c_m && pop(par(2)).c_m >= pop(par(1)).c_t 
                chi(c).c_m = pop(par(2)).c_m;
                chi(c+1).c_m = pop(par(1)).c_m;
            end
            
            % Corre��es referentes � planta da asa (asas bitrapezoidais apenas)
            if chi(c).type == 1
                
                % Se a envergadura da primeira se��o for maior do que permitido
                % pelo requisito de separa��o, atribuir o m�ximo valor que 
                % cumpre o requisito
                if chi(c).b1 > chi(c).b-dat.b1_ext_in(3)*2
                    chi(c).b1 = chi(c).b-dat.b1_ext_in(3)*2;
                end
                
                % Se a corda do meio for maior do que a corda da raiz, atribuir
                % o valor da raiz ao meio
                if chi(c).c_m > chi(c).c_r  && ~ismember('L',dat.c_m_ext_in)
                    chi(c).c_m = chi(c).c_r;
                end
                
                % Se a corda do meio for menor que a corda da ponta, atribuir
                % o valor da ponta ao meio
                if chi(c).c_m < chi(c).c_t && ~ismember('L',dat.c_m_ext_in)
                    chi(c).c_m = chi(c).c_t;
                end
                
            end
            if chi(c+1).type == 1
                % Se a envergadura da primeira se��o for maior do que permitido
                % pelo requisito de separa��o, atribuir o m�ximo valor que 
                % cumpre o requisito
                if chi(c+1).b1 > chi(c+1).b-dat.b1_ext_in(3)*2
                    chi(c+1).b1 = chi(c+1).b-dat.b1_ext_in(3)*2;
                end
                
                % Se a corda do meio for maior do que a corda da raiz, atribuir
                % o valor da raiz ao meio
                if chi(c+1).c_m > chi(c+1).c_r && ~ismember('L',dat.c_m_ext_in)
                    chi(c+1).c_m = chi(c+1).c_r;
                end
                
                % Se a corda do meio for menor que a corda da ponta, atribuir
                % o valor da ponta ao meio
                if chi(c+1).c_m < chi(c+1).c_t && ~ismember('L',dat.c_m_ext_in)
                    chi(c+1).c_m = chi(c+1).c_t;
                end
            end
            
            % Aerof�lio da raiz
            if cross_op_v(6) == 1 
            
                af1 = chi(c).af_r;
                af2 = chi(c+1).af_r;
                
                if af1(1) == 0 || af2(1) == 0 % Caso um deles seja sim�trico
                    n = randi(2);
                else
                    n = randi(4);
                end
                
                switch n
                    case 1 % Trocar os perfis completamente
                        chi(c).af_r = af2;
                        chi(c+1).af_r = af1;
                    
                    case 2 % Trocar a espessura m�xima
                        temp1 = [af1(1:2),af2(3)];
                        temp2 = [af2(1:2),af1(3)];
                        if randi([0,1]) == 1 % Decidir pra qual asa vai cada um dos aerof�lios novos
                            chi(c).af_r = temp1;
                            chi(c+1).af_r = temp2;
                        else
                            chi(c).af_r = temp2;
                            chi(c+1).af_r = temp1;
                        end
                        
                    case 3 % Trocar o local da curvatura m�xima
                        temp1 = [af1(1),af2(2),af1(3)];
                        temp2 = [af2(1),af1(2),af2(3)];
                        
                        if randi([0,1]) == 1 % Decidir pra qual asa vai cada um dos aerof�lios novos
                            chi(c).af_r = temp1;
                            chi(c+1).af_r = temp2;
                        else
                            chi(c).af_r = temp2;
                            chi(c+1).af_r = temp1;
                        end
                        
                    case 4 % Trocar a curvatura m�xima
                        temp1 = [af1(1),af2(2:3)];
                        temp2 = [af2(1),af1(2:3)];
                        if randi([0,1]) == 1 % Decidir pra qual asa vai cada um dos aerof�lios novos
                            chi(c).af_r = temp1;
                            chi(c+1).af_r = temp2;
                        else
                            chi(c).af_r = temp2;
                            chi(c+1).af_r = temp1;
                        end
                end
            end
            
            % Aerof�lio do meio (asas bitrapezoidais apenas) (ignorar caso a op��o 'L' seja aplicada ao aerof�lio do meio)
            if cross_op_v(7) == 1 && pop(par(1)).type == 1 && pop(par(2)).type == 1 && ~ismember('L',[dat.m_ext_m,dat.p_ext_m,dat.t_ext_m])
                af1 = chi(c).af_m;
                af2 = chi(c+1).af_m;
                
                if af1(1) == 0 || af2(1) == 0 % Caso um deles seja sim�trico
                    n = randi(2);
                else
                    n = randi(4);
                end
                
                switch n
                    case 1 % Trocar os perfis completamente
                        chi(c).af_m = af2;
                        chi(c+1).af_m = af1;
                    
                    case 2 % Trocar a espessura m�xima
                        temp1 = [af1(1:2),af2(3)];
                        temp2 = [af2(1:2),af1(3)];
                        if randi([0,1]) == 1 % Decidir pra qual asa vai cada um dos aerof�lios novos
                            chi(c).af_m = temp1;
                            chi(c+1).af_m = temp2;
                        else
                            chi(c).af_m = temp2;
                            chi(c+1).af_m = temp1;
                        end
                        
                    case 3 % Trocar o local da curvatura m�xima
                        temp1 = [af1(1),af2(2),af1(3)];
                        temp2 = [af2(1),af1(2),af2(3)];
                        
                        if randi([0,1]) == 1 % Decidir pra qual asa vai cada um dos aerof�lios novos
                            chi(c).af_m = temp1;
                            chi(c+1).af_m = temp2;
                        else
                            chi(c).af_m = temp2;
                            chi(c+1).af_m = temp1;
                        end
                        
                    case 4 % Trocar a curvatura m�xima
                        temp1 = [af1(1),af2(2:3)];
                        temp2 = [af2(1),af1(2:3)];
                        if randi([0,1]) == 1 % Decidir pra qual asa vai cada um dos aerof�lios novos
                            chi(c).af_m = temp1;
                            chi(c+1).af_m = temp2;
                        else
                            chi(c).af_m = temp2;
                            chi(c+1).af_m = temp1;
                        end
                end
            end
            
            % Aerof�lio da ponta
            if cross_op_v(8) == 1 
                af1 = chi(c).af_t;
                af2 = chi(c+1).af_t;
                
                if af1(1) == 0 || af2(1) == 0 % Caso um deles seja sim�trico
                    n = randi(2);
                else
                    n = randi(4);
                end
                
                switch n
                    case 1 % Trocar os perfis completamente
                        chi(c).af_t = af2;
                        chi(c+1).af_t = af1;
                    
                    case 2 % Trocar a espessura m�xima
                        temp1 = [af1(1:2),af2(3)];
                        temp2 = [af2(1:2),af1(3)];
                        if randi([0,1]) == 1 % Decidir pra qual asa vai cada um dos aerof�lios novos
                            chi(c).af_t = temp1;
                            chi(c+1).af_t = temp2;
                        else
                            chi(c).af_t = temp2;
                            chi(c+1).af_t = temp1;
                        end
                        
                    case 3 % Trocar o local da curvatura m�xima
                        temp1 = [af1(1),af2(2),af1(3)];
                        temp2 = [af2(1),af1(2),af2(3)];
                        
                        if randi([0,1]) == 1 % Decidir pra qual asa vai cada um dos aerof�lios novos
                            chi(c).af_t = temp1;
                            chi(c+1).af_t = temp2;
                        else
                            chi(c).af_t = temp2;
                            chi(c+1).af_t = temp1;
                        end
                        
                    case 4 % Trocar a curvatura m�xima
                        temp1 = [af1(1),af2(2:3)];
                        temp2 = [af2(1),af1(2:3)];
                        if randi([0,1]) == 1 % Decidir pra qual asa vai cada um dos aerof�lios novos
                            chi(c).af_t = temp1;
                            chi(c+1).af_t = temp2;
                        else
                            chi(c).af_t = temp2;
                            chi(c+1).af_t = temp1;
                        end
                end
            end
            
            % Tor��o geom�trica na ponta
            if cross_op_v(9) == 1 
                chi(c).tw_t = pop(par(2)).tw_t;
                chi(c+1).tw_t = pop(par(1)).tw_t;
            end
            
            % Enflechamento total (asas trapezoidais simples)
            if cross_op_v(10) == 1 && pop(par(1)).type == 0 && pop(par(2)).type == 0
                chi(c).sweep = pop(par(2)).sweep;
                chi(c+1).sweep = pop(par(1)).sweep;
            end 
        
            % Enflechamento da primeira se��o (asas bitrapezoidais)
            if cross_op_v(11) == 1 && pop(par(1)).type == 1 && pop(par(2)).type == 1
                chi(c).sweep1 = pop(par(2)).sweep1;
                chi(c+1).sweep1 = pop(par(1)).sweep1;
            end
            
            % Enflechamento da segunda se��o (asas bitrapezoidais)
            if cross_op_v(12) == 1 && pop(par(1)).type == 1 && pop(par(2)).type == 1
                chi(c).sweep2 = pop(par(2)).sweep2;
                chi(c+1).sweep2 = pop(par(1)).sweep2;
            end
            
        else % Transformar uma asa trapezoidal simples em trapezoidal dupla e vice-versa
             % (adiciona-se/retira-se o aerof�lio do meio)
            if pop(par(1)).type == 0 % Se a primeira do par for trapezoidal simples
                chi(c) = pop(par(1));
                chi(c).type = 1;
                chi(c).b1 = pop(par(2)).b1;
                chi(c).c_m = pop(par(2)).c_m;
                chi(c).af_m = pop(par(2)).af_m;
                chi(c).tw_m = pop(par(2)).tw_m;
                chi(c).sweep1 = pop(par(2)).sweep1;
                chi(c).sweep2 = pop(par(2)).sweep2;
                
                chi(c+1) = pop(par(2));
                chi(c+1).type = 0;
                chi(c+1).b1 = [];
                chi(c+1).c_m = [];
                chi(c+1).af_m = zeros(1,3);
                chi(c+1).tw_m = [];,
                chi(c+1).sweep = pop(par(1)).sweep;
                
            else % Se a primeira do par for trapezoidal dupla
                chi(c) = pop(par(2));
                chi(c).type = 1;
                chi(c).b1 = pop(par(1)).b1;
                chi(c).c_m = pop(par(1)).c_m;
                chi(c).af_m = pop(par(1)).af_m;
                chi(c).tw_m = pop(par(1)).tw_m;
                chi(c).sweep1 = pop(par(1)).sweep1;
                chi(c).sweep2 = pop(par(1)).sweep2;
                
                chi(c+1) = pop(par(1));
                chi(c+1).type = 0;
                chi(c+1).b1 = [];
                chi(c+1).c_m = [];
                chi(c+1).af_m = zeros(1,3);
                chi(c+1).tw_m = [];
                chi(c+1).sweep = pop(par(2)).sweep;
                
            end
            
            % Checar o requisito das envergaduras
            if chi(c).b1 > chi(c).b - dat.b1_ext_in(3)*2
                % Se n�o cumprir o requisito, atribuir um novo valor
                if chi(c).b - dat.b1_ext_in(3)*2 >= dat.b1_ext_in(2)
                    dat.b1_ext = dat.b1_ext_in(1):dat.b1_step:dat.b1_ext_in(2);
                else
                    dat.b1_ext = dat.b1_ext_in(1):dat.b1_step:chi(c).b-dat.b1_ext_in(3)*2;
                end
                
                chi(c).b1 = dat.b1_ext(randi(length(dat.b1_ext)));
            end
            
            % Checar o requisito dos comprimentos de corda
            if chi(c).c_t > chi(c).c_m && ~ismember('L',dat.c_m_ext_in) || chi(c).c_m > chi(c).c_r && ~ismember('L',dat.c_m_ext_in)
                % Se n�o cumprir o requisito, atribuir um novo valor
                dat.c_m_ext = [0,0];
                if chi(c).c_t >= dat.c_m_ext_in(1)
                    dat.c_m_ext(1) = chi(c).c_t;
                else
                    dat.c_m_ext(1) = dat.c_m_ext_in(1);
                end
                if chi(c).c_r <= dat.c_m_ext_in(2)
                    dat.c_m_ext(2) = chi(c).c_r;
                else
                    dat.c_m_ext(2) = dat.c_m_ext_in(2);
                end
                dat.c_m_ext = dat.c_m_ext(1):dat.c_m_step:dat.c_m_ext(2);
                chi(c).c_m = dat.c_m_ext(randi(length(dat.c_m_ext)));
            end
            
        end
        
        % Debugging: ver como est�o sendo cumpridas os requisitos de geometria da planta
        if chi(c).type == 1
            if chi(c).b1 > chi(c).b-2*dat.b1_ext_in(3) || chi(c).c_t > chi(c).c_m && ~ismember('L',dat.c_m_ext_in) || chi(c).c_m > chi(c).c_r && ~ismember('L',dat.c_m_ext_in)
                error('Problema na geometria da planta (c)')
            end 
        end
        if chi(c+1).type == 1
            if chi(c+1).b1 > chi(c+1).b-2*dat.b1_ext_in(3) || chi(c+1).c_t > chi(c+1).c_m && ~ismember('L',dat.c_m_ext_in) || chi(c+1).c_m > chi(c+1).c_r && ~ismember('L',dat.c_m_ext_in)
                error('Problema na geometria da planta (c+1)')
            end 
        end
        
        % Zerar a pontua��o dos filhos 
        chi(c).score = 0;
        chi(c+1).score = 0;
        
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
            
            
            % A muta��o funciona de modo a atribuir novos valores aos respectivos campos
            
            % Genes a serem alterados 
            % Envergadura b
            % Envergadura b1 (asas bitrapezoidais apenas)
            % Corda da raiz
            % Corda do meio (asas bitrapezoidais apenas)
            % Corda da ponta
            % - aerof�lio da raiz
            % - aerof�lio do meio (asas bitrapezoidais apenas)
            % - aerof�lio da ponta
            % Tor��o geom�trica na ponta
            % Envergaduras
            % Enflechamento total (asas trapezoidais simples)
            % Enflechamento da primeira se��o (asas bitrapezoidais)
            % Enflechamento da segunda se��o (asas bitrapezoidais)
            
            mu_op_v = randi([0,1],1,12);
            
            % Envergadura b
            if mu_op_v(1) == 1
                chi(s).b = dat.b_ext(randi(length(dat.b_ext)));
            end
            
            % Envergadura da primeira se��o b1 (asas bitrapezoidais apenas)
            if mu_op_v(2) == 1 && chi(s).type == 1
                if dat.b1_ext_in(2) >= chi(s).b - 2*dat.b1_ext_in(3);
                    dat.b1_ext = dat.b1_ext_in(1):dat.b1_step:chi(s).b-2*dat.b1_ext_in(3);
                else
                    dat.b1_ext = dat.b1_ext_in(1):dat.b1_step:dat.b1_ext_in(2);
                end
                chi(s).b1 = dat.b1_ext(randi(length(dat.b1_ext)));
            end
            
            % Corda da raiz c_r
            if mu_op_v(3) == 1
                chi(s).c_r = dat.c_r_ext(randi(length(dat.c_r_ext)));
                
                % Se a corda da ponta for maior do que a da raiz, atribuir o 
                % valor da ponta � raiz
                if chi(s).c_t > chi(s).c_r
                    chi(s).c_r = chi(s).c_t;
                end
                
            end
            
            % Corda da ponta c_t (deve cumprir o requisito c_t <= c_r)
            if mu_op_v(4) == 1
                if chi(s).c_r < dat.c_t_ext_in(2);
                    dat.c_t_ext = dat.c_t_ext_in(1):dat.c_t_step:pop(s).c_r;
                else
                    dat.c_t_ext = dat.c_t_ext_in(1):dat.c_t_step:dat.c_t_ext_in(2);
                end
                chi(s).c_t = dat.c_t_ext(randi(length(dat.c_t_ext)));
                
                % Se a corda da ponta for maior do que a da raiz, atribuir o 
                % valor da raiz � ponta
                if chi(s).c_t > chi(s).c_r
                    chi(s).c_t = chi(s).c_r;
                end
                
            end
            
            % Corda do meio c_m (asas bitrapezoidais apenas)
            if mu_op_v(5) == 1 && ~ismember('L',dat.c_m_ext_in)
                dat.c_m_ext = [0,0];
                if dat.c_m_ext_in(1) < chi(s).c_t
                    % Caso o valor m�nimo da extens�o da corda do meio seja menor do que
                    % a corda da ponta da asa atual, usar o valor da corda da ponta da
                    % asa como o valor m�nimo da extens�o
                    dat.c_m_ext(1) = chi(s).c_t;
                else   
                    % Caso contr�rio, usar o valor original
                    dat.c_m_ext(1) = dat.c_m_ext_in(1);
                end
                if dat.c_m_ext_in(2) > chi(s).c_t
                    % Caso o valor m�ximo da extens�o da corda do meio seja maior do que
                    % a corda da raiz da asa atual, usar o valor da corda da raiz da
                    % asa como o valor m�nimo da extens�o
                    dat.c_m_ext(2) = chi(s).c_r;
                else
                    % Caso contr�rio, usar o valor original
                    dat.c_m_ext(2) = dat.c_m_ext_in(2);
                end
                chi(s).c_m = dat.c_m_ext(randi(length(dat.c_m_ext)));
            end
            
            % Corre��es referentes � planta da asa (asas bitrapezoidais apenas)
            if chi(s).type == 1
                
                % Se a envergadura da primeira se��o for maior do que permitido
                % pelo requisito de separa��o, atribuir o m�ximo valor que 
                % cumpre o requisito
                if chi(s).b1 > chi(s).b-dat.b1_ext_in(3)*2
                    chi(s).b1 = chi(s).b-dat.b1_ext_in(3)*2;
                end
                
                % Se a corda do meio for maior do que a corda da raiz, atribuir
                % o valor da raiz ao meio
                if chi(s).c_m > chi(s).c_r
                    chi(s).c_m = chi(s).c_r;
                end
                
                % Se a corda do meio for menor que a corda da ponta, atribuir
                % o valor da ponta ao meio
                if chi(s).c_m < chi(s).c_t
                    chi(s).c_m = chi(s).c_t;
                end
                
            end
            
            % Aerof�lio da raiz
            if mu_op_v(6) == 1
                
                op = randi([0,1],1,3);
                
                if op(1) == 1
                    chi(s).af_r(1) = randi(dat.m_ext_r);
                    % Terminar o resto da transforma��o para perfil sim�trico
                    if chi(s).af_r(1) == 0
                        chi(s).af_r(2) = 0;
                    end
                end
                
                if ( op(2) == 1 && chi(s).af_r(1) ~= 0 ) || ( chi(s).af_r(1) ~= 0 && chi(s).af_r(2) == 0 )
                    % Considerar tamb�m o resto da transforma��o sim�trico -> assim�trico
                    chi(s).af_r(2) = randi(dat.p_ext_r);
                end
                
                if op(3) == 1
                    chi(s).af_r(3) = randi(dat.t_ext_r);
                end
                
            end
            
            % Aerof�lio do meio (asas bitrapezoidais apenas)
            if mu_op_v(7) == 1 && chi(s).type == 1
                op = randi([0,1],1,3);
                
                if op(1) == 1
                    chi(s).af_m(1) = randi(dat.m_ext_m);
                    % Terminar o resto da transforma��o para perfil sim�trico
                    if chi(s).af_m(1) == 0
                        chi(s).af_m(2) = 0;
                    end
                end
                
                if ( op(2) == 1 && chi(s).af_m(1) ~= 0 ) || ( chi(s).af_m(1) ~= 0 && chi(s).af_m(2) == 0 )
                    % Considerar tamb�m o resto da transforma��o sim�trico -> assim�trico
                    chi(s).af_m(2) = randi(dat.p_ext_m);
                end
                
                if op(3) == 1
                    chi(s).af_m(3) = randi(dat.t_ext_m);
                end
            end
            
            % Aerof�lio da ponta
            if mu_op_v(8) == 1
                op = randi([0,1],1,3);
                
                if op(1) == 1
                    chi(s).af_t(1) = randi(dat.m_ext_t);
                    % Terminar o resto da transforma��o para perfil sim�trico
                    if chi(s).af_t(1) == 0
                        chi(s).af_t(2) = 0;
                    end
                end
                
                if ( op(2) == 1 && chi(s).af_t(1) ~= 0 ) || ( chi(s).af_t(1) ~= 0 && chi(s).af_t(2) == 0 )
                    % Considerar tamb�m o resto da transforma��o sim�trico -> assim�trico
                    chi(s).af_t(2) = randi(dat.p_ext_t);
                end
                
                if op(3) == 1
                    chi(s).af_t(3) = randi(dat.t_ext_t);
                end
            end
            
            % Tor��o geom�trica na ponta
            if mu_op_v(9) == 1
                chi(s).tw_t = dat.tw_t_ext(randi(length(dat.tw_t_ext)));
            end
           
            % Enflechamento total (asas trapezoidais simples)
            if mu_op_v(10) == 1 && chi(s).type == 0 && ~ismember('Z',dat.sweep_ext_in)
                chi(s).sweep = dat.sweep_ext(randi(length(dat.sweep_ext)));
            end
            
            % Enflechamento da primeira se��o (asas trapezoidais duplas)
            if mu_op_v(11) == 1 && chi(s).type == 1 && ~ismember('Z',dat.sweep1_ext_in)
                chi(s).sweep1 = dat.sweep1_ext(randi(length(dat.sweep1_ext)));
            end
            
            % Enflechamento da segunda se��o (asas trapezoidais duplas)
            if mu_op_v(12) == 1 && chi(s).type == 1 && ~ismember('Z',dat.sweep2_ext_in)
                chi(s).sweep2 = dat.sweep2_ext(randi(length(dat.sweep2_ext)));
            end
                
            % Debugging: ver como est�o sendo cumpridas os requisitos de geometria da planta
            if chi(s).type == 1 
                if chi(s).b1 > chi(s).b-2*dat.b1_ext_in(3) || chi(s).c_t > chi(s).c_m && ~ismember('L',dat.c_m_ext_in) || chi(s).c_m > chi(s).c_r && ~ismember('L',dat.c_m_ext_in)
                    error('Problema na geometria da planta')
                end    
            end
            
            k = k+1;
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

clc
t = toc;
min = fix(t/60); s = rem(t,60);
fprintf('Tempo: %d min e %.2f s\n\n', min, s)

% Fazer gr�ficos dos coeficientes dos melhores indiv�duos de cada gera��o
for i = 1:dat.cases
    aero_m = zeros(dat.iter,4);
    for j = 1:dat.iter
        aero_m(j,:) = archive(j).aero(i,:);
    end
    figure(i+2),clf,hold on,grid on
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
    
    % Trocar separador decimal
    xl = get(gca,'XTickLabel'); yl = get(gca,'YTickLabel');
    new_xl = strrep(xl(:),'.',','); new_yl = strrep(yl(:),'.',',');
    set(gca,'XTickLabel',new_xl), set(gca,'YTickLabel',new_yl)

end




%% Pegar o struct de arquivo e imprimir todos
for i = 1:length(archive)
    disp(['<< Itera��o ' num2str(i) ' >>'])
    disp(' - Dados da planta - ')
    if archive(i).type == 0
        disp('Tipo: trapezoidal simples (type = 0)')
    else
        disp('Tipo: trapezoidal dupla (type = 1)')
    end
    fprintf('Envergadura b = %.6f\n',archive(i).b)
    if archive(i).type == 1,fprintf('Envergadura da primeira se��o b1 = %.6f\n',archive(i).b1),end
    fprintf('Corda da raiz c_r = %.6f\n',archive(i).c_r)
    if archive(i).type == 1,fprintf('Corda do meio c_m = %.6f\n',archive(i).c_m),end
    fprintf('Corda da ponta c_t = %.6f\n',archive(i).c_t)
    if archive(i).type == 0
        fprintf('Enflechamento completo sweep = %.6f\n\n',archive(i).sweep)
    else
        fprintf('Enflechamento da primeira se��o sweep1 = %.6f�\n',archive(i).sweep1)
        fprintf('Enflechamento da segunda se��o sweep2 = %.6f�\n\n',archive(i).sweep2)
    end
    
    disp('- Dados dos aerof�lios -')
    
    fprintf('Raiz: NACA %d%d%d\n',archive(i).af_r(1),archive(i).af_r(2),archive(i).af_r(3))
    if archive(i).type == 1,fprintf('Meio: NACA %d%d%d\n',archive(i).af_m(1),archive(i).af_m(2),archive(i).af_m(3)),end
    fprintf('Ponta: NACA %d%d%d\n',archive(i).af_t(1),archive(i).af_t(2),archive(i).af_t(3))
    fprintf('Tor��o geom�trica na ponta tw_t = %.6f\n\n',archive(i).tw_t)
    
    disp('- Dados aerodin�micos -')
    for j = 1:dat.cases
        fprintf('Condi��o de voo %d (CL,CD,L/D,CM): ',j),disp(archive(i).aero(j,:))
        
        if ismember('q',dat.coeff_op(:,1)) || ismember('#',dat.coeff_op(:,1))
            fprintf('L = %f N\n',archive(i).aero(j,1)*1/2*dat.rho(j)*dat.v_ref(j)^2*archive(i).S)
        end
        
        if ismember('q',dat.coeff_op(:,2)) || ismember('#',dat.coeff_op(:,2))
            fprintf('D = %f N\n',archive(i).aero(j,2)*1/2*dat.rho(j)*dat.v_ref(j)^2*archive(i).S)
        end
        
        if ismember('q',dat.coeff_op(:,4)) 
            fprintf('M = %f Nm\n',archive(i).aero(j,4)*1/2*dat.rho(j)*dat.v_ref(j)^2*archive(i).S*archive(i).mac)
        end
        
    end

    fprintf('Pontua��o: %.6f\n\n\n',archive(i).score)
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
%
%figure(10),saveas(gcf,'aoba.png')



