% reads input_vectors.txt file and perform floating point operations for circuit validation
clear all;
close all;
disp('Script iniciado!');

% leitura de entradas
fname="C:/Users/renan/Documents/FPGA projects/fpu_single_precision/simulation/modelsim/input_vectors.txt";
fid=fopen(fname,"r");
[val]=textscan(fid,"%s");
fclose(fid);

val=val{1,1};
##disp('val');
##disp(val);

disp('Entradas lidas');
inputs=hex2num(val,"single");
%disp(inputs)
L=length(inputs);

% loop de operações de ponto flutuante
% os operandos são os pares de inputs
for i=1:floor(L/2)
  a=inputs(2*i-1);
  b=inputs(2*i);
  y(i)= a + b;
end
##y=single(y);% converte y para precisão simples

Ly=length(y);
%ESCRITA DE ARQUIVO
disp('Resultados calculados no octave');
% escrita dos resultados das operações
convertidos=toupper(num2hex(single(y))); % string a ser impressa
s=blanks(9*Ly);
for i=1:Ly
  s(9*i-8:9*i)=[convertidos(i,:) "\n"];
end

disp('Escrevendo arquivo de resultados');
fname="C:/Users/renan/Documents/FPGA projects/fpu_single_precision/simulation/modelsim/octave_results.txt";
fid=fopen(fname,"w");
fprintf(fid,"%s",s);
fclose(fid);