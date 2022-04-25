function v = make_vector_TCC2_3D(pop,P,coef,op,select2,v_ref,rho)
% Esta fun��o transforma informa��es dos vetores aero e transforma em
% um vetor
% Atualiza��o: especifica��o da linha desejada da matriz aero

% op = 1 -> coeficientes 
% op = 2 -> for�as de sustenta��o e arrasto
% op = 3 -> momento de arfagem

v = zeros(1,length(pop));
if op == 1
    for i = [select2]
        v(i) = pop(i).aero(P,coef);
    end
    
elseif op == 2
    for i = [select2]
        v(i) = pop(i).aero(P,coef)*1/2*rho(P)*v_ref(P)^2*pop(i).S;
    end
    
else
    for i = [select2]
        v(i) = pop(i).aero(P,coef)*1/2*rho(P)*v_ref(P)^2*pop(i).S*pop(i).mac;
    end
    
end

%% Remover valores referentes aos indiv�duos defeituosos
%for i = [flip(select)]
%    v(i) = [];
%end

end