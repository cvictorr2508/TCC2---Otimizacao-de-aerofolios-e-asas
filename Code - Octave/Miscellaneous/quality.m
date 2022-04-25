function check = quality(coo,dat)
% Checagem de qualidade dos perfis CST

np = dat.np;
c = dat.chord;

% Separar as superf�cies
ex = flip(coo(1:np,2)); in = coo(np:(np*2)-1,2);
% Definir a espessura
thickness = ex - in;

check = 1;
while 1
    
    % 1 - Checar se h� interse��o
    if sum(thickness(2:end-1)<=0) > 0
        check = 0;disp('erro1'),break
    end
    
    % 2 - Checar as inclina��es do extradorso
    % A inclina��o do extradorso n�o pode mudar duas ou mais vezes
    slope = zeros(1,length(ex));
    for i = 1:(length(ex)-1)
        slope(i) = ex(i+1) - ex(i);
    end
    v = slope > 0;
    
    % Isto detecta quantas mudan�as de inclina��o existem
    counter = 0; num = 0;
    for i = 1:length(v)
        if v(i) == num
            counter = counter + 1;
            if mod(counter,2) == 0
                num = 0;
            else
                num = 1;
            end
        end
    end
    
    if counter >= 2
        check = 0; disp('erro2'),break
    end
    
    % 3 - Checar as inclina��es do intradorso
    % A inclina��o do intradorso n�o pode mudar tr�s ou mais vezes
    slope = zeros(1,length(in));
    for i = 1:(length(in)-1)
        slope(i) = in(i+1) - in(i);
    end
    v = slope < 0;
    
    counter = 0; num = 0;
    for i = 1:length(v)-1
        if v(i) == num
            counter = counter + 1;
            if mod(counter,2) == 0
                num = 0;
            else
                num = 1;
            end
        end
    end
    
    if counter >= 3
        check = 0; disp('erro3'),break
    end
    
    % 4 - Garantir que o perfil n�o seja fino demais
    if mean(thickness)/c < 0.04
        check = 0; disp('erro4'),break
    end
    
	%% 5 - Garantir que o bordo de fuga n�o seja pontiagudo demais
    %if mean(ex(end-5:end-1) - in(end-5:end-1))/c < 7e-3
    %    check = 0; break
    %end
	
    break
end