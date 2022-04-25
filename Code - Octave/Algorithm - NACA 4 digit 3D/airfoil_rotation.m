function coo_R = airfoil_rotation(coo,th)

% Centro de rota��o (sempre no ponto de quarto de corda como padr�o)
c = 1/4;

% Fazer a rota��o
th = -th; % As conven��es de sinal (matem�tica e aeron�utica) s�o inversas, portanto, realiza-se a troca aqui
R = [cosd(th),-sind(th);
     sind(th),cosd(th)];
coo(:,1) = coo(:,1) - c;  % Transladar as coordenadas pra que a rota��o ocorra em torno do ponto desejado
coo_R = (R*coo')';                  
coo_R(:,1) = coo_R(:,1) + c;     % Mover a geometria de volta � posi��o original

end