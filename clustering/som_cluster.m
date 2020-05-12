function [PARout] = som_cluster(DATA,PAR)

% --- SOM Clustering Function ---
%
%   [PARout] = som_cluster(DATA,PAR)
%
%   Input:
%       DATA.
%           input = input matrix                            [p x N]
%       PAR.
%           Nep = max number of epochs                    	[cte]
%           Nk = number of prototypes (neurons)             [1 x Nd]
%                (Nd = dimenions)
%           init = type of initialization for prototypes    [cte]
%               1: C = zeros
%               2: C = randomly picked from data
%               3: C = mean of randomly choosen data
%               4: C = between max and min values of atrib
%           dist = type of distance                         [cte]
%               0: Dot product
%               inf: Chebyshev distance
%               -inf: Minimum Minkowski distance
%               1: Manhattam (city-block) distance
%               2: Euclidean distance
%           learn = type of learning step                   [cte]
%               1: N = No (constant)
%               2: N = No*(1-(t/tmax))
%               3: N = No/(1+t)
%               4: N = No*((Nt/No)^(t/tmax))
%           No = initial learning step                      [cte]
%           Nt = final learning step                        [cte]
%           Nn = number of neighbors (for training)         [cte]
%           neig = type of neighborhood function            [cte]
%               1: if winner, or neighbor, h = 1, else h = 0.
%               2: if neighbor, h = exp (-(||ri - ri*||^2)/(V^2))
%                     where: V = Vo*((Vt/Vo)^(t/tmax))
%               3: Decreasing function 1. Init with 3 neig
%           Vo = initial neighborhood parameter             [cte]
%           Vt = final neighborhood parameter               [cte]
%           Von = enable or disable video                   [cte]
%           K = number of nearest neighbors (classify)      [cte]
%           Ktype = Kernel Type                             [cte]
%               = 0 -> non-kernelized algorithm
%   Output:
%       PARout.
%       	Cx = clusters centroids (prototypes)            [p x Nk]
%           R = prototypes' grid positions                  [Nd x Nk]
%           ind = cluster index for each sample             [1 x N]
%           SSE = Sum of Squared Errors for each epoch      [1 x Nep]
%           VID = frame struct (played by 'video function')	[1 x Nep]

%% SET DEFAULT HYPERPARAMETERS

if ((nargin == 1) || (isempty(PAR))),
    PARaux.Nep = 200;     	% max number of epochs
    PARaux.Nk = [4 3];   	% number of neurons (prototypes)
    PARaux.init = 2;     	% neurons' initialization
    PARaux.dist = 2;      	% type of distance
    PARaux.learn = 2;     	% type of learning step
    PARaux.No = 0.7;       	% initial learning step
    PARaux.Nt = 0.01;      	% final learnin step
    PARaux.Nn = 1;      	% number of neighbors
    PARaux.neig = 2;      	% type of neighborhood function
    PARaux.Vo = 0.8;      	% initial neighborhood constant
    PARaux.Vt = 0.3;      	% final neighborhood constant
    PARaux.lbl = 1;         % Neurons' labeling function
    PARaux.Von = 0;         % disable video 
    PARaux.K = 1;           % Number of nearest neighbors (classify)
    PARaux.Ktype = 0;       % Non-kernelized Algorithm
    PAR = PARaux;
else
    if (~(isfield(PAR,'Nep'))),
        PAR.Nep = 200;
    end
    if (~(isfield(PAR,'Nk'))),
        PAR.Nk = [4 3];
    end
    if (~(isfield(PAR,'init'))),
        PAR.init = 2;
    end
    if (~(isfield(PAR,'dist'))),
        PAR.dist = 2;
    end
    if (~(isfield(PAR,'learn'))),
        PAR.learn = 2;
    end
    if (~(isfield(PAR,'No'))),
        PAR.No = 0.7;
    end
    if (~(isfield(PAR,'Nt'))),
        PAR.Nt = 0.01;
    end
    if (~(isfield(PAR,'Nn'))),
        PAR.Nn = 1;
    end
    if (~(isfield(PAR,'neig'))),
        PAR.neig = 2;
    end
    if (~(isfield(PAR,'Vo'))),
        PAR.Vo = 0.8;
    end
    if (~(isfield(PAR,'Vt'))),
        PAR.Vt = 0.3;
    end
    if (~(isfield(PAR,'lbl'))),
        PAR.lbl = 1;
    end
    if (~(isfield(PAR,'Von'))),
        PAR.Von = 0;
    end
    if (~(isfield(PAR,'K'))),
        PAR.K = 1;
    end
    if (~(isfield(PAR,'Ktype'))),
        PAR.Ktype = 0;
    end
