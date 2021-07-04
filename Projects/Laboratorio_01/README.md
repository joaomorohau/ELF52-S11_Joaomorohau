# ELF52-S11_Joaomorohau
Laboratório 01 - Exercicio 3

Os valores negatiovs são codificados com uso de binarios com sinais, e se o sufixo S for aplicado, a FLAG APSR detecta o negativo (N).
A mesma tambem detecta se houve carry(C), se o valor for zero (Z) entre outros, sendo que seu valor altera para cada caso, podendo ser comparado.

Quando são trocados as instruções MOV por MVNS, como vistos nos registradores R7 a R12, a flag APSR é forçada a alterar (pela adição do sufixo S) e apresenta a natureza explicada acima.

MVN move o valor negado da constante hexadecimal 0x0000'0055, que se torna 0xffff'ffaa e faz o mesmo nas demais linhas, sempre movendo o valor negado.
ROR, RRX, LSL e LSR atuam de mesma forma que o circuito original. Mas é interessante observar que ASR causa uma sutil diferença quando numeros negativos são alterados.

Com ambas instruçoes e com o sufixo S indicado, pode-se observar o valor de APSR mudar constantemente, pois as varias negações e deslocamentos alteram os valores de C e N do flag.
De forma geral, a aplicação foi bem sucedida e a movimentação de BITs pode ser vista como fundamental para criação de programas em asm.
