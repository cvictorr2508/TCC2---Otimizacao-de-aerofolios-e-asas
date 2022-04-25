function aero = run_xfoil_cst_TCC2(dat,op) 

if op == 1 % Montar o arquivo de input

    % Pegar as informa��es do c�digo base:
    reynolds = dat.reynolds;
    aoa = dat.aoa;
    iter_sim = dat.iter_sim;
    numNodes = dat.numNodes;
    cases = dat.cases;

    %fclose('all');

    %if (exist('xfoil_input.txt','file'))
    %    delete('xfoil_input.txt');
    %end

    %% Cria��o do arquivo de input do Xfoil
    fid = fopen('xfoil_input.txt','w');

    % Mudar uma op��o dos gr�ficos do XFOIL (desativar a apari��o 
    % da janela com o desenho da simula��o)
    fprintf(fid,'PLOP\n');
    fprintf(fid,'G\n\n');

    % Ler coordenadas
    fprintf(fid,'LOAD coordenadas.dat\n\n'); % Nota: retirar a quebra de linha extra 
                                             % caso o perfil tenha um nome
                                             
    % Modificar o n�mero de n�s
    if numNodes ~= 0
        fprintf(fid,'PPAR\n');
        fprintf(fid,'N %s\n', num2str(numNodes));
        fprintf(fid,'\n\n');
    end
                                            
    % Simula��o
    fprintf(fid,'OPER\n');
    if cases == 1 % Apenas uma condi��o de voo
        
        fprintf(fid,'VISC %d\n', reynolds(1)); % Aplicar o modo viscoso e determinar n�mero de Reynolds 
        fprintf(fid,'PACC\n');                 % Estabelecer arquivo de output
        fprintf(fid,['polar' num2str(1) '.txt\n\n']);
        fprintf(fid,'ITER %d\n', iter_sim(1)); % Mudar o n�mero de itera��es      
        fprintf(fid,'ALFA %f\n', aoa(1));        % Estabelecer �ngulo de ataque

    else % Duas ou mais condi��es de voo
        
        for i = 1:cases
            
            if i == 1
                fprintf(fid,'VISC %d\n', reynolds(i)); % Aplicar o modo viscoso e determinar n�mero de Reynolds
            elseif i ~= 1 && reynolds(i) ~= reynolds(i-1)
                fprintf(fid,'RE %d\n',reynolds(i)); % Mudar n�mero de Reynolds (ap�s primeira simula��o)
    %        else
    %            fprintf(fid,'RE %d\n',reynolds(i)); % Mudar n�mero de Reynolds (ap�s primeira simula��o)
            end
            fprintf(fid,'PACC\n');              % Estabelecer arquivo de output
            fprintf(fid,['polar' num2str(i) '.txt\n\n']);
            if i == 1 || i~= 1 && iter_sim(i) ~= iter_sim(i-1)
                fprintf(fid,'ITER %d\n', iter_sim(i)); % Mudar o n�mero de itera��es    
            end
            fprintf(fid,'ALFA %f\n', aoa(i));        % Estabelecer �ngulo de ataque
            fprintf(fid,'PACC\n'); % Fechar a polar para come�ar a pr�xima simula��o
            
        end
    end

    % Fechar arquivo
    fprintf(fid,'\nQUIT\n');
    fclose(fid);

    
else % Simular os aerof�lios
    cases = dat.cases;
    
    % Apagar arquivos caso existam
    for i = 1:cases
        a_polar = ['polar' num2str(i) '.txt'];
        if (exist(a_polar,'file'))
            delete(a_polar);
        end
    end

    % Executar XFOIL com o arquivo de entrada
    cmd = 'xfoil.exe < xfoil_input.txt';
    system(cmd);

    %% Ler o arquivo de output
    aero = zeros(cases,4);
    for i = 1:cases

        % Contar o n�mero de linhas
        fidpolar = fopen(['polar' num2str(i) '.txt']); 
        tline = fgetl(fidpolar);
        nl = 0;
        while ischar(tline)	
            nl = nl+1; % N�mero de linhas
            tline = fgetl(fidpolar);
        end
        fclose(fidpolar);
        
        if nl == 13
            fidpolar = fopen(['polar' num2str(i) '.txt']);
            dataBuffer = textscan(fidpolar,'%f %f %f %f %f %f %f','HeaderLines',12,...
                'CollectOutput',1,...
                'Delimiter','');
            fclose(fidpolar);
            
            % Valores dos coeficientes
            CL = dataBuffer{1,1}(1,2);
            CD = dataBuffer{1,1}(1,3);
            CM = dataBuffer{1,1}(1,5);
            
            aero(i,:) = [CL,CD,CL/CD,CM];
            
        else
            aero = 'n'; break % Ignorar o aerof�lio se ao menos uma das simula��es n�o convergir
        end

        
    end


end