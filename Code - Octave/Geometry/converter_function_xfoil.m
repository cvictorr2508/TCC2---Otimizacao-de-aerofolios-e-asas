function [coordenadas,zero_p] = converter_function_xfoil(coordenadas)
%%

% Fun��o baseada no conversor de coordenadas de aerof�lio (caso do xfoil
% apenas)


%%
% Nota: esta fun��o requer que no arquivo de coordenadas n�o haja nada
% escrito al�m das coordenadas


delta = zeros(1,size(coordenadas,1)-1);
for i = 1:(size(coordenadas,1)-1)
    delta(i) = coordenadas(i+1,1) - coordenadas(i,1);
end

delta_b = delta >= 0;
sum_p = sum(delta_b==1);
sum_n = sum(delta_b==0);


if sum_p < size(coordenadas,1)*0.1
    % Coordenadas em duas partes, ambas come�ando no bordo de fuga e
    % terminando no bordo de ataque
    edit = 1;
    for i = 1:size(delta,2)
        if delta_b(i) == 0
            zero_p = i;
            break
        end
    end
elseif sum_n < size(coordenadas,1)*0.1
    % Coordenadas em duas partes, ambas come�ando no bordo de ataque e
    % terminando no bordo de fuga
    edit = 2;
    for i = 1:size(delta,2)
        if delta_b(i) == 0
            zero_p = i;
            break
        end
    end
else
    % Coordenadas em uma �nica parte (geralmente come�ando e terminando no
    % bordo de fuga
    edit = 3;
    
    if delta_b(1) == 0
        for i = 1:size(delta_b,2)
            if delta_b(i) == 1
                zero_p = i;
                break
            end
        end
        
    else
        for i = 1:size(delta_b,2)
            if delta_b(i) == 0
                zero_p = i;
                break
            end
        end
    end
    
end

%% Convers�o das coordenadas

switch edit
    case 1
        
    case 2
        % Inverter a ordem da primeira parte
        coordenadas = [flip(coordenadas(2:zero_p,:)); coordenadas(zero_p+1:end,:)];
        
    case 3
        if coordenadas(1,1) == 1
            % N�o � necess�rio editar as coordenadas
            
        end
        
end

end