%% this script performs an example of all steps of the system identification available  at this repository

clear all
close all
clc


%% steps to perfrom
identifyModel = true;
identifyNoise = true;
identifyComplete = true;
computeGFRF = true; % if you do not have the Symbolic Toolbox,set this to false. The other parts of the system 
                    %identification will work normally

%% data

% obtain a signal of the system y(k) = 0.3*y(k-1) + 2*x(k-1)*x(k-2). You
% can change it as you wish, or use your own data collected elsewhere.
% The data must be in column format. It is also possible to use in the same
% identification process different data acquisitions from the same system.
% Each data acquisition must be in a different column and the columns from
% the input matrix must be correspondent to the columns from the output
% matrix

Fs = 100; % Sampling frequency of the data acquisition, in Hz. It is used only for the GFRFs computation

x = randn(2000,1);
y = zeros(size(x));

for k = 3:length(y)
   y(k) = 0.3*y(k-1) + 2*x(k-1)*x(k-2); 
end

%% 
input = x(100:end);  %throw away the first 100 samples to avoid transient effects
output = y(100:end);  %throw away the first 100 samples to avoid transient effects
mu = 2; % maximal lag for the input. In this case, we know that mu is 2 but normally we do not!
my = 1; % maximal lag for the output. In this case, we know that my is 1 but normally we do not!   
degree = 2; % maximal polynomial degree. In this case, we know that degree is 2 but normally we do not! 
delay = 0; % the number of samplings that takes to the input signal effect the output signal. In this case we know that 
%degree is 2 but normally we do not! 
dataLength = 500; % number of samplings to be used during the identification process. Normally a number between 400 and
% 600 is good. Do not use large numbers.
divisions = 1; %Number of parts of the each data acquisition to be used in the identification process
pho = 1e-1; % a lower value will give you more identified terms. A higher value will give you less.
phoL = 1e-1; % a lower value will give you more identified terms. A higher value will give you less. This is only used 
%if you want to compute the GFRFs, to guarantee that at least one term will be linear. In this case, change the variable
%flag in %NARXModelIdentificationOf2Signals.m  file to 1



%%
if identifyModel
    
    [Da, a, la, ERRs] = NARXModelIdentificationOf2Signals(input, output, degree, mu, my, delay, dataLength, divisions, ...
        phoL, pho);
    %%
    identModel.terms = Da;
    identModel.termIndices = la;
    identModel.coeff = a;
    identModel.degree = degree;
    identModel.Fs = Fs;
    identModel.ESR = 1-ERRs;
    %%    
    save(['testIdentifiedModel' num2str(Fs) '.mat'], 'identModel');
else
    load(['testIdentifiedModel' num2str(Fs) '.mat']);
    Da = identModel.terms;
    la = identModel.termIndices;
    a = identModel.coeff;
    degree = identModel.degree;
    Fs = identModel.Fs;
end

%%

if identifyNoise
    degree = identModel.degree;
    me = 2;  
    phoN = 1e-2;
    [Dn, an, ln] = NARXNoiseModelIdentification(input, output, degree, mu, my, me, delay, dataLength, divisions, phoN,  ...
        identModel.coeff, identModel.termIndices);
    %%
    identModel.noiseTerms = Dn;
    identModel.noiseTermIndices = ln;
    identModel.noiseCoeff = an;
    %%
    save(['testIdentifiedModel' num2str(Fs) '.mat'], 'identModel');
else
    load(['testIdentifiedModel' num2str(Fs) '.mat']);  
    Dn = identModel.noiseTerms;
    ln = identModel.noiseTermIndices;
    an = identModel.noiseCoeff;
end

%%

if identifyComplete
    delta = 1e-1;
    [a, an, xi] = NARMAXCompleteIdentification((input), output, identModel.terms, identModel.noiseTerms, dataLength, ...
        divisions,  delta, identModel.degree, identModel.degree);
    %%
    identModel.finalCoeff = a;
    identModel.finalNoiseCoeff = an;
    identModel.residue = xi;
    identModel.delta = delta;
    %%
    save(['testIdentifiedModel' num2str(Fs) '.mat'], 'identModel');
else
    load(['testIdentifiedModel' num2str(Fs) '.mat']);      
end

disp(identModel.terms)
disp(identModel.finalCoeff)


%%

if computeGFRF
    Hn = computeSignalsGFRF(identModel.terms, identModel.Fs, identModel.finalCoeff, identModel.degree)
    %%
    identModel.GFRF = Hn;    
    %%
    save(['testIdentifiedModel' num2str(Fs) '.mat'], 'identModel');
    disp('GFRF of order 1: ')
    disp(identModel.GFRF{1}{1})
    disp('GFRF of order 2: ')
    disp(identModel.GFRF{1}{2})
else
    load(['testIdentifiedModel' num2str(Fs) '.mat']);      
end

