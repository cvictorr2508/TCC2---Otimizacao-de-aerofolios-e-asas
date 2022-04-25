% Objetivo: montar a malha de uma asa pro APAME
clc,clear,fclose('all');

% Caracter�sticas 
% - Asa retangular
% - Um perfil pra raiz e outro pra ponta

% Nota sobre as coordenadas de aerof�lios: este script trabalha de modo que seja
% necess�rio que os aerof�lios carregados tenham sempre o mesmo n�mero de pontos.
% Isso n�o � um problema no contexto do algoritmo de otimiza��o. No entanto, se o
% o intuito for gerar uma malha em outra aplica��o, � necess�rio garantir esse
% requisito de n�meros iguais de pontos. Para isso, pode-se interpolar as coordenadas
% em m�os, ou inser�-las no CST reverso e gerar o aerof�lio com a quantidade desejada
% de pontos


% Dados da asa
b = 10; % Envergadura
%c_r = 0; % Corda da raiz
%c_t = 0; % Corda da ponta
%af_r = 'coordenadas.dat'; % Aerof�lio da raiz (coordenadas em formato XFOIL)
%af_t = 'coordenadas_2.dat'; % Aerof�lio da ponta (coordenadas em formato XFOIL)
%af_r = 'coordenadas_20_1.dat';
%af_t = 'coordenadas_20_2.dat';

% Aerof�lios CST
v_ex_r = [0.04,.1,.3,.1,20,0]; v_in_r = [.01,.1,.1,.2,-10,0]; 
v_ex_t = [0.01,.1,.1,.1,10,0]; v_in_t = [.01,.1,.1,.2,10,0]; 
dat.chord = 1;
dat.BPn = 4;
dat.np = 50;
dat.N1 = 0.5;
dat.N2 = 1;
dat.p_op = 0;


% Nota: aerof�lios *devem* ter o bordo de fuga fechado
%if size(af_r,1) ~= size(af_t,1),error('N�mero de pontos de ambos os aerof�lios devem ser iguais'),end

% Dados da malha de pain�is
far = b*2; % Comprimento dos pain�is de trilha (a partir do bordo de fuga)
nb = 5;    % N�mero de se��es intermedi�rias entre a raiz e a ponta (considerando apenas um lado da asa)

% Configura��es da simula��o
sim_op = 0; % Fazer a simula��o no apame ao final?
v_ref = 100; % [m/s]
aoa = 0; % [graus]
rho = 1.225; % [kg/m^3]
p_atm = 101325; % [Pa]


% Carregar coordenadas dos aerof�lios. Como o contorno � fechado, ignora-se o �ltimo par de coordenadas
%coo_r = dlmread(af_r); coo_r = coo_r(1:end-1,:);
%coo_t = dlmread(af_t); coo_t = coo_t(1:end-1,:);
coo_r = run_cst_TCC2(v_ex_r,v_in_r,dat); coo_r = coo_r(1:end-1,:);
coo_t = run_cst_TCC2(v_ex_t,v_in_t,dat); coo_t = coo_t(1:end-1,:);
sec_af_N = size(coo_r,1); % N�mero de n�s por se��o
sec_N = 3 + nb*2; % N�mero de se��es transversais




% Obter n�s ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
NODE = zeros(sec_af_N*(1+nb),3);
NODE(1:sec_af_N,:) = [coo_t(:,1),repmat(-b/2,sec_af_N,1),coo_t(:,2)]; % Ponta esquerda da asa
%NODE = [coo_t(:,1),repmat(-b/2,sec_af_N,1),coo_t(:,2)]; % Ponta esquerda da asa

% Gerar se��es intermedi�rias e adicionar ao lado esquerdo da asa
if nb > 0
    % Criar struct que guarda se��es de asa intermedi�rias
    % (isto ser� um aux�lio devido � natureza sim�trica a asa)
    wing_sec.coo = []; wing_sec = repmat(wing_sec,nb,1); % Inicializar
    op_vec = linspace(1,0,2+nb); op_vec = op_vec(2:end-1); % Defini��o do formato da interpola��o em fun��o dos originais
    
    % Encontrar as coordenadas das se��es (fazer interpola��es)
    for i = 1:length(op_vec)
        wing_sec(i).coo = airfoil_interpolation(coo_r,coo_t,op_vec(i),-op_vec(i)*(b/2));
        % Adicionar ao lado esquerdo da asa
        NODE(sec_af_N*i+1:sec_af_N*(i+1),:) = wing_sec(i).coo;
    end
end

%    for i = 1:length(op_vec)
%%        wing_sec(i).coo = airfoil_interpolation(coo_r,coo_t,op_vec(i),-op_vec(i)*(b/2));
%        % Adicionar ao lado esquerdo da asa
%%        disp(NODE(sec_af_N*i+1:sec_af_N*(i+1),:))
%disp(NODE(sec_af_N*(i+1),:))
%    end

% Adicionar coordenadas do perfil da raiz
NODE = [NODE;coo_r(:,1),zeros(sec_af_N,1),coo_r(:,2)];

% Adicionar se��es intermedi�rias ao lado direito da asa
if nb > 0
%    NODE = [NODE;zeros(sec_af_N*nb,3)];
    temp = zeros(sec_af_N*nb,3);
    k = 1;
    for i = length(op_vec):-1:1
        wing_sec(k).coo(:,2) = -wing_sec(k).coo(:,2); % Inverter o sinal da coordenada y das se��es intermedi�rias
        temp(sec_af_N*i-sec_af_N+1:sec_af_N*i,:) = wing_sec(k).coo;
        k = k + 1;
    end
    NODE = [NODE;temp];
end

% Adicionar ponta direita
NODE = [NODE;coo_t(:,1),zeros(sec_af_N,1)+b/2,coo_t(:,2)];


% Teste: fazer um gr�fico das se��es da asa (raiz � ponta)
figure(2),clf,grid on,axis equal,hold on
for i = 1:(sec_N-1)
%    figure(2),clf,grid on,axis equal
    plot(NODE(sec_af_N*i-sec_af_N+1:sec_af_N*i,1),NODE(sec_af_N*i-sec_af_N+1:sec_af_N*i,3))
%    input('')
end






% Teste: fazer um gr�fico dos perfis carregados
%figure(1),clf
%plot(coo_r(:,1),coo_r(:,2)),axis equal,grid on,hold on
%plot(coo_t(:,1),coo_t(:,2))


% Gerar pain�is~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% N�mero de pain�is: (sec_af_N*(3 + nb*2 - 1)) + ((3 + nb*2 - 1))
%               (pain�is na superf�cie das asas) + (pain�is de trilha)
panel_surf = zeros(sec_af_N*(sec_N-1),9); % Inicializar pain�is da superf�cie
% Devido � natureza das geometrias, n�o haver�o elementos triangulares 
% Nota: pain�is da superf�cie que se localizam no bordo de fuga n�o tem um dos
% pain�is adjacentes. Nesse caso, insere-se o valor 0

% Montar os elementos da superf�cie
v = 1:(sec_N-1);
k = 1;
for i = v
    for j = 1:sec_af_N-1
        panel_surf(k,1:5) = [1,k,sec_af_N+k,sec_af_N+k+1,k+1];
%        j+sec_af_N*(i-1)
        k = k + 1;
    end    
    panel_surf(k,1:5) = [1,k,sec_af_N+k,sec_af_N*i+1,sec_af_N*(i-1)+1];
    k = k + 1;
end
% Adicionar numera��o de pain�is adjacentes
panel_surf(1,6:end) = [sec_af_N+1,2,0,0]; % Primeiro painel
panel_surf(end,6:end) = [sec_af_N*(sec_N-2),sec_af_N*(sec_N-1)-1,0,0]; % �ltimo painel
for i = 2:size(panel_surf,1)-1
    if i <= sec_af_N % Ponta esquerda da asa
        panel_surf(i,6:end) = [i-1,i+sec_af_N,i+1,0];
    elseif i > size(panel_surf,1)-sec_af_N+1 % Ponta direita da asa
        panel_surf(i,6:end) = [i-1,0,i+1,i-sec_af_N];
    elseif i == sec_af_N % Painel do intradorso da ponta esquerda (bordo de fuga)
        panel_surf(i,6:end) = [sec_af_N*2,0,0,sec_n-1];
    elseif i == sec_af_N*(1+2*nb)+1 % Painel do extradorso da ponta direita(bordo de fuga)
        panel_surf(i,6:end) = [0,0,sec_af_N*(1+nb*2)+2,sec_af_N*(1+nb)+1];
    else % Todos os outros pontos
        panel_surf(i,6:end) = [i-1,i+sec_af_N,i+1,i-sec_af_N];
    end
end

