% Objetivo: ler as coordenadas de um aerof�lio e rotacion�-lo (tor��o geom�trica)
clc,clear

nome = 'coordenadas.dat'; % O formato das coordenadas deve ser o do XFOIL
th = -5; % �ngulo de rota��o [graus]
c = 1/4; % Centro de rota��o (ao longo da linha da corda)

coo = dlmread(nome);

% Tra�ar o perfil original
figure(1),clf
plot(coo(:,1),coo(:,2),'k'),hold on,grid on,axis equal
c_L = [0,0;1,0];
plot(c_L(:,1),c_L(:,2),'k--') % Linha de corda

% Fazer a rota��o
th = -th; % As conven��es de sinal (matem�tica e aeron�utica) s�o inversas, portanto, realiza-se a troca aqui
R = [cosd(th),-sind(th);
     sind(th),cosd(th)];
coo(:,1) = coo(:,1) - c; c_L(:,1) = c_L(:,1) - c; % Transladar as coordenadas pra que a rota��o ocorra em torno do ponto desejado
coo_R = (R*coo')';                  c_L_R = (R*c_L')';
coo_R(:,1) = coo_R(:,1) + c;        c_L_R(:,1) = c_L_R(:,1) + c; % Mover a geometria de volta � posi��o original

% Tra�ar o perfil rotacionado
plot(coo_R(:,1),coo_R(:,2),'b')
plot(c_L_R(:,1),c_L_R(:,2),'b--') 
scatter(c,0,'filled')

    