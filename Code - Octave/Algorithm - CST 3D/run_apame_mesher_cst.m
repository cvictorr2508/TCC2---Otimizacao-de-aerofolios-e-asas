function pop = run_apame_mesher_cst(pop,dat,op1,op2,fig1,fig2,text)
% Esta fun��o gera a malha de asas pro apame. Asas s�o trapezoidais simples ou
% duplas.

% Nota sobre as coordenadas de aerof�lios: este script trabalha de modo que seja
% necess�rio que os aerof�lios carregados tenham sempre o mesmo n�mero de pontos.
% Isso n�o � um problema no contexto do algoritmo de otimiza��o. No entanto, se o
% o intuito for gerar uma malha em outra aplica��o, � necess�rio garantir esse
% requisito de n�meros iguais de pontos. Para isso, pode-se interpolar as coordenadas
% em m�os, ou inser�-las no CST reverso e gerar o aerof�lio com a quantidade desejada
% de pontos

% Valores de entrada para asas trapezoidais simples:
% b      - envergadura
% c_r    - corda da raiz
% c_t    - corda da ponta
% tw_t   - tor��o geom�trica na ponta
% v_ex_r - vetor CST do extradorso do aerof�lio da raiz
% v_in_r - vetor CST do intradorso do aerof�lio da raiz
% v_ex_t - vetor CST do extradorso do aerof�lio da ponta
% v_in_t - vetor CST do intradorso do aerof�lio da ponta
% nb     - n�mero de se��es intermedi�rias (raiz/ponta)

% Valores de entrada para asas trapezoidais duplas:
% b      - envergadura
% b1     - envergadura da primeira parte da asa (raiz ao meio)
% c_r    - corda da raiz
% c_m    - corda do meio (permite op��o 'L')
% c_t    - corda da ponta
% tw_m   - tor��o geom�trica no meio (permite op��o 'L')
% tw_t   - tor��o geom�trica na ponta
% v_ex_r - vetor CST do extradorso do aerof�lio da raiz
% v_in_r - vetor CST do intradorso do aerof�lio da raiz
% v_ex_m - vetor CST do extradorso do aerof�lio do meio (permite op��o 'L')
% v_in_m - vetor CST do intradorso do aerof�lio do meio
% v_ex_t - vetor CST do extradorso do aerof�lio da ponta
% v_in_t - vetor CST do intradorso do aerof�lio da ponta
% nb     - n�mero de se��es intermedi�rias (raiz/ponta) 
% nb1    - n�mero de se�oes intermedi�rias (raiz/meio) (permite op��o 'L')
% nb2    - n�mero de se�oes intermedi�rias (meio/ponta)

% Para visualizar um gr�fico da asa:
% op1 = 2 -> vista da planta
% op1 = 3 -> vista isom�trica
% Para visualizar os aerof�lios principais: 
% op2 = 1 -> formatos originais
% op2 = 2 -> formatos com rota��o

if nargin == 2 % Ignorar os gr�ficos se op1 e op2 sequer forem especificados
    op1 = 0;
    op2 = 0;
end

