clc,clear


% Objetivo: testar a fun��o de gera��o de malha pro apame

% Dados da planta
pop.type = 1; % 0 -> Trapezoidal simples, 1 -> Trapezoidal dupla
pop.b = 20;
pop.b1 = 10;
pop.c_r = 5;
pop.c_m = 2;
pop.c_t = 1;
pop.tw_m = 'L';
pop.tw_t = 0;

% Partes do struct que ser�o preenchidas posteriormente
pop.coo_r = [];
pop.coo_m = [];
pop.coo_t = [];
pop.NODE = [];
pop.ELEM = [];
pop.sec_N = [];
pop.aero = [];

% Aerof�lios CST
pop.v_ex_r = [0.0100, 0.1300, 0.2900, 0.2300, 16.0000, 0.0000];
pop.v_in_r = [0.0100, 0.0800, 0.0800, 0.0500, 13.0000, 0.0000];
pop.v_ex_m = [0.0100, 0.1600, 0.3000, 0.1100, 21.0000, 0.0000];
pop.v_in_m = [0.0100, 0.0200, 0.0200, 0.0200, -1.0000, 0.0000];
pop.v_ex_t = [0.0100, 0.2500, 0.1800, 0.2900, 19.0000, 0.0000];
pop.v_in_t = [0.0100, 0.0700, 0.0500, 0.0300, 1.0000, 0.0000];
dat.BPn = length(pop.v_ex_r)-2;
dat.N1 = 0.5; dat.N2 = 1;

% N�mero de pontos
dat.np = 30;
dat.p_op = 1;
dat.chord = 1;

% Dados da malha de pain�is
dat.nb = [1,1]; % N�mero de se��es intermedi�rias (raiz/ponta) [n�mero de se��es,desligado (0)] ou [se��es por metro,ligado(1)]
dat.nb1 = 'L'; % N�mero de se��es intermedi�rias (raiz/meio)
dat.nb2 = []; % N�mero de se��es intermedi�rias (meio/ponta)

% Dados da simula��o
dat.cases = 1;
dat.v_ref = 100; % [m/s]
dat.rho = 1.225; % [kg/m^3]
dat.p_atm = 101325; % [Pa]
dat.aoa = 0; % [graus]
dat.mach = 0.; 

% Obter coordenadas dos aerof�lios
%pop.af_r = [str2num(pop.naca_r(1)),str2num(pop.naca_r(2)),str2num(pop.naca_r(3:4))]; % Raiz
%if pop.type == 1
%    pop.af_m = [str2num(pop.naca_m(1)),str2num(pop.naca_m(2)),str2num(pop.naca_m(3:4))]; % Meio
%end    
%pop.af_t = [str2num(pop.naca_t(1)),str2num(pop.naca_t(2)),str2num(pop.naca_t(3:4))]; % Ponta

% Obter geometria (malha) do APAME
figure(1),clf,figure(2),clf
pop = run_apame_mesher_cst(pop,dat,2,2,1,2,'T�tulo');

% Escrever o arquivo de entrada e fazer a simula��o
pop.aero = run_apame(pop,dat);

% Imprimir valores
if pop.aero ~= 'n'
    fprintf('CL  = %.8f\nCD  = %.8f\nL/D = %.8f\nCM  = %.8f\n',pop.aero(1),pop.aero(2),pop.aero(3),pop.aero(4))
else
    disp('A simula��o n�o convergiu')
end

