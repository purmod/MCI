function d_hat = estimateDepth_CRA(d, c, p, N, M, A, e_s, e_a, e_i, f_mod, T)



%% Parameters
tau = 2*d/c;                                        % time-of-flight
sampleN = size(e_s, 1);                             % number of samples
Tslot = T/M;                                        % slot integration time



%% Generate binary ON/OFF sequences
binarySeq = binornd(1, p, N+1, M);                  % N+1 by M matrix: 1st row:primary camera, 2nd~Nth rows:interfering cameras



%% Generate random relative starting point for interfering cameras
% start = 2*rand(N, 1) - 1;                           % -1.0 ~ 1.0
start = zeros(N, 1);    % for sychronized approach



%% Find ON slots of primary camera
ONIdx = find(binarySeq(1, :) == 1);
M_ON = size(ONIdx, 2);                              % Number of the ON slots



%% Estimate interference amount due to interfering cameras
itfAmnt = estItfAmnt(N, binarySeq, start, ONIdx);   % 1 by M_ON vector with interference amount



%% Get ground-truth non-clashed slots of primary camera
noClshIdxGT = ONIdx(itfAmnt == 0);                  % Non-clashed slot index
M_noclsh = size(noClshIdxGT, 2);                    % Number of non-clashed slots
if (M_noclsh == 0)
    error('All slots clashed');
end



%% Get correlation values
C1 = zeros(sampleN, M_ON);
C2 = zeros(sampleN, M_ON);
C3 = zeros(sampleN, M_ON);
C4 = zeros(sampleN, M_ON);

for m = 1 : M_ON
    
    C1(:, m) = Tslot*(A*e_s + e_a + itfAmnt(1, m)*A*e_i + A*e_s/2.*cos(2*pi*f_mod.*tau));
    C2(:, m) = Tslot*(A*e_s + e_a + itfAmnt(1, m)*A*e_i - A*e_s/2.*sin(2*pi*f_mod.*tau));
    C3(:, m) = Tslot*(A*e_s + e_a + itfAmnt(1, m)*A*e_i - A*e_s/2.*cos(2*pi*f_mod.*tau));
    C4(:, m) = Tslot*(A*e_s + e_a + itfAmnt(1, m)*A*e_i + A*e_s/2.*sin(2*pi*f_mod.*tau));
end



%% Add photon noise
C1 = poissrnd(C1);
C2 = poissrnd(C2);
C3 = poissrnd(C3);
C4 = poissrnd(C4);



%% Check clash
noClshIdx = noClshIdxGT;                          % Use ground truth

% k = 2;
% noClshIdx = checkClash(C1, C2, C3, C4, ONIdx, k);   % Use clash check algorithm



%% Extract non-clashed slots
[yesno, memberIdx] = ismember(noClshIdx, ONIdx);
C1 = C1(:, memberIdx);
C2 = C2(:, memberIdx);
C3 = C3(:, memberIdx);
C4 = C4(:, memberIdx);



%% Sum correlation values
C1 = sum(C1, 2);
C2 = sum(C2, 2);
C3 = sum(C3, 2);
C4 = sum(C4, 2);



%% Decode
phase_hat = atan2((C4-C2) , (C1-C3));
phase_hat(phase_hat<0) = phase_hat(phase_hat<0) + 2*pi;
d_hat = c/(4*pi*f_mod)*phase_hat;