if pop.type == 0 % Se a asa for trapezoidal simples

    % Dados da asa
    b = pop.b; % Envergadura
    c_r = pop.c_r; % Corda da raiz
    c_t = pop.c_t; % Corda da ponta (DEVE ser menor que a da raiz)
    tw_t = pop.tw_t; % Tor��o geom�trica na ponta
	sweep = pop.sweep; % Enflechamento

    % Carregar coordenadas dos aerof�lios. Como o contorno � fechado, ignora-se o �ltimo par de coordenadas
    coo_r = run_cst_TCC2_3D(pop.v_ex_r,pop.v_in_r,dat,[dat.N1_r,dat.N2_r]); coo_r = coo_r(1:end-1,:)*c_r;
    coo_t = run_cst_TCC2_3D(pop.v_ex_t,pop.v_in_t,dat,[dat.N1_t,dat.N2_t]); coo_t = coo_t(1:end-1,:)*c_t;

    % Dados da malha de pain�is
    nb = dat.nb;
    far = b*2; % Comprimento dos pain�is de trilha (a partir do bordo de fuga)
    
    % Alterar a quantidade de se��es em termos de uma concentra��o especificada
    if nb(2) == 0 % Usar o valor especificado 
        nb = nb(1);
    else % Usar como uma concentra��o por metro e determinar o n�mero de se��es
        nb = floor((b*nb(1)-2)/2);
    end
    
    % Alguns dados a mais
    sec_af_N = size(coo_r,1); % N�mero de n�s por se��o
    sec_N = 3 + nb*2; % N�mero de se��es transversais

    % Rotacionar o perfil da ponta
    coo_t_R = airfoil_rotation(coo_t,tw_t);

    % Obter n�s ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NODE = zeros(sec_af_N*(1+nb),3);
    if sweep == 'Z' % Fazer com que o enflechamento da linha c/2 seja sempre zero
        dx_t = (c_r - c_t*cosd(tw_t))/2; % Ligeiro translado pra quando as cordas forem diferentes (� preciso considerar a tor��o na ponta)
    else % Usar enflechamento especificado pelo usu�rio
        dx_t = b/2*tand(sweep);
    end
    NODE(1:sec_af_N,:) = [coo_t_R(:,1)+dx_t,repmat(-b/2,sec_af_N,1),coo_t_R(:,2)]; % Ponta esquerda da asa

    % Gerar se��es intermedi�rias e adicionar ao lado esquerdo da asa
    if nb > 0
        % Criar struct que guarda se��es de asa intermedi�rias
        % (isto ser� um aux�lio devido � natureza sim�trica a asa)
        wing_sec.coo = []; wing_sec.dx = 0;
        wing_sec = repmat(wing_sec,nb,1); % Inicializar
        op_vec = linspace(1,0,2+nb); op_vec = op_vec(2:end-1); % Defini��o do formato da interpola��o em fun��o dos originais
        
        % Encontrar as coordenadas das se��es (fazer interpola��es)
        for i = 1:length(op_vec)
            % Fazer interpola��o e aplicar tor��o geom�trica
            tw_sec = op_vec(i)*tw_t;
            wing_sec(i).coo = airfoil_interpolation(coo_r,coo_t,op_vec(i),-op_vec(i)*(b/2),tw_sec);
            % Aplicar o translado
            wing_sec(i).dx = op_vec(i)*dx_t; 
            wing_sec(i).coo(:,1) = wing_sec(i).coo(:,1) + wing_sec(i).dx;
            % Adicionar ao lado esquerdo da asa
            NODE(sec_af_N*i+1:sec_af_N*(i+1),:) = wing_sec(i).coo;
        end
            
    end

    % Adicionar coordenadas do perfil da raiz
    NODE = [NODE;coo_r(:,1),zeros(sec_af_N,1),coo_r(:,2)];

    % Adicionar se��es intermedi�rias ao lado direito da asa
    if nb > 0
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
    NODE = [NODE;coo_t_R(:,1)+dx_t,zeros(sec_af_N,1)+b/2,coo_t_R(:,2)];

    % Calcular �rea e corda aerodin�mica m�dia
    S = (c_r + c_t)*b/2;
    mac = (c_r + c_t)/2;
    
    
