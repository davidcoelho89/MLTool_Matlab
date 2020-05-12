function [C] = convolucao(A, B)
% [C] = convolucao(A, B)
% Determina a convolu��o entre dois vetores (2 sinais no tempo)
%   entradas:
%       - A: sinal 01
%       - B: sinal 02
%   Saidas:
%       - C: Resultado da convolu��o

len_A = length(A);  % tamanho do sinal A
len_B = length(B);  % tamanho do sinal B
len_C = max([len_A+len_B-1, len_A, len_B]); % sinal convoluido

C = zeros(1,len_C); % inicializa o sinal C

for x = 1:len_C,
    for j = 1:len_C,

        ind_A = j;      % indice do vetor A que ser� multiplicado
        ind_B = x-j+1;  % indice do vetor B que ser� multiplicado
        
        if ((ind_A > 0) & (ind_A < len_A) & (ind_B > 0) & (ind_B < len_B)),
            C(x) = C(x) + A(ind_A)*B(ind_B);
        else
            continue;
        end
    end
end