% Adicionar os n�s da trilha da asa
% Cada um ser� posicionado diretamente atr�s de sua respectiva se��o de asa a uma dist�ncia far
far_nodes = zeros(sec_N-1,3);
for i = 1:sec_N
    far_nodes(i,:) = [NODE(sec_af_N*i-sec_af_N+1,1)+far,NODE(sec_af_N*i-sec_af_N+1,2:3)];
end
S = size(NODE,1);
NODE = [NODE;far_nodes];

% Teste: fazer um gr�fico dos n�s
figure(1),clf
scatter3(NODE(:,1),NODE(:,2),NODE(:,3)),axis equal
xlabel('x'),ylabel('y'),zlabel('z')
% Enumerar os n�s
%for i = 1:size(NODE,1)   
%%    text(x(n),y(n),num2str(n))
%    text(NODE(i,1),NODE(i,2),NODE(i,3),num2str(i))
%end

% Montar os pain�is da trilha
%num_sec = 3 + 2*nb;
panel_far = zeros(sec_N-1,9);
%S = size(panel_surf,1);
k = 1;
for i = 1:sec_N-1
    panel_far(i,:) = [10,k,S+i,S+i+1,k+sec_af_N,k,k+sec_af_N-1,0,0];
    k = k + sec_af_N;
end
PANEL = [panel_surf;panel_far];

%for i = 1:(3 + nb*2)
%    num = sec_af_N*i-sec_af_N+1;
%    disp(NODE(num,:))
%    disp(num)
%end

%op_vec = linspace(1,0,2+nb);
%clc,for i = 1:(nb+2)
%    disp(sec_af_N*i-sec_af_N+1)
%end

% Imprimir o arquivo de entrada ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

fid = fopen('wings_rewrite.inp','w');
fprintf(fid,'APAME input file\nVERSION 3.1\n\n');
fprintf(fid,'AIRSPEED %f\n',v_ref);
fprintf(fid,'DENSITY %f\n',rho);
fprintf(fid,'PRESSURE %f\n',p_atm);
fprintf(fid,'MACH 0\n');
fprintf(fid,'CASE_NUM 1\n')
fprintf(fid,'%f\n0\n\n',aoa);
fprintf(fid,'WINGSPAN %f\n',b);
fprintf(fid,'MAC 1\n');
fprintf(fid,'SURFACE %f\n',b);
fprintf(fid,'ORIGIN *\n0 0 0\n\n');
fprintf(fid,'METHOD 0\n');
fprintf(fid,'ERROR 0.0000001\n');
fprintf(fid,'COLLDIST 0.0000001\n');
fprintf(fid,'FARFIELD 5\n');
fprintf(fid,'COLLCALC 0\n');
fprintf(fid,'VELORDER 1\n\n');
fprintf(fid,'RESULTS 1\n');
fprintf(fid,'RES_COEF 1\n');
fprintf(fid,'RES_FORC 0\n');
fprintf(fid,'RES_GEOM 0\n');
fprintf(fid,'RES_VELO 1\n');
fprintf(fid,'RES_PRES 1\n');
fprintf(fid,'RES_CENT 0\n');
fprintf(fid,'RES_DOUB 1\n');
fprintf(fid,'RES_SORC 1\n');
fprintf(fid,'RES_VELC 1\n');
fprintf(fid,'RES_MESH 0\n');
fprintf(fid,'RES_STAT 0\n');
fprintf(fid,'RES_DYNA 0\n');
fprintf(fid,'RES_MANO 1\n\n');

 
% Ler o modelo
%fid = fopen('wings_template.inp','r'); 
%string = fscanf(fid,'%c');
%fclose(fid);

%fid = fopen('wings_rewrite.inp','w');
%fprintf(fid,string);
fprintf(fid,'NODES %d\n',size(NODE,1));
fprintf(fid,'%f %f %f\n',NODE');
fprintf(fid,'\nPANELS %d\n',size(PANEL,1));
fprintf(fid,'%d %d %d %d %d %d %d %d %d\n',PANEL(1:end-sec_N+1,:)');
fprintf(fid,'%d %d %d %d %d %d %d\n',PANEL(end-sec_N+2:end,1:7)');
fclose(fid);

if sim_op == 1
    % Fazer a simula��o ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


    system('apame_win64.exe < apame_input.txt');clc

    result_ID = fopen('wings_rewrite.log','r');
    result = fscanf(result_ID,'%c');
    disp(result)
    fclose(result_ID);
    delete('fort.2');
    delete('wings_rewrite.log');
    delete('wings_rewrite.res');

end