else % Asa trapezoidal dupla
    % Dados da asa
    b = pop.b; % Envergadura
    b1 = pop.b1; % Envergadura da primeira se��o (raiz ao meio)
    b2 = b - b1; % Envergadura da segunda se��o (meio � raiz)
    c_r = pop.c_r; % Corda da raiz
    c_m = pop.c_m; % Corda do meio
    c_t = pop.c_t; % Corda da ponta (DEVE ser menor que a da raiz)
    tw_m = pop.tw_m; % Tor��o geom�trica no meio
    tw_t = pop.tw_t; % Tor��o geom�trica na ponta
	sweep1 = pop.sweep1; % Enflechamento da primeira se��o
    sweep2 = pop.sweep2; % Enflechamento da segunda se��o
    
    % Considerar op��o 'L' da corda do meio
    if c_m == 'L'
        c_m = 2*(c_t-c_r)/b*b1/2 + c_r;
    end
    
    % Carregar coordenadas dos aerof�lios da raiz e da ponta. Como o contorno � fechado, ignora-se o �ltimo par de coordenadas
    coo_r = run_cst_TCC2_3D(pop.v_ex_r,pop.v_in_r,dat,[dat.N1_r,dat.N2_r]); coo_r = coo_r(1:end-1,:)*c_r;
    coo_t = run_cst_TCC2_3D(pop.v_ex_t,pop.v_in_t,dat,[dat.N1_t,dat.N2_t]); coo_t = coo_t(1:end-1,:)*c_t;

    % Alguns dados a mais
    nb1 = dat.nb1;
    if nb1 == 'L' % Tornar uniforme (ou pr�ximo disso) a distribui��o de se��es ao longo da envergadura completa
        nb = dat.nb;
        % Alterar a quantidade de se��es em termos de uma concentra��o especificada
        if nb(2) == 0 % Usar o valor especificado 
            nb = nb(1);
        else % Usar como uma concentra��o por metro e determinar o n�mero de se��es
            nb = floor((b*nb(1)-2)/2);
        end
        nb1 = nb*b1/b;
        if nb1 - round(nb1) < 0 % Caso o valor seja arredondado para cima
            nb1 = round(nb1);
            nb2 = nb - nb1;
        else % Caso o valor seja arredondado para baixo
            nb1 = round(nb1);
            nb2 = nb - nb1;
        end
    else % Usar os valores originais de nb1 e nb2 dados pelo usu�rio
        nb2 = dat.nb2;
        nb = nb1 + nb2;
    end
    sec_af_N = size(coo_r,1); % N�mero de n�s por se��o (cada aerof�lio)
    sec_N = 5 + nb1*2 + nb2*2; % N�mero de se��es transversais
    far = b*2;
        
    % Distribui��o de tor��es geom�tricas
    if tw_m == 'L' && ~ischar(tw_t) % Definir a tor��o do meio em termos da tor��o da ponta
        tw_m = tw_t*b1/b;
        tw_V = linspace(0,1,3+nb1+nb2)*tw_t;
        tw_V1 = flip(tw_V(2:nb1+1));
        tw_V2 = flip(tw_V(3+nb1:end-1));
    elseif tw_t == 'L' && ~ischar(tw_m) % Definir a tor��o da ponta em termos da tor��o do meio
        tw_t = tw_m*b/b1;
        tw_V = linspace(0,1,3+nb1+nb2)*tw_t;
        tw_V1 = flip(tw_V(2:nb1+1));
        tw_V2 = flip(tw_V(3+nb1:end-1));
    else % Aplicar ambos os valores de tor��o especificados
        tw_V1 = linspace(0,1,2+nb1)*tw_m;
        tw_V2 = linspace(tw_m/tw_t,1,2+nb2)*tw_t;
        tw_V1 = flip(tw_V1(2:end-1));
        tw_V2 = flip(tw_V2(2:end-1));
    end
    % (Em todos os casos acima, as tor��es intermedi�rias s�o definidas linearmente)

    % Rotacionar o perfil da ponta
    coo_t_R = airfoil_rotation(coo_t,tw_t);
    
    % Carregar as coordenadas do aerof�lio do meio
    if ismember('L',pop.v_ex_m) || ismember('L',pop.v_in_m)
        coo_m = airfoil_interpolation(coo_r,coo_t,b1/b,0,tw_t*b1/b);
    else
		coo_m = run_cst_TCC2_3D(pop.v_ex_m,pop.v_in_m,dat,[dat.N1_m,dat.N2_m]);
        coo_m = coo_m(1:end-1,:)*c_m; % Tirar o �ltimo par de coordenadas
    end

    % Obter n�s ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NODE = zeros(sec_af_N*(1+nb2),3);
    if sweep1 == 'Z' % Fazer com que o enflechamento da linha c/2 seja sempre zero
        dx_m = (c_r - c_m*cosd(tw_m))/2; % Ligeiro translado pra quando as cordas forem diferentes (� preciso considerar a tor��o na ponta)
    else % Usar enflechamento especificado pelo usu�rio
        dx_m = b1/2*tand(sweep1);
    end
    if sweep2 == 'Z' % Fazer com que o enflechamento da linha c/2 seja sempre zero
        dx_t = (c_m - c_t*cosd(tw_t))/2 + dx_m; % Ligeiro translado pra quando as cordas forem diferentes (� preciso considerar a tor��o na ponta)
        sweep2_angle = atand((c_t-c_m)/(b2/2));
    else % Usar enflechamento especificado pelo usu�rio
        dx_t = b2/2*tand(sweep2) + dx_m;
        sweep2_angle = sweep2;
    end
    NODE(1:sec_af_N,:) = [coo_t_R(:,1)+dx_t,repmat(-b/2,sec_af_N,1),coo_t_R(:,2)]; % Ponta esquerda da asa

    % Gerar se��es intermedi�rias (ponta/meio)
    if nb2 > 0
        % Criar struct que guarda se��es de asa intermedi�rias
        % (isto ser� um aux�lio devido � natureza sim�trica a asa)
        wing_sec2.coo = []; wing_sec2.dx = 0;
        wing_sec2 = repmat(wing_sec2,nb2,1); % Inicializar
        op_vec2 = linspace(1,0,2+nb2); op_vec2 = op_vec2(2:end-1); % Defini��o do formato da interpola��o em fun��o dos originais

        % Encontrar as coordenadas das se��es (fazer interpola��es)
        for i = 1:length(op_vec2)
            % Fazer interpola��o e aplicar tor��o geom�trica
            tw_sec = tw_V2(i);
            wing_sec2(i).coo = airfoil_interpolation(coo_m,coo_t,op_vec2(i),-op_vec2(i)*((b-b1)/2)-b1/2,tw_sec);
            % Aplicar o translado
            if sweep2 == 'Z'
                wing_sec2(i).dx = op_vec2(i)*(dx_t-dx_m)+dx_m; 
            else
                wing_sec2(i).dx = op_vec2(i)*b2/2*tand(sweep2_angle)+dx_m;
            end
            wing_sec2(i).coo(:,1) = wing_sec2(i).coo(:,1) + wing_sec2(i).dx;
            % Adicionar ao lado esquerdo da asa
            NODE(sec_af_N*i+1:sec_af_N*(i+1),:) = wing_sec2(i).coo;
        end
            
    end

    % Rotacionar perfil do meio
    coo_m_R = airfoil_rotation(coo_m,tw_m);

    % Adicionar coordenadas do perfil do meio
    NODE = [NODE;coo_m_R(:,1)+dx_m,zeros(sec_af_N,1)-b1/2,coo_m_R(:,2)];

    % Gerar se��es intermedi�rias (meio/raiz)
    if nb1 > 0
        temp = zeros(sec_af_N*(nb1),3);
        % Criar struct que guarda se��es de asa intermedi�rias
        % (isto ser� um aux�lio devido � natureza sim�trica a asa)
        wing_sec1.coo = []; wing_sec1.dx = 0;
        wing_sec1 = repmat(wing_sec1,nb1,1); % Inicializar
        op_vec1 = linspace(1,0,2+nb1); op_vec1 = op_vec1(2:end-1); % Defini��o do formato da interpola��o em fun��o dos originais
        
        % Encontrar as coordenadas das se��es (fazer interpola��es)
        for i = 1:length(op_vec1)
            % Fazer interpola��o e aplicar tor��o geom�trica
            tw_sec = tw_V1(i);
            wing_sec1(i).coo = airfoil_interpolation(coo_r,coo_m,op_vec1(i),-op_vec1(i)*(b1/2),tw_sec);
            % Aplicar o translado
            wing_sec1(i).dx = op_vec1(i)*dx_m; 
            wing_sec1(i).coo(:,1) = wing_sec1(i).coo(:,1) + wing_sec1(i).dx;
            % Adicionar ao lado esquerdo da asa
            temp(sec_af_N*(i-1)+1:sec_af_N*i,:) = wing_sec1(i).coo;
        end
        NODE = [NODE;temp];    
    end

    % Adicionar coordenadas do perfil da raiz
    NODE = [NODE;coo_r(:,1),zeros(sec_af_N,1),coo_r(:,2)];

    % Adicionar se��es intermedi�rias ao lado direito da asa (raiz/meio)
    if nb1 > 0
        temp = zeros(sec_af_N*nb1,3);
        k = 1;
        for i = length(op_vec1):-1:1
            wing_sec1(k).coo(:,2) = -wing_sec1(k).coo(:,2); % Inverter o sinal da coordenada y das se��es intermedi�rias
            temp(sec_af_N*i-sec_af_N+1:sec_af_N*i,:) = wing_sec1(k).coo;
            k = k + 1;
        end
        NODE = [NODE;temp];
    end

    % Adicionar perfil do meio do lado direito da asa
    NODE = [NODE;coo_m_R(:,1)+dx_m,zeros(sec_af_N,1)+b1/2,coo_m_R(:,2)];

    % Adicionar se��es intermedi�rias ao lado direito da asa (meio/ponta)
    if nb2 > 0
    %    NODE = [NODE;zeros(sec_af_N*nb,3)];
        temp = zeros(sec_af_N*nb2,3);
        k = 1;
        for i = length(op_vec2):-1:1
            wing_sec2(k).coo(:,2) = -wing_sec2(k).coo(:,2); % Inverter o sinal da coordenada y das se��es intermedi�rias
            temp(sec_af_N*i-sec_af_N+1:sec_af_N*i,:) = wing_sec2(k).coo;
            k = k + 1;
        end
        NODE = [NODE;temp];
    end

    % Adicionar ponta direita
    NODE = [NODE;coo_t_R(:,1)+dx_t,zeros(sec_af_N,1)+b/2,coo_t_R(:,2)];
    
    % Calcular �rea e corda aerodin�mica m�dia
    S1 = (c_r + c_m)*b1/2; S2 = (c_m + c_t)*b2/2;
    S = S1 + S2;
    mac = (S1/b1 + S2/b2)/2; % obtido a partir das rela��es da raz�o de aspecto
    
