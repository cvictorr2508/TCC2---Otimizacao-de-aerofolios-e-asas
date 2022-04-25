%% Algoritmo gen�tico - Perfis NACA 4 d�gitos 
% Vers�o TCC 2

% Modifica��es a serem feitas:
% - Na checagem de erros, p�r c�digo que troca o n�mero de itera��es do XFOIL pro n�mero padr�o quando 
%   valores nulos forem inseridos



%%

clear,clc
fclose('all');
tic 
[y2,Fs2] = audioread('C:\Users\Guga Weffort\Documents\MATLAB\504 Finding a Treasure Box.wav');


% Par�metros do algoritmo
dat.N = 500;                              % N�mero de indiv�duos na popula��o
dat.mu = 0.05;                           % Probabilidade de muta��o
dat.iter = 5;                           % N�mero de itera��es
dat.elite = 1;                         % Aplicar elitismo?
dat.subs = 1;                          % Substituir aerof�lios sem resultados? 

% Par�metros da geometria
dat.m_ext = [0,9];
dat.p_ext = [1,9];
dat.t_ext = [10,30];

% Par�metros das simula��es
dat.cases = 2;                          % N�mero de condi��es de voo a serem analisadas
dat.reynolds = [1e6,1e6,1e6];           % Valores dos n�meros de Reynolds para as simula��es
dat.aoa = [0,4,0];                     % �ngulos de ataque
dat.iter_sim = [10,10,10];             % N�meros de itera��es no XFOIL
dat.coeff_op = ['o','^','!','c';       % Uma linha para cada condi��o de voo
                '!','!','!','!';
                '!','!','!','!'];
dat.coeff_val = [0.2,0.021,90,0;
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
% A matriz dat.coeff_F d� os pesos de cada fun��o objetiva

% Checagem de erros
dat = error_check_naca4_TCC2(dat);

% Gerar popula��o inicial
empty.m = [];
empty.p = [];
empty.t = [];
empty.aero = []; % Ter� o mesmo formato que a matriz coeff_op
empty.score = 0;

pop = repmat(empty,dat.N,1);
chi = pop;
    
% Gerar numera��o aleat�ria
disp('<< Gera��o da popula��o inicial >>')
for i = 1:dat.N
    disp(['Indiv�duo ' num2str(i)])
    pop(i).m = randi(dat.m_ext); % Curvatura m�xima
    if pop(i).m == 0 % Perfis sim�tricos
        pop(i).p = 0;
    else % Perfis assim�tricos
        pop(i).p = randi(dat.p_ext);
    end
    pop(i).t = randi(dat.t_ext); % Espessura m�xima
end

% Gerar struct que guarda o melhor perfil de cada gera��o
archive = repmat(empty,dat.iter,1);

%% Loop principal ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

for loop = 1:dat.iter

    % Simular os perfis e obter dados
    select = ones(1,dat.N);
    disp('<< Simula��o dos aerof�lios >>')
    for i = 1:dat.N
        disp(['Indiv�duo ' num2str(i)])
        naca_num = strcat(num2str(pop(i).m),num2str(pop(i).p),num2str(pop(i).t));
        pop(i).aero = run_xfoil_naca4_TCC2(naca_num,dat);clc % Simula��o
        
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
    pop = fitness_naca4(pop,dat,select2);
    
    % Isto serve pra p�r todas as pontua��es em um vetor
    weights = [pop.score];
    
    % Guardar o melhor perfil de cada itera��o
    [~,pos] = max(weights);
    archive(loop) = pop(pos);
    
    % Mostrar o melhor perfil
    figure(1),clf
    plot_airfoil_naca4_TCC2(pop(pos),loop)
    
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
        if pop(par(1)).m == 0 || pop(par(2)).m == 0 % Caso um deles seja sim�trico
            n = 1;
        else
            n = randi(3);
        end
        
        switch n
            case 1
                chi(c).m = pop(par(1)).m;
                chi(c).p = pop(par(1)).p;
                chi(c).t = pop(par(2)).t;
                chi(c+1).m = pop(par(2)).m;
                chi(c+1).p = pop(par(2)).p;
                chi(c+1).t = pop(par(1)).t;
                
            case 2
                chi(c).m = pop(par(1)).m;
                chi(c).p = pop(par(2)).p;
                chi(c).t = pop(par(1)).t;
                chi(c+1).m = pop(par(2)).m;
                chi(c+1).p = pop(par(1)).p;
                chi(c+1).t = pop(par(2)).t;
                
            case 3
                chi(c).m = pop(par(2)).m;
                chi(c).p = pop(par(1)).p;
                chi(c).t = pop(par(1)).t;
                chi(c+1).m = pop(par(1)).m;
                chi(c+1).p = pop(par(2)).p;
                chi(c+1).t = pop(par(2)).t;
                
        end
        if (chi(c).m == 0 && chi(c).p ~= 0) || (chi(c).m ~= 0 && chi(c).p == 0) || (chi(c+1).m == 0 && chi(c+1).p ~= 0) || (chi(c+1).m ~= 0 && chi(c+1).p == 0)
            error('problema na configura��o do perfil sim�trico')
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
            
            
            % C�digo da muta��o referente apenas aos perfis NACA 4 d�gitos
            % come�a aqui
            if chi(s).m == 0 % Perfis sim�tricos
                n = randi(2);
                switch n
                    case 1 % Transformar em um perfil assim�trico
                        chi(s).m = randi([1,dat.m_ext(2)]);
                        chi(s).p = randi(dat.p_ext);
                    case 2 % Mudar apenas a espessura
                        chi(s).t = randi(dat.t_ext);
                end
            else % Perfis assim�tricos
                n = randi(4);
                switch n
                    case 1 % Mudar apenas a curvatura m�xima
                        chi(s).m = randi([1,dat.m_ext(2)]);
                    case 2 % Mudar apenas o local da curvatura m�xima
                        chi(s).p = randi(dat.p_ext);                        
                    case 3 % Mudar apenas a espessura
                        chi(s).t = randi(dat.t_ext);
                    case 4 % Transformar em um perfil sim�trico
                        chi(s).m = 0;
                        chi(s).p = 0;
                end
            end
                
                
            % C�digo da muta��o referente apenas aos perfis NACA 4 d�gitos
            % termina aqui
            
            if chi(s).m == 0 && chi(s).p ~= 0 || chi(s).m ~= 0 && chi(s).p == 0 
                error('problema na configura��o do perfil sim�trico')
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



%% Final ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% Mostrar qual foi o perfil resultante, as condi��es da simula��o e o
% n�mero de itera��es. Tamb�m tra�ar um gr�fico do perfil

clc,%sound(y2,Fs2)
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
    
    % Trocar separador decimal
    xl = get(gca,'XTickLabel'); yl = get(gca,'YTickLabel');
    new_xl = strrep(xl(:),'.',','); new_yl = strrep(yl(:),'.',',');
    set(gca,'XTickLabel',new_xl), set(gca,'YTickLabel',new_yl)

end

%% Pegar o struct de arquivo e imprimir todos
for i = 1:length(archive)
    disp(['<< Itera��o ' num2str(i) ' >>'])
    fprintf('NACA %d%d%d\n',archive(i).m,archive(i).p,archive(i).t)
	disp('- Dados aerodin�micos -')
    for j = 1:dat.cases
        fprintf('Condi��o de voo %d: ',j),disp(archive(i).aero(j,:))
    end
    fprintf('Pontua��o: %.6f\n\n\n',archive(i).score)%,disp(archive(i).score)
    
end