end

%% INITIALIZATION

% Get Data

X = DATA.input;
[~,N] = size(X);

% Get hyperparameters

Nep = PAR.Nep;
Nk = PAR.Nk;
learn = PAR.learn;
No = PAR.No;
Nt = PAR.Nt;
Nn = PAR.Nn;
neig = PAR.neig;
Vo = PAR.Vo;
Vt = PAR.Vt;
Von = PAR.Von;

% Init aux variables

tmax = N*Nep;       % max number of iterations
t = 0;              % count iterations

% Init Outputs

if (isfield(PAR,'Cx')),
    Cx = PAR.Cx;
    [~,Nk] = size(Cx);
else
    Cx = prototypes_init(DATA,PAR);
end

ind = zeros(1,N);

SSE = zeros(1,Nep);

VID = struct('cdata',cell(1,Nep),'colormap', cell(1,Nep));

%% ALGORITHM

% Assign grid positions (R)
Nk_lenght = length(Nk);
if (Nk_lenght == 1),
    R = 1:Nk;
else
    Nk_t = prod(Nk);
    R = zeros(Nk_lenght,Nk_t);
    r = ones(Nk_lenght,1);
    for k = 1:Nk_t,
        % Generate vecotr of positions
        R(:,k) = r;
        % Update r
        i = 1;
        while(i <= Nk_lenght),
            r(i) = r(i) + 1;
            if(r(i) > Nk(i)),
                r(i) = 1;
                i = i+1;
            else
                break;
            end
        end
    end
end

% Update Nk
Nk = prod(Nk);

% Verify if it is a decreasing neighboorhood function
if neig == 3,
    decay = 1;
else
    decay = 0;
end

for ep = 1:Nep,
    
	% Save frame of the current epoch
    if (Von),
        VID(ep) = prototypes_frame(Cx,DATA);
    end
    
    % shuffle data
    I = randperm(N);
    X = X(:,I);
    
    % Update Neurons (one epoch)
    for i = 1:N,
        
        % Uptade Iteration
        t = t+1;
        
        % Update decreasing neighboorhood function of SOM
        [out_decay] = prototypes_decay(decay,Nn,neig,t,ep);
        Nn      = out_decay.Nn;
        neig    = out_decay.neig;
        t       = out_decay.t;
        
        % Get Winner Neuron and Learning Step
        xn = X(:,i);                                % Training Sample
        win = prototypes_win(Cx,xn,PAR);            % Winner Neuron Index
        n = prototypes_learn(learn,tmax,t,No,Nt);	% Learning Step
        
        % Uptade Neurons (Prototypes)
        for k = 1:Nk,
            % Get grid positions of winner and current prototype
            r_k = R(:,k);
            r_win = R(:,win);
            % Calculate Neighborhood function
            h = som_f_neig(neig,r_k,r_win,Nn,t,tmax,Vo,Vt);
            % Update function
            Cx(:,k) = Cx(:,k) + n*h*( xn - Cx(:,k) );
        end
        
    end
    
    % SSE (one epoch)
    SSE(ep) = prototypes_sse(Cx,DATA,PAR);
    
end

% Assign indexes
for i = 1:N,
    xn = DATA.input(:,i);               % not shuffled data
    win = prototypes_win(Cx,xn,PAR); 	% Winner Neuron index
    ind(i) = win;                       % save index for sample
end

%% FILL OUTPUT STRUCTURE

PARout = PAR;
PARout.Cx = Cx;
PARout.R = R;
PARout.ind = ind;
PARout.SSE = SSE;
PARout.VID = VID;

%% END