function [ fMatrix ] = forward_algorithm( data,param,age_stack,index,rhos,phi )
%% This function generates the forward sum matrix.

% L = length of data in the core
% T = length of age in the stack

% Inputs:
% data: a Lx3-matrix where the first column has the depth indexes and the
% third one has the del-O18 data
% param: a structure of parameters consisting of the following:
% param.mu: a 1xT-vector of means
% param.sigma: a 1xT-vector of standard deviations
% param.shift: a 1xC-vector of shifts
% age_stack: a 1xT-vector of ages in stack
% ETable: file index.
% rhos: a 3x1-cell where the first one is rho_table and the second one is
% grid.
% phi: a hyperparameter for controlling the length of unaligned regions.

% Outputs:
% fMatrix: a TxTxL-forward matrix computed by the forward algorithm

%% Define variables:

% length constants
T = size(age_stack,2);
L = size(data,1);
fMatrix = zeros(T,T,L);
n = 2;

% emission log - probability
E_del = Emission_del_O18(data,param,index); % include radiocarbon emision...?

% delta depth and age
depth = data(:,1);
d_depth = abs(depth(2:end) - depth(1:end-1));
d_time = age_stack' - age_stack +  0.5 * eye(T);

% sedementation rate parameters
rho_table = log([zeros(3,1),rhos{1}]);
rho_dist = log([0,rhos{2}]);
rho_values = rhos{3};
grid1 = [log(0.9220),log(1.0850), inf];
phi = log(phi);


%% Initial n = 2

emission = E_del(1,:)' + E_del(2,:);
sed_rate = d_time / d_depth(n - 1);
[~,~,bin] = histcounts(sed_rate,rho_values);
transition = rho_dist(bin+1);
fMatrix(:,:,n) = emission + transition + (0:T-1)' * phi;
n = n + 1;

%% Iterative n > 2

while n <= L
    emission = E_del(n,:);
    sed_rate = d_time / d_depth(n - 1);
    [~,~,bin] = histcounts(sed_rate,rho_values);
    prev_sed_rate = d_time / d_depth(n - 2);
    [~,~,index] = histcounts(prev_sed_rate,grid1);
    
    % loop for tn
    for tn = 1:T
        % loop for tn-1
        for tn_1 = 1:T
            % loop for t
            transitions = zeros(1,tn_1);
            for t = 1:tn_1
                transitions(t) = rho_table(index(t,tn_1) + 1, bin(tn_1, tn) + 1) + fMatrix(t,tn_1,n - 1);
            end
            % find max and compute sum to avoid underflow
            mTrans = max(transitions);
            transition = mTrans + log(sum(exp(transitions - mTrans)));
            if isnan(transition)
                transition = -Inf;
            end
            % update fMatrix
            fMatrix(tn_1,tn,n) = emission(t) + transition;
        end
    end
    
    n = n + 1;
end

disp('Forward algorithim is done.');

end


%% General questions for Taehee
% - Are values in Rho_table log probabilites or just probability?
% - How to handle sum of probabilities in iterative case when taking log?
% - Use repmat?
