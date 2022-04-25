%% Este c�digo l� as coordenadas de algum aerof�lio e fornece os par�metros 
%% CST que geram a mesma geometria

% As coordenadas de entrada DEVEM estar configuradas como:
% Bordo de fuga -> bordo de ataque -> bordo de fuga

% Modifica��es:
% - fator de escala agora n�o � mais utilizado
% - Adi��o de uma op��o para alterar a precis�o dos valores dos vetores do CST

clc,clear

% Qual o grau do polin�mio de Bernstein?
% N�mero de vari�veis da fun��o shape (ou seja, n�o considera o delta z) � igual
% ao grau do polin�mio mais um
n = 4;

% Precis�o dos valores nos vetores (n�mero de casas decimais)
pre = 6;

% Configura��o da sele��o de pontos
op = 1;
start1 = 6; % Ponto de in�cio do linspace (deixar 2 como padr�o, aumentar caso a concentra��o
           % de pontos no bordo de ataque seja muito alta)
start2 = 4;

% Configura��o pra gera��o de pontos
p_op = 1;

% Definir fator de escala
%f = 0.1;

% Ler coordenadas
%coo = dlmread('coordenadas.txt');
coo = dlmread('naca2412.txt');
%coo = dlmread('naca5311.txt');
%coo = dlmread('naca0012.txt');
%coo = dlmread('s1223.txt');
%coo = dlmread('fx61-180.txt');
%coo = dlmread('eppler544.txt');
%coo = dlmread('nplx.txt');
%coo = dlmread('raf15.txt');
%coo = dlmread('saratov.txt');
%coo = dlmread('whitcomb.txt');
coo = converter_function_xfoil(coo);

% Mostrar perfil original e sua distribui��o de pontos
%figure(1),clf
%plot(coo(:,1),coo(:,2)),hold on,grid on,axis equal
%scatter(coo(:,1),coo(:,2)),pause(3)

% Separar as superf�cies
% Transladar as coordenadas caso a menor ordenada n�o seja igual a zero
[val,pos] = min(coo(:,1));
if val ~= 0
    coo(:,1) = coo(:,1) - val;
    coo(:,2) = coo(:,2) - coo(pos,2);
end
if coo(pos,2) ~= 0
    coo(:,2) = coo(:,2) - coo(pos,2);
end

% Tomar o ponto de separa��o das superf�cies no bordo de ataque como a ordenada 
% m�nima para facilitar o funcionamento do CST
ex = flip(coo(1:pos,:)); 
in = coo(pos:end,:);
c = coo(1,1);
np = 80;
%np2 = size(in,1);
%np = (size(coo,1)+1)/2; % Isto ainda ser� mantido por causa da fun��o run_CST

% Encontrar a dist�ncia vertical do bordo de fuga
Dz1 = (ex(end,2) - coo(pos,2));
Dz2 = -(in(end,2) + coo(pos,2));

% Pegar pontos o suficiente das coordenadas para calcular as vari�veis de 
% design pro CST (quantidade de pontos = grau do polin�mio + 1)
if op == 1
    num1 = floor(linspace(start1,length(ex)-1,n+1));
    num2 = floor(linspace(start2,length(in)-1,n+1));
%num1 = 2:(n+2);
%num2 = 2:(n+2);
%num2 = [2:8 (35-8):35];
elseif op == 2
    num1 = floor(cosspace_half(2,length(ex)-1,n+1));
    num2 = floor(cosspace_half(2,length(in)-1,n+1));
    num1(1:length(num1)/2) = num1(1:length(num1)/2) + 2;
    num2(1:length(num2)/2) = num2(1:length(num2)/2) + 2;
    for i = 2:length(num1)-1
        if num1(i) == num1(i-1)
            num1(i) = num1(i) + 1;
        end
    end
    for i = 2:length(num2)-1
        if num2(i) == num2(i-1)
            num2(i) = num2(i) + 1;
        end
    end
else
    num1 = 2:(n+2);
    num2 = 2:(n+2);
end

P1 = zeros(n+1,2); P2 = P1;
for i = 1:n+1
    P1(i,:) = ex(num1(i),:);
    P2(i,:) = in(num2(i),:);
end

% Montar o sistema de equa��es (extradorso)
%A1 = zeros(1,n+1);
M = zeros(n+1);
R = zeros(n+1,1);

for i = 1:n+1
    px = P1(i,1);
    py = P1(i,2);
    for j = 1:n+1
        K = factorial(n)/(factorial(j-1)*factorial(n-(j-1)));
        M(i,j) = sqrt(px)*(1-px)*K*(px)^(j-1)*(1-px)^(n-(j-1));
    end
    R(i,1) = py - px*Dz1/c;
end

A1 = linsolve(M,R)';

% Montar o sistema de equa��es (intradorso)
%A2 = zeros(1,n+1);
M = zeros(n+1);
R = zeros(n+1,1);

for i = 1:n+1
    px = P2(i,1);
    py = -P2(i,2);
    for j = 1:n+1
        K = factorial(n)/(factorial(j-1)*factorial(n-(j-1)));
        M(i,j) = sqrt(px)*(1-px)*K*(px)^(j-1)*(1-px)^(n-(j-1));
    end
    R(i,1) = py - px*Dz2/c;
end

A2 = linsolve(M,R)';


% Imprimir as informa��es
v_ex = [A1(1)^2*c/2,A1(2:n),atand(A1(n+1)-Dz1/c),Dz1];
v_in = [A2(1)^2*c/2,A2(2:n),atand(A2(n+1)-Dz2/c),Dz2];
%disp(v_ex),disp(v_in)

fprintf(['v_ex = [%.' num2str(pre) 'f, '], v_ex(1))
for j = 2:(length(v_ex)-2)
    fprintf(['%.' num2str(pre) 'f, '],v_ex(j))
end
%fprintf(['%.' num2str(pre) 'f, '], v_ex(end-2))
fprintf(['%.' num2str(pre) 'f, '], v_ex(end-1))
fprintf(['%.' num2str(pre) 'f];\n'], v_ex(end))

fprintf(['v_in = [%.' num2str(pre) 'f, '], v_in(1))
for j = 2:(length(v_in)-2)
    fprintf(['%.' num2str(pre) 'f, '],v_in(j))
end
%fprintf(['%.' num2str(pre) 'f, '], v_in(end-2))
fprintf(['%.' num2str(pre) 'f, '], v_in(end-1))
fprintf(['%.' num2str(pre) 'f];\n'], v_in(end))



    
% Comparar aerof�lios
% Perfil CST calculado
dat.chord = c;
dat.BPn = n;
dat.np = np;
%dat.np1 = np1;
%dat.np2 = np2;
dat.N1 = 0.5;
dat.N2 = 1;
dat.p_op = p_op;
coo2 = run_cst_tcc2(dat,v_ex,v_in);
figure(1),clf
scatter(coo2(:,1),coo2(:,2)),grid on,hold on,axis equal
%set(gca,'ylim',[-0.1,0.2]),set(gca,'xlim',[0,1])
plot(coo(:,1),coo(:,2)) % Perfil original
legend('Calculado','Original')
%title([]);

set(gca,'xlim',[0,1])
set(gca,'ylim',[-0.2,0.2])

%plot(coo2(:,1),coo2(:,2),'--')

%subplot (2, 1, 1)
%fplot (@sin, [-10, 10]);
%subplot (2, 1, 2)
%fplot (@cos, [-10, 10]);
%
%clf;
% r = 3;
% c = 3;
% fmt = {"horizontalalignment", "center", "verticalalignment", "middle"};
% for n = 1 : r*c
%   subplot (r, c, n);
%    xlabel (sprintf ("xlabel #%d", n));
%    ylabel (sprintf ("ylabel #%d", n));
%    title (sprintf ("title #%d", n));
%    text (0.5, 0.5, sprintf ("subplot(%d,%d,%d)", r, c, n), fmt{:});
%    axis ([0 1 0 1]);
% endfor
% subplot (r, c, 1:3);
%  xlabel (sprintf ("xlabel #%d:%d", 1, 3));
%  ylabel (sprintf ("ylabel #%d:%d", 1, 3));
%  title (sprintf ("title #%d:%d", 1, 3));
%  text (0.5, 0.5, sprintf ("subplot(%d,%d,%d:%d)", r, c, 1, 3), fmt{:});
% axis ([0 1 0 1]);

% Trocar separador decimal
xl = get(gca,'XTickLabel'); yl = get(gca,'YTickLabel');
new_xl = strrep(xl(:),'.',','); new_yl = strrep(yl(:),'.',',');
set(gca,'XTickLabel',new_xl), set(gca,'YTickLabel',new_yl)

saveas(gcf,'aaaa.png')