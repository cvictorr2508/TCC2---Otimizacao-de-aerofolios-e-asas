% Reescrita do script test_interpolation_v02 
% Adapta��o para ser utilizada no script de malha do APAME:
% - Todos os aerof�lios t�m coordenadas na mesma configura��o/tamanho, portanto, 
%   n�o � necess�rio utilizar as splines

% Nota: o tamanho das coordenadas � igual em dois sentidos:
% - N�mero total de n�s
% - N�mero de n�s para cada superf�cie (extradorso e intradorso). Isso faz com 
%   que o bordo de ataque sempre fique na mesma posi��o

%function coo = airfoil_interpolation(coo_r,coo_t,deg)
clc,clear
c_r = 1; % Comprimentos de corda
c_t = 1;
op = 0.1; % 0 -> raiz, 1 -> ponta

% Coordenadas de aerof�lio
%coo_r = 'coordenadas.dat';
%coo_t = 'coordenadas_2.dat';
%coo_r = dlmread(coo_r)*c_r;
%coo_t = dlmread(coo_t)*c_t;

% Perfis NACA 4 d�gitos
x = cosspace_half(0,1,80);
[xU,yU,xL,yL] = fourdigit(x,2,4,16); coo_r = [flip(xU'),flip(yU');xL(2:end)',yL(2:end)']*c_r;
[xU,yU,xL,yL] = fourdigit(x,2,4,12); coo_t = [flip(xU'),flip(yU');xL(2:end)',yL(2:end)']*c_t;


% Fun��o de interpola��o do formato de aerof�lios.
% Nota: o n�mero de pontos da raiz e da ponta devem ser iguais

% Encontrar o bordo de ataque de ambos os aerof�lios
delta_r = zeros(1,size(coo_r,1)-1);
for i = 1:(size(coo_r,1)-1)
    delta_r(i) = coo_r(i+1,1) - coo_r(i,1);
end
delta_b_r = delta_r >= 0;
LE = find(delta_b_r == 1,1);

% Como o tamanho de coordenadas � igual, o ponto do bordo de ataque de ambosos aerof�lios � igual
%delta_t = zeros(1,size(coo_t,1)-1);
%for i = 1:(size(coo_t,1)-1)
%    delta_t(i) = coo_t(i+1,1) - coo_t(i,1);
%end
%delta_b_t = delta_t >= 0;
%LE_t = find(delta_b_t == 1,1);

% Separar superf�cies (ordenadas)
ex_r = coo_r(1:LE,:);
in_r = coo_r(LE:end,:);
ex_t = coo_t(1:LE,:);
in_t = coo_t(LE:end,:);

% Fazer interpola��es
% 0 -> raiz
% 1 -> ponta
ex_intp = (ex_r*(1-op) + ex_t*op);
in_intp = (in_r*(1-op) + in_t*op);

coo_intp = [ex_intp;in_intp(2:end,:)];

figure(1),clf
plot(coo_r(:,1),coo_r(:,2)),hold on,axis equal,grid on
plot(coo_t(:,1),coo_t(:,2))
plot(coo_intp(:,1),coo_intp(:,2),'-*')
legend('Raiz','Ponta','Interpolado')


%end


