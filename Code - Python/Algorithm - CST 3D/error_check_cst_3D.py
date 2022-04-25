from warnings import warn
from time import sleep
import numpy as np

def error_check_cst_3D(dat):

    # Forçar a variável chord para ter valor unitário. Isso é importante para evitar
    #conflito com as especificações de tamanhos de corda da planta da asa
    dat.chord = 1
    
    if dat.N%2 != 0:
        warn('Tamanho da população deve ser par. O valor inserido será alterado.'),sleep(5)
        dat.N += 1
        
    if dat.mu < 0 or dat.mu > 1:
        raise TypeError('Chance de mutação deve estar no intervalo 0 <= dat.mu <= 1')
    
    if dat.iter < 1 or dat.iter != np.floor(dat.iter):
        raise TypeError('Número de iterações do algoritmo deve ser positivo, não nulo e inteiro')

    if dat.planf_op < 0 or dat.planf_op > 1:
        raise TypeError('A proporção de tipos de planta deve estar no intervalo 0 <= dat.planf_op <= 1')

    if dat.planf_op != 0 and 'L'== dat.c_m_ext_in and 'L' == dat.m_ext_m:
    	raise TypeError("Configurações da geometria transformarão todas as asas bitrapezoidais em trapezoidais simples (rever opções 'L')")
    
    if dat.b1_ext_in[0] >= dat.b_ext_in[1] and dat.planf_op != 0:
    	raise TypeError('O valor mínimo da extensão de b1 deve sempre ser menor que o valor máximo da extensão de b')
    
    if dat.b1_ext_in[2] <= 0 and dat.planf_op != 0:
    	raise TypeError('A separação mínima entre b1 e b deve ser um valor positivo não nulo')

    if dat.c_m_ext_in[1] > dat.c_r_ext_in[1] and dat.planf_op != 0:
    	raise TypeError('O valor máximo da extensão de c_m deve ser menor ou igual ao valor da extensão máxima da extensão de c_r')

    if dat.c_m_ext_in[0] < dat.c_t_ext_in[0] and dat.planf_op != 0:
    	raise TypeError('O valor mínimo da extensão de c_m deve ser maior ou igual ao valor mínimo da extensão de c_t')

    # Erros relacionados aos aerofólios?
    if dat.symm_op_r < 0 or dat.symm_op_r > 1 or dat.symm_op_m < 0 or dat.symm_op_m > 1 or dat.symm_op_t < 0 or dat.symm_op_t > 1:
    	raise TypeError('Opção de perfis simétricos deve estar definida no intervalo 0 <= dat.symm_op <= 1')
    
    # Parâmetros das simulações: número de condições de voo
    if dat.cases < 1 or dat.cases != np.floor(dat.cases):
    	raise TypeError('Número de condições de voo deve ser positivo, não nulo e inteiro')
    
    # Parâmetros das simulações: velocidades de referência
    if len(dat.v_ref) < dat.cases:
    	raise TypeError('Não há velocidades de referência suficientes para todas as condições de voo')
    
    # Parâmetros das simulações: densidades do ar
    if len(dat.rho) < dat.cases:
    	raise TypeError('Não há densidades do ar suficientes para todas as condições de voo')
    
    # Parâmetros das simulações: pressões atmosféricas
    if len(dat.p_atm) < dat.cases:
    	raise TypeError('Não há pressões atmosféricas suficientes para todas as condições de voo')
    
    # Parâmetros das simulações: números de Mach
    if len(dat.mach) < dat.cases:
    	raise TypeError('Não há números de Mach suficientes para todas as condições de voo')
    
    # Parâmetros das simulações: números de Reynolds
    if len(dat.reynolds) < dat.cases:
        raise TypeError('Não há números de Reynolds suficientes para todas as condições de voo')
    
    # Parâmetros das simulações: ângulos de ataque
    if len(dat.aoa) < dat.cases :
        raise TypeError('Não há ângulos de ataque suficientes para todas as condições de voo')
    
    #if len(dat.iter_sim) < dat.cases
    #    error('Não há números de iterações (XFOIL) suficientes para todas as condições de voo')
    #end
    
    # # Trocar valores nulos e negativos de números de iteração pelo valor padrão do XFOIL
    # for i = 1:dat.cases
    	# if dat.iter_sim(i) == 0
    		# dat.iter_sim(i) = 10;
    	# end
    # end
    
    # Parâmetros das simulações: configuração das funções objetivas
    if dat.coeff_op.shape[0] < dat.cases or dat.coeff_val.shape[0] < dat.cases or dat.coeff_F.shape[0] < dat.cases:
        raise TypeError('Configurações das funções objetivas são insuficientes para todas as condições de voo')

    if 'q' in dat.coeff_op[:,2]:
    	raise TypeError('Função objetiva q vale apenas para a sustentação, arrasto e momento')

    if '#' in dat.coeff_op[:,2:]:
        raise TypeError('Função objetiva # vale apenas para sustentação e arrasto')

    if 'c' in dat.coeff_op[:,0:3] or 'k' in dat.coeff_op[:,0:3]:
        raise TypeError('Funções objetivas c e k valem apenas para o coeficiente de momento')

    if dat.cases == 1 and dat.coeff_op[0,3] == 'c' or dat.cases == 1 and dat.coeff_op[0,3] == 'k':
        warn('Função objetiva c/k vale apenas para múltiplas condições de voo. A mesma será ignorada.')
        dat.coeff_op[0,3] = '!'; sleep(5)

    if sum(sum(dat.coeff_op[0:dat.cases,:] == '!')) == dat.coeff_op[0:dat.cases].size:
        raise TypeError('Ao menos uma das funções objetivas deve estar ativa')
    
    T = dat.coeff_op
    for i in range(dat.cases):
        for j in range(4):
            if T[i,j] != '!' and T[i,j] != '^' and T[i,j] != 'o' and T[i,j] !='q' and T[i,j] !='#'and T[i,j] != 'c' and T[i,j] != 'k':
                raise TypeError('A matriz dat.coeff_op deve ser definida com opções !, ^, o, q, #, c ou k')

    if dat.cases > 1:
        for i in range(1,dat.cases):
            if sum(dat.coeff_op[i,:] == '!') == 4 and dat.coeff_op[0,3] != 'c' and dat.coeff_op[0,3] != 'k':
                raise TypeError('Condição de voo ' + str(i+1) + ' não tem função objetiva definida')
    
    for P in range(dat.cases):
        if dat.coeff_op[P,1] == 'o' and dat.coeff_val[P,1] < 0:
            raise TypeError('Condição de voo ' + str(i) + ': CD alvo deve ser maior que zero')
        elif dat.coeff_op[P,1] == 'o' and dat.coeff_val[P,1] == 0:
            dat.coeff_op[1] = '^'
            warn('Condição de voo ' + str(i+1) + ': CD = 0 - Função objetiva de arrastop trocada de o para ^');sleep(5) 

    if dat.cases > 1 and dat.coeff_op[0,3] == 'c' or dat.cases > 1 and dat.coeff_op[0,3] == 'k':
        x = 0
        for i in range(1,3):
            if dat.coeff_op[i,3] != '!': x+=1
        if x!= 0:
            warn('Função objetiva de momento c/k: funções objetivas das condições de voo subsequentes serão ignoradas');sleep(5)
            # temp = np.zeros((dat.cases-1,1))
            # for i in range(len(temp)):
            #     temp[i] = '!'
            dat.coeff_op[1:dat.cases,3] = np.repeat('!',dat.cases-1)
    
    return dat
