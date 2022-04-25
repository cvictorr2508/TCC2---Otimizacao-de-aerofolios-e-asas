function v = make_vector_TCC2(pop,P,op,select2)
% Esta função toma informações das matrizes aero e transforma em
% um vetor
% Atualização: especificação da linha desejada da matriz aero

v = zeros(1,length(pop));
for i = [select2]
    v(i) = pop(i).aero(P,op);
end

%% Remover valores referentes aos indivíduos defeituosos
%for i = [flip(select)]
%    v(i) = [];
%end
    
end