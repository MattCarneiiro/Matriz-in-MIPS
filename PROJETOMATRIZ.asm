#autor: Matheus Moreira Carneiro
#RA23003891

.data
# --- Definição das Mensagens de Experiência do Usuário  ---
MSG_WELCOME: .asciiz "### Calculadora de Matriz Inversa (N Dinamico) ###\n"
MSG_N:       .asciiz "-> Digite o tamanho da matriz N (N >= 2): "
MSG_ELEM:    .asciiz "Elemento A["
MSG_ELEM_2:  .asciiz "]["
MSG_ELEM_3:  .asciiz "]: "
MSG_ORIG:    .asciiz "\n--- Matriz Original A ---\n"
MSG_INV:     .asciiz "\n--- Matriz Inversa A^-1 ---\n"
MSG_SING:    .asciiz "\n*** A matriz e singular (nao possui inversa) ***\n"
MSG_SEP:     .asciiz "\t"       # Separador de coluna (TAB)
MSG_NL:      .asciiz "\n"       # Nova linha (Newline)
MSG_ERRO_N:  .asciiz "ERRO: N invalido. N deve ser >= 2 e <= 10.\n"

# --- Constantes ---
MAX_N:       .word 10           # Limite máximo para N 

.text
.globl main 



# MAIN - Ponto de entrada do programa

main:
    # Convenção de Registradores (Salvos/Restaurados no início/fim):
    # $s0: N (tamanho da matriz)
    # $s1: Endereço Base da MAT_AUM (Matriz Aumentada [A|I] na heap)
    # $s2: N * 8 (Largura total da Linha em bytes = 2N * 4 bytes/float)
    
    # 1. Setup inicial e salvamento de registradores
    addi $sp, $sp, -12
    sw $s0, 0($sp)      # Salva $s0
    sw $s1, 4($sp)      # Salva $s1
    sw $s2, 8($sp)      # Salva $s2
    
    # Imprime Boas-Vindas
    la $a0, MSG_WELCOME
    li $v0, 4
    syscall

    # 2. Lê e valida o tamanho N
    la $a0, MSG_N
    li $v0, 4
    syscall
    li $v0, 5           # syscall read_int
    syscall
    move $s0, $v0       # $s0 = N
    
    # Verifica se N >= 2
    li $t0, 2
    blt $s0, $t0, erro_n_invalido 
    # Verifica se N <= MAX_N
    lw $t1, MAX_N
    bgt $s0, $t1, erro_n_invalido 

    # 3. Aloca Memória Dinâmica (sbrk) para N x 2N floats
    # Cálculo do tamanho em bytes: N * 2N * 4
    sll $t0, $s0, 1     # $t0 = 2N (número de colunas)
    mul $t1, $s0, $t0   # $t1 = N * 2N (total de elementos float)
    sll $a0, $t1, 2     # $a0 = Total de bytes a alocar (multiplica por 4 bytes/float)
    
    sll $s2, $s0, 3     # $s2 = N * 8. Armazena o offset de uma linha (2N * 4 bytes). ESSENCIAL.
    
    li $v0, 9           # syscall sbrk (alocação de memória na heap)
    syscall
    move $s1, $v0       # $s1 = Endereço base da matriz [A|I]

    # 4. Lê a Matriz Original A e constrói a Identidade I
    jal le_matriz

    # 5. Imprime a Matriz Original A 
    la $a0, MSG_ORIG
    li $v0, 4
    syscall
    
    move $a0, $s1       # Arg 1: Endereço Base da MAT_AUM
    move $a1, $s0       # Arg 2: Largura de impressão (N)
    li $a2, 0           # Arg 3: Coluna inicial para impressão (0)
    jal imprime_matriz

    # 6. Calcula a Inversa (Gauss-Jordan)
    move $a0, $s1       # Arg 1: Endereço Base
    move $a1, $s0       # Arg 2: N
    move $a2, $s2       # Arg 3: Largura da Linha em bytes (2N * 4)
    jal gauss_jordan    # O resultado (1 ou 0) volta em $v0
    
    # 7. Verifica o resultado
    beqz $v0, matriz_singular # Se $v0 == 0 (singular), salta para o erro.
    
    # 8. Imprime a Matriz Inversa A^-1 (A^-1 é as últimas N colunas)
    la $a0, MSG_INV
    li $v0, 4
    syscall
    
    move $a0, $s1       # Arg 1: Endereço Base
    move $a1, $s0       # Arg 2: Largura de impressão (N)
    move $a2, $s0       # Arg 3: Coluna inicial para impressão (N, i.e., I)
    jal imprime_matriz

fim_programa:
    # Restaura registradores globais e termina
    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    addi $sp, $sp, 12
    li $v0, 10          # syscall exit
    syscall
    
matriz_singular:
    # Imprime mensagem de matriz não-invertível
    la $a0, MSG_SING
    li $v0, 4
    syscall
    j fim_programa

erro_n_invalido:
    # Imprime mensagem de erro de N
    la $a0, MSG_ERRO_N
    li $v0, 4
    syscall
    j fim_programa
    
# ----------------------------------------------------
# PROCEDIMENTO: print_int_val (Auxiliar para UX)
# Imprime o valor inteiro em $a0.
# ----------------------------------------------------
print_int_val:
    addi $sp, $sp, -4
    sw $a0, 0($sp) # Salva $a0 para poder usá-lo na syscall
    li $v0, 1
    syscall        # Imprime o inteiro em $a0
    lw $a0, 0($sp) # Restaura $a0
    addi $sp, $sp, 4
    jr $ra

# ----------------------------------------------------
# PROCEDIMENTO: le_matriz
# Lê os N*N elementos de A e constrói a Matriz Aumentada [A|I].
# Usa: $s0 (N), $s1 (MAT_AUM base), $s2 (Largura da Linha em bytes)
# ----------------------------------------------------
le_matriz:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    move $t4, $s1       # $t4 (ptr) = Endereço base da Linha i
    li $t0, 0           # $t0 = i (contador de linha)

loop_i_leitura:
    bge $t0, $s0, fim_i_leitura # if (i >= N) goto fim_i_leitura
    li $t1, 0           # $t1 = j (contador de coluna)
    
loop_j_leitura:
    bge $t1, $s0, fim_j_leitura # if (j >= N) goto fim_j_leitura

    # --- UX: Imprime prompt A[i][j] e lê float (em $f0) ---
    la $a0, MSG_ELEM    
    li $v0, 4
    syscall
    move $a0, $t0       
    jal print_int_val
    la $a0, MSG_ELEM_2  
    li $v0, 4
    syscall
    move $a0, $t1       
    jal print_int_val
    la $a0, MSG_ELEM_3  
    li $v0, 4
    syscall
    
    li $v0, 6           # syscall read_float
    syscall             # Valor lido em $f0
    
    # --- Armazenamento de A[i][j] ---
    sll $t5, $t1, 2     # $t5 = j * 4 (Offset na linha)
    add $t6, $t4, $t5   # $t6 = Endereço de MAT_AUM[i][j]
    s.s $f0, 0($t6)     # Armazena o float lido (parte A)

    # --- Preenche I[i][j] em MAT_AUM[i][j+N] ---
    sll $t7, $s0, 2     # $t7 = N * 4 (Offset para pular a matriz A)
    add $t6, $t6, $t7   # $t6 = Endereço de MAT_AUM[i][j+N] (Parte I)
    
    beq $t0, $t1, set_identidade_1 # if (i == j)
    
set_identidade_0:
    li.s $f1, 0.0       # $f1 = 0.0
    j armazena_identidade
    
set_identidade_1:
    li.s $f1, 1.0       # $f1 = 1.0
    
armazena_identidade:
    s.s $f1, 0($t6)     # Armazena 0.0 ou 1.0
    
    addi $t1, $t1, 1    # j++
    j loop_j_leitura

fim_j_leitura:
    # Avança o ponteiro para a próxima linha: $t4 = $t4 + Largura_Linha_Bytes ($s2)
    add $t4, $t4, $s2   
    
    addi $t0, $t0, 1    # i++
    j loop_i_leitura
    
fim_i_leitura:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# ----------------------------------------------------
# PROCEDIMENTO: imprime_matriz
# Imprime uma submatriz de N linhas.
# Args: $a0=Base, $a1=Largura, $a2=Coluna_Inicial
# ----------------------------------------------------
imprime_matriz:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    move $t8, $a0       # $t8 = Endereço Base
    move $t9, $a1       # $t9 = Largura a imprimir (N)
    
    sll $t6, $a2, 2     # $t6 = Coluna inicial * 4 (Offset inicial de impressão)
    
    li $t0, 0           # $t0 = i (contador de linha)
    
loop_i_imprime:
    bge $t0, $s0, fim_i_imprime # if (i >= N) goto fim_i_imprime

    # Calcula endereço inicial da linha: Base + i * $s2 + $t6
    mul $t5, $t0, $s2       # $t5 = i * (2N*4) (Offset da linha em bytes)
    add $t2, $t8, $t5       # $t2 = Endereço base da linha i em MAT_AUM
    add $t2, $t2, $t6       # $t2 = Endereço inicial de A[i][col_inicial]
    
    li $t1, 0           # $t1 = j (contador de coluna)
    
loop_j_imprime:
    bge $t1, $t9, fim_j_imprime # if (j >= Largura) goto fim_j_imprime

    # Imprime o float (em $f12)
    l.s $f12, 0($t2)        # Carrega o float em $f12
    li $v0, 2               # syscall print_float
    syscall

    la $a0, MSG_SEP         # Imprime TAB
    li $v0, 4
    syscall

    addi $t2, $t2, 4        # Avança 4 bytes (próxima coluna)
    addi $t1, $t1, 1        # j++
    j loop_j_imprime

fim_j_imprime:
    la $a0, MSG_NL          # Imprime nova linha
    li $v0, 4
    syscall
    
    addi $t0, $t0, 1        # i++
    j loop_i_imprime
    
fim_i_imprime:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# ----------------------------------------------------
# PROCEDIMENTO: gauss_jordan
# Implementa a Eliminação de Gauss-Jordan.
# ----------------------------------------------------
gauss_jordan:
    # Salvando registradores (temporários dentro da função)
    addi $sp, $sp, -32
    sw $ra, 0($sp)
    sw $s3, 4($sp)      # $s3: i (Linha pivô)
    sw $s4, 8($sp)      # $s4: k (Linha a ser eliminada)
    sw $s5, 12($sp)     # $s5: Ptr Linha k
    sw $s6, 16($sp)     # $s6: Ptr Linha i
    sw $s7, 20($sp)     # $s7: 2N (limite de colunas)
    
    move $s1, $a0       # $s1 = Base
    move $s0, $a1       # $s0 = N
    move $s2, $a2       # $s2 = Largura da Linha em bytes (2N * 4)
    sll $s7, $s0, 1     # $s7 = 2N (Limite para loops de coluna j)

    li $s3, 0           # $s3 = i (Linha pivô/atual)

loop_i_pivot:
    bge $s3, $s0, fim_gauss_jordan  # Loop principal: itera sobre as N linhas/colunas do pivot

    # --- 1. Encontrar o Pivot A[i][i] ---
    sll $t0, $s3, 2             # $t0 = i * 4 (Offset da coluna i)
    mul $t1, $s3, $s2           # $t1 = i * (2N*4) (Offset da linha i)
    add $s6, $s1, $t1           # $s6 = Endereço base da linha i (Pivô)
    add $t2, $s6, $t0           # $t2 = Endereço de A[i][i]
    l.s $f2, 0($t2)             # $f2 = A[i][i] (Pivot)
    
    # DETECÇÃO DE SINGULARIDADE (Se Pivot == 0, a matriz é singular)
    li.s $f1, 0.0               # $f1 = 0.0
    c.eq.s $f2, $f1             # Compara $f2 com 0.0
    bc1t matriz_singular_gj_local # Se igual, salta para indicar erro

    # --- 2. Normalizar a linha i: Linha[i] = Linha[i] / Pivot ---
    li.s $f1, 1.0               # Garante que $f1 = 1.0
    div.s $f3, $f1, $f2         # $f3 = 1.0 / Pivot (Fator de normalização)
    
    li $t3, 0                   # $t3 = j (contador de coluna)
    
loop_j_normaliza:
    bge $t3, $s7, fim_j_norm    # Loop J: itera de 0 a 2N-1
    
    sll $t5, $t3, 2             # $t5 = j * 4 (Offset na coluna)
    add $t6, $s6, $t5           # $t6 = Endereço de MAT_AUM[i][j]
    l.s $f4, 0($t6)             # $f4 = A[i][j]
    
    mul.s $f4, $f4, $f3         # A[i][j] = A[i][j] * (1/Pivot)
    s.s $f4, 0($t6)             
    
    addi $t3, $t3, 1            
    j loop_j_normaliza

fim_j_norm:
    # --- 3. Eliminação das outras linhas (k): Lk = Lk - Fator * Li ---
    li $s4, 0           # $s4 = k (Linha a ser eliminada)

loop_k_elimina:
    bge $s4, $s0, fim_k_elimina     # Loop K: itera de 0 a N-1
    beq $s4, $s3, next_k_elimina    # Se k == i, salta (não elimina a linha pivô)

    #  Carregar A[k][i] (Fator de eliminação)
    mul $t5, $s4, $s2       # $t5 = k * (2N*4) 
    add $s5, $s1, $t5       # $s5 = Endereço base da linha k
    sll $t0, $s3, 2         # $t0 = i * 4
    add $t2, $s5, $t0       # $t2 = Endereço de A[k][i]
    l.s $f5, 0($t2)         # $f5 = Fator A[k][i] (Multiplicador)
    
    #  Subtração da Linha (Loop J aninhado)
    li $t3, 0           # $t3 = j (contador de coluna)

loop_j_subtrai:
    bge $t3, $s7, fim_j_subt    # Loop J: itera de 0 a 2N-1
    
    sll $t5, $t3, 2             
    
    # Elemento pivô normalizado da linha i (A[i][j])
    add $t6, $s6, $t5           
    l.s $f6, 0($t6)             
    
    # Elemento atual da linha k (A[k][j])
    add $t6, $s5, $t5           
    l.s $f7, 0($t6)             

    # CÁLCULO: A[k][j] = A[k][j] - Fator * A[i][j]
    mul.s $f8, $f5, $f6         
    sub.s $f7, $f7, $f8         
    s.s $f7, 0($t6)             
    
    addi $t3, $t3, 1            
    j loop_j_subtrai

fim_j_subt:
    # Garante que o elemento A[k][i] seja zero após a eliminação
    li.s $f1, 0.0 
    s.s $f1, 0($t2)             

next_k_elimina:
    addi $s4, $s4, 1            
    j loop_k_elimina

fim_k_elimina:
    addi $s3, $s3, 1            # i++ (Próximo pivot)
    j loop_i_pivot

fim_gauss_jordan:
    li $v0, 1                   # Retorna 1 (Sucesso: Invertível)
    j restaura_gauss_jordan

matriz_singular_gj_local:
    li $v0, 0                   # Retorna 0 (Erro: Singular)

restaura_gauss_jordan:
    # Restaura registradores salvos e retorna
    lw $ra, 0($sp)
    lw $s3, 4($sp)
    lw $s4, 8($sp)
    lw $s5, 12($sp)
    lw $s6, 16($sp)
    lw $s7, 20($sp)
    addi $sp, $sp, 32
    jr $ra