function dat = error_check_naca4_TCC2(dat)

if rem(dat.N,2) ~= 0
    warning('Tamanho da popula��o deve ser par. O valor inserido ser� alterado'),pause(5)
    dat.N = dat.N + 1;
end

if dat.mu < 0 || dat.mu > 1
    error('Chance de muta��o deve estar no intervalo 0 <= dat.mu <= 1')
end

if dat.iter < 1 || dat.iter ~= floor(dat.iter)
    error('N�mero de itera��es do algoritmo deve ser positivo, n�o nulo e inteiro')
end
    
if dat.m_ext(1) < 0 || dat.m_ext(2) > 9
    error('Extens�o de m deve ser especificada de 0 a 9')
end

if dat.p_ext(1) < 1 || dat.p_ext(2) > 9
    error('Extens�o de p deve ser especificada de 1 a 9')
end

if dat.t_ext(1) < 1 || dat.t_ext(2) > 99
    error('Extens�o de t deve ser especificada de 1 a 99')
end

if dat.cases < 1
	error('N�mero de condi��es de voo deve ser positivo e n�o nulo')
end

if length(dat.reynolds) < dat.cases 
    error('N�o h� n�meros de Reynolds suficientes para todas as condi��es de voo')
end

if length(dat.aoa) < dat.cases 
    error('N�o h� �ngulos de ataque suficientes para todas as condi��es de voo')
end

if length(dat.iter_sim) < dat.cases
    error('N�o h� n�meros de itera��es (XFOIL) suficientes para todas as condi��es de voo')
end

% Trocar valores nulos e negativos de n�meros de itera��o pelo valor padr�o do XFOIL
for i = 1:dat.cases
	if dat.iter_sim(i) == 0
		dat.iter_sim(i) = 10;
	end
end

if size(dat.coeff_op,1) < dat.cases || size(dat.coeff_val,1) < dat.cases || size(dat.coeff_F,1) < dat.cases
    error('Configura��es das fun��es objetivo s�o insuficientes para todas as condi��es de voo')
end

if sum(sum(dat.coeff_op(:,1:3) == 'c')) ~= 0 || sum(sum(dat.coeff_op(:,1:3) == 'k')) ~= 0
    error('fun��es objetivo c e k valem apenas para o coeficiente de momento')
end

if dat.cases == 1 && dat.coeff_op(1,4) == 'c' || dat.cases == 1 && dat.coeff_op(1,4) == 'k'
    warning('fun��o objetivo c/k vale apenas para m�ltiplas condi��es de voo. A mesma ser� ignorada.')
    dat.coeff_op(1,4) = '!'; pause(5)
end

if sum(sum(dat.coeff_op(1:dat.cases,:) == '!')) == numel(dat.coeff_op(1:dat.cases,:)),
    error('Ao menos uma das fun��es objetivo deve estar ativa')
end

for i = 1:dat.cases
	for j = 1:4
		if dat.coeff_op(i,j) ~= '!' && dat.coeff_op(i,j) ~= '^' && dat.coeff_op(i,j) ~= 'o' && dat.coeff_op(i,j) ~= 'c' && dat.coeff_op(i,j) ~= 'k'
			error('A matriz dat.coeff_op deve ser definida com op��es !, ^, o, c ou k')
		end
	end
end

if dat.cases > 1
	for i = 2:dat.cases
        if sum(dat.coeff_op(i,:) == '!') == 4 && dat.coeff_op(1,4) ~= 'c' && dat.coeff_op(1,4) ~= 'k'
			error(['Condi��o de voo ' num2str(i) ' n�o tem fun��o objetivo definida'])
		end
	end
end

for P = 1:dat.cases
    if dat.coeff_op(P,2) == 'o' && dat.coeff_val(P,2) < 0
        error(['Condi��o de voo ' num2str(P) ': CD alvo deve ser maior que zero'])
    elseif dat.coeff_op(P,2) == 'o' && dat.coeff_val(P,2) == 0
        dat.coeff_op(P,2) = '^';
        warning(['Condi��o de voo ' num2str(P) ': CD = 0 - fun��o objetivo de arrasto trocada de o para ^']),pause(5)
    end
end

if dat.cases > 1 && dat.coeff_op(1,4) == 'c' || dat.cases > 1 && dat.coeff_op(1,4) == 'k'
	if sum(dat.coeff_op(2:end,4) ~= '!') ~= 0
		warning('fun��o objetivo de momento c/k: fun��es objetivo das condi��es de voo subsequentes ser�o ignoradas'),pause(5)
		dat.coeff_op(2:dat.cases,4) = repmat('!',dat.cases-1,1);
	end	
end