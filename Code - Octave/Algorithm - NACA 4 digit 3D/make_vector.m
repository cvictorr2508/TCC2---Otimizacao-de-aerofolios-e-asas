function v = make_vector(pop,op,select2)
% Esta fun��o transforma informa��es dos vetores aero e transforma em
% um vetor

v = zeros(1,length(pop));
for i = [select2]
    v(i) = pop(i).aero(op);
end

%% Remover valores referentes aos indiv�duos defeituosos
%for i = [flip(select)]
%    v(i) = [];
%end
    
end