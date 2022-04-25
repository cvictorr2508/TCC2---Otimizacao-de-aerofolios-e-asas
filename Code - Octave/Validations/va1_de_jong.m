%% Valida��o 1 - Fun��o de De Jong

% 20%, 10% e 5%

clc,clear,clf

% Par�metros do algoritmo
dat.n = 400;                            % N�mero de indiv�duos na popula��o (deve ser par por hora)
dat.iter = 100;                         % N�mero de itera��es
dat.t = 20;                               % Dimens�o da fun��o
dat.mu = 0.05;                           % Probabilidade de muta��o
dat.mu_number = 1/dat.mu;                % Vetor usado na fase de muta��o
dat.best = zeros(1,dat.iter);            % Vetor usado no plot final (cont�m o valor de fun��o que mais se aproxima do m�nimo)
dat.convergence_op = 1;

%% Gerar popula��o inicial

% Template
empty.gen = [];  % Gen�tipo
empty.score = 0; % Pontua��o (quanto maior, melhor)

% Popula��o inicial
pop = repmat(empty,dat.n,1);
children = pop;

% Atribuir caracteres aleat�rios aos genes de cada indiv�duo
for i = 1:dat.n
    for j = 1:dat.t
        pop(i).gen(j) = rand*5.12*randi([-1 1]);
    end
end

% condition = 0; 
convergence = 0;
%% loop principal
for loop = 1:dat.iter
    
    % Avaliar cada indiv�duo de acordo com a fun��o e atribuir pontua��o
    for i = 1:dat.n
        
        sum = 0;
        for j = 1:dat.t
            sum = pop(i).gen(j)^2. + sum;
        end
        
        if sum == 0
            condition = 1;
            break
            
        else
            pop(i).score = sum^-1;
            
        end
    end
    
    
    % Isto serve pra p�r todas as pontua��es em um vetor
    weights = zeros(1,dat.n);
    for i = 1:dat.n
        weights(i) = pop(i).score;
    end
    
    % Pegar o melhor de cada itera��o
    [~,pos] = max(weights);
    sum = 0;
    for j = 1:dat.t
        sum = pop(pos).gen(j)^2. + sum;
    end
    f_tgt = sum;
    dat.best(loop) = f_tgt;
    fprintf('Itera�ao %d - Indiv�duo %d, ',loop,pos)
    fprintf('com f = %f\n',f_tgt)
    
    
    % Checar converg�ncia
    if dat.convergence_op == 1
        check = (weights == pop(1).score);
        sum = 0;
        for i = 1:size(check,2)
            if check(i) == 1
                sum = sum + 1;
                convergence = 1;
            end
            
        end
        
        if sum>0.9*dat.n
            break
        end
        
    end
    
    % Escolher membros da popula��o pra reprodu��o
    c=1;
    for f = 1:dat.n/2
        
        % Isto seleciona dois pais por meio de uma sele��o via roleta
        % (indiv�duos com pesos maiores t�m  mais chance de serem selecionados)
        par = [0 0]; % Vetor que indica a numera��o dos pais escolhidos
        for u = 1:2
            accumulation = cumsum(weights);
            p = rand() * accumulation(end);
            chosen_index = -1;
            for index = 1 : length(accumulation)
                if (accumulation(index) > p)
                    chosen_index = index;
                    break;
                end
            end
            %choice = chosen_index;
            par(1,u) = chosen_index;
        end
        
        
        % Crossover, gerando dois filhos de cada dois pais
        corte = randi(dat.t);
        children(c).gen = [pop(par(1,1)).gen(1:corte) pop(par(1,2)).gen(1+corte:end)];
        children(c+1).gen = [pop(par(1,2)).gen(1:corte) pop(par(1,1)).gen(1+corte:end)];
        c = c + 2;
        
        
    end
    
    
    % Muta��o
    for i = i:dat.n
        
        if randi([1 dat.mu_number]) == 1
            
            start = randi(dat.t);
            range = randi([start dat.t]);
            array = zeros(1,range-start+1);
            
            k = 1;
            for j = start:range
                children(i).gen(j) = rand*5.12*randi([-1 1]);
                k = k + 1;
            end
            
        end
    end
    
    
    
    % Substituir a popula��o inicial pelos filhos
    pop = children;
    
end


plot(1:dat.iter,dat.best),grid on
xlabel('Itera��o'),ylabel('f(x)')

if convergence == 1
    disp('Solu��o convergida')
end


% sum = 0;
% for j = 1:dat.t
%     sum = pop(best2).gen(j)^2. + sum;
% end
% f_tgt = sum;
% fprintf('Valor da fun��o: %f\n',f_tgt)