end

% Fazer um gr�fico da asa
if op1 == 2 || op1 == 3
    figure(fig1)
    scatter3(NODE(:,1),NODE(:,2),NODE(:,3)),axis equal,grid on
    xlabel('x'),ylabel('y'),zlabel('z')
    view(op1) % Desenhar os pontos em 3D
    % view(2) faz a vista de cima
    % view(3) faz a vista isom�trica
    
    title(text)
    
    % Trocar separador decimal
    xl = get(gca,'XTickLabel'); yl = get(gca,'YTickLabel');
    new_xl = strrep(xl(:),'.',','); new_yl = strrep(yl(:),'.',',');
    set(gca,'XTickLabel',new_xl), set(gca,'YTickLabel',new_yl)
end

% Fazer um gr�fico dos perfis da asa (apenas raiz, meio e ponta)
if op2 == 1 % Tra�ar os formatos originais
    figure(fig2),hold on,grid on,axis equal
    plot(coo_r(:,1),coo_r(:,2),'k')
    if pop.type == 1
        coo_m_dx = coo_m;
        coo_m_dx(:,1) = coo_m_dx(:,1) + dx_m;
        plot(coo_m_dx(:,1),coo_m_dx(:,2),'r')
    end
    coo_t_dx = coo_t;
    coo_t_dx(:,1) = coo_t_dx(:,1) + dx_t;
    plot(coo_t_dx(:,1),coo_t_dx(:,2),'b')
    
    if pop.type == 1
        legend('Raiz','Meio','Ponta')
    else
        legend('Raiz','Ponta')
    end
    title(text)
    
    % Trocar separador decimal
    xl = get(gca,'XTickLabel'); yl = get(gca,'YTickLabel');
    new_xl = strrep(xl(:),'.',','); new_yl = strrep(yl(:),'.',',');
    set(gca,'XTickLabel',new_xl), set(gca,'YTickLabel',new_yl)
    
elseif op2 == 2 % Tra�ar considerando as rota��es
    figure(fig2),hold on,grid on,axis equal
    plot(coo_r(:,1),coo_r(:,2),'k')
    if pop.type == 1
        coo_m_dx = coo_m;
        coo_m_dx(:,1) = coo_m_dx(:,1) + dx_m;
        plot(coo_m_dx(:,1),coo_m_dx(:,2),'r')
    end
    coo_t_dx = coo_t;
    coo_t_dx(:,1) = coo_t_dx(:,1) + dx_t;
    plot(coo_t_dx(:,1),coo_t_dx(:,2),'b')
    
    if pop.type == 1
        legend('Raiz','Meio','Ponta')
    else
        legend('Raiz','Ponta')
    end
    title(text)
    
    % Trocar separador decimal
    xl = get(gca,'XTickLabel'); yl = get(gca,'YTickLabel');
    new_xl = strrep(xl(:),'.',','); new_yl = strrep(yl(:),'.',',');
    set(gca,'XTickLabel',new_xl), set(gca,'YTickLabel',new_yl)
end

% Gerar pain�is~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% N�mero de pain�is: 
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
        k = k + 1;
    end    
    panel_surf(k,1:5) = [1,k,sec_af_N+k,sec_af_N*i+1,sec_af_N*(i-1)+1];
    k = k + 1;
end
% Adicionar numera��o de pain�is adjacentes
panel_surf(1,6:end) = [sec_af_N+1,2,0,0]; % Primeiro painel
panel_surf(end,6:end) = [sec_af_N*(sec_N-2),sec_af_N*(sec_N-1)-1,0,0]; % �ltimo painel
for i = 2:size(panel_surf,1)-1
    if i < sec_af_N % Ponta esquerda da asa
        panel_surf(i,6:end) = [i-1,i+sec_af_N,i+1,0];
    elseif i > size(panel_surf,1)-sec_af_N+1 % Ponta direita da asa
        panel_surf(i,6:end) = [i-1,0,i+1,i-sec_af_N];
    elseif i == sec_af_N % Painel do intradorso da ponta esquerda (bordo de fuga)
        panel_surf(i,6:end) = [sec_af_N*2,0,0,sec_af_N-1];
    elseif i == sec_af_N*(1+2*nb)+1 % Painel do extradorso da ponta direita(bordo de fuga)
        panel_surf(i,6:end) = [0,0,sec_af_N*(1+nb*2)+2,sec_af_N*(1+nb)+1];
    else % Todos os outros pontos
        panel_surf(i,6:end) = [i-1,i+sec_af_N,i+1,i-sec_af_N];
    end
end

% Adicionar os n�s da trilha da asa
% Cada um ser� posicionado diretamente atr�s de sua respectiva se��o de asa a uma dist�ncia far
far_nodes = zeros(sec_N,3);
for i = 1:sec_N
    far_nodes(i,:) = [NODE(sec_af_N*i-sec_af_N+1,1)+far,NODE(sec_af_N*i-sec_af_N+1,2:3)];
end
A = size(NODE,1);
NODE = [NODE;far_nodes];

% Montar os pain�is da trilha
panel_far = zeros(sec_N-1,9);
k = 1;
for i = 1:sec_N-1
    panel_far(i,:) = [10,k,A+i,A+i+1,k+sec_af_N,k,k+sec_af_N-1,0,0];
    k = k + sec_af_N;
end
PANEL = [panel_surf;panel_far];

% Inserir as novas informa��es ao struct original
pop.NODE = NODE;
pop.PANEL = PANEL;
pop.sec_N = sec_N;
pop.S = S;
pop.mac = mac;

end