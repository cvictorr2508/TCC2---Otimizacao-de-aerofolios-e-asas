clc,clear


% Dados da asa
pop.type = 1;
pop.b = 20; % Envergadura
pop.b1 = 14;
pop.c_r = 5; % Corda da raiz
pop.c_m = 4; 
pop.c_t = 1; % Corda da ponta (DEVE ser menor que a da raiz)
pop.tw_m = 'L';
pop.tw_t = -0; % Tor��o geom�trica na ponta
pop.v_ex_r = [0.1,0.1,0.1,0.1,10,0];
pop.v_in_r = [0.1,0.1,0.1,0.1,10,0];
pop.v_ex_m = [0.1,0.1,0.1,0.1,10,0];
pop.v_in_m = [0.1,0.1,0.1,0.1,10,0];
pop.v_ex_t = [0.1,0.1,0.1,0.1,10,0];
pop.v_in_t = [0.1,0.1,0.1,0.1,10,0];


% (enflechamentos s�o sempre referentes ao bordo de ataque da asa)
% Op��o 'Z' aqui calcula o enflechamento automaticamente de modo que o enflechamento da linha c/2 seja sempre zero
pop.sweep = 15; % enflechamento da asa (trapezoidal simples) [graus]
pop.sweep1 = 45; % enflechamento da primeira se��o (trapezoidal dupla) [graus]
pop.sweep2 = 0; % enflechamento da segunda se��o (trapezoidal dupla) [graus]


dat.np = 30; % N�mero de pontos na gera��o de ordenadas nos aerof�lios
dat.np_op = 1; % 1 -> cosspace, 0 -> cosspace_half
dat.nb = [1,1];
dat.nb1 = 'L';
dat.nb2 = 2;
% Dados da simula��o
dat.cases = 1;
dat.v_ref = [100,100,100]; # Velocidades de refer�ncia [m/s] 
dat.rho = [1.225,1.225,1.225]; # Densidades do ar [kg/m^3] 
dat.p_atm = [101325,101325,101325]; # Press�es do ar [Pa] (irrelevante neste algoritmo)
dat.mach = [0,0.,0.2]; # N�meros de Mach
dat.reynolds = [1e6,1e6,1e6];           # Valores dos n�meros de Reynolds para as simula��es (irrelevante neste algoritmo))
dat.aoa = [0,2,4];    

% Par�metros da geometria: aerof�lio da raiz
dat.BPn_r = 4;                  % Grau do polin�mio de Bernstein (n�mero de vari�veis de design = BPn+1 mais o delta_z)
dat.N1_r = 0.5;
dat.N2_r = 1;
% Par�metros da geometria: aerof�lio do meio (asas bitrapezoidais apenas) 
dat.BPn_m = 4;                  % Grau do polin�mio de Bernstein (n�mero de vari�veis de design = BPn+1 mais o delta_z)
dat.N1_m = 0.5;
dat.N2_m = 1;
% Par�metros da geometria: aerof�lio da ponta
dat.BPn_t = 4;                  % Grau do polin�mio de Bernstein (n�mero de vari�veis de design = BPn+1 mais o delta_z)
dat.N1_t = 0.5;
dat.N2_t = 1;
dat.chord = 1;


figure(1),clf%,figure(2),clf
pop = run_apame_mesher_cst(pop,dat,2,0,1,2,'teste');
%pop = run_apame_mesher_naca4_uuuh(pop,dat,2,0,1,2,'teste');
%run_apame(pop,dat);

%fid = fopen('apame_input.inp','w');
%fprintf(fid,'# GEOMETRY\n\n');
%fprintf(fid,'NODES %d\n',size(pop.NODE,1));
%fprintf(fid,'%.10f %.10f %.10f\n',pop.NODE');
%fprintf(fid,'\nPANELS %d\n',size(pop.PANEL,1));
%fprintf(fid,'%d %d %d %d %d %d %d %d %d\n',pop.PANEL(1:end-pop.sec_N+1,:)');
%fprintf(fid,'%d %d %d %d %d %d %d\n',pop.PANEL(end-pop.sec_N+2:end,1:7)');
%fclose(fid);