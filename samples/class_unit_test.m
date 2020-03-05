%% Machine Learning ToolBox

% Classification Algorithms - Unit Test
% Author: David Nascimento Coelho
% Last Update: 2020/02/02

close;          % Close all windows
clear;          % Clear all variables
clc;            % Clear command window

format long e;  % Output data style (float)

%% GENERAL DEFINITIONS

% General options' structure

OPT.prob = 06;              % Which problem will be solved / used
OPT.prob2 = 30;             % More details about a specific data set
OPT.norm = 0;               % Normalization definition
OPT.lbl = 1;                % Labeling definition
OPT.Nr = 005;              	% Number of repetitions of the algorithm
OPT.hold = 2;               % Hold out method
OPT.ptrn = 0.7;             % Percentage of samples for training
OPT.file = 'fileX.mat';     % file where all the variables will be saved

%% CHOOSE ALGORITHM

% Handlers for classification functions

class_name = 'k2nn';
class_train = @k2nn_train;
class_test = @k2nn_classify;

%% CHOOSE HYPERPARAMETERS

% Kernel Functions: 1 lin / 2 gauss / 3 poly / 5 cauchy / 6 log / 7 sigm /

HP.Dm = 2;          % Design Method
HP.Ss = 1;          % Sparsification strategy
HP.v1 = 0.005;      % Sparseness parameter 1 
HP.v2 = 0.9;        % Sparseness parameter 2
HP.Ps = 0;          % Prunning strategy
HP.min_score = -10; % Score that leads the sample to be pruned
HP.Us = 0;          % Update strategy
HP.eta = 0.01;      % Update rate
HP.max_prot = Inf;  % Max number of prototypes
HP.Von = 1;         % Enable / disable video 
HP.K = 1;           % Number of nearest neighbors (classify)
HP.Ktype = 7;       % Kernel Type
HP.sig2n = 0.001;   % Kernel Regularization parameter
HP.sigma = 2;    	% Kernel width (gaussian)
HP.gamma = 2;       % polynomial order (poly 2 or 3)
HP.alpha = 0.1;     % Dot product multiplier (poly 1 / sigm 0.1)
HP.theta = 0.1;     % Dot product adding (poly 1 / sigm 0.1)

%% DATA LOADING AND PRE-PROCESSING

DATA = data_class_loading(OPT);     % Load Data Set
DATA = label_encode(DATA,OPT);      % adjust labels for the problem

%% ACCUMULATORS

NAMES = {'train','test'};           % Acc of names for plots
DATA_acc = cell(OPT.Nr,1);       	% Acc of Data
PAR_acc = cell(OPT.Nr,1);         	% Acc of Parameters and Hyperparameters
STATS_tr_acc = cell(OPT.Nr,1);   	% Acc of Statistics of training data
STATS_ts_acc = cell(OPT.Nr,1);   	% Acc of Statistics of test data
nSTATS_all = cell(2,1);             % Acc of General statistics

%% HOLD OUT / TRAINING / TEST / STATISTICS

display('Begin Algorithm');

for r = 1:OPT.Nr,

% %%%%%%%%% DISPLAY REPETITION AND DURATION %%%%%%%%%%%%%%

display(r);
display(datestr(now));

% %%%%%%%%%%%%%%%%%%%% HOLD OUT %%%%%%%%%%%%%%%%%%%%%%%%%%

DATA_acc{r} = hold_out(DATA,OPT);   % Hold Out Function
DATAtr = DATA_acc{r}.DATAtr;        % Training Data
DATAts = DATA_acc{r}.DATAts;      	% Test Data

% %%%%%%%%%%%%%%%%% NORMALIZE DATA %%%%%%%%%%%%%%%%%%%%%%%

% training data normalization

DATAtr = normalize(DATAtr,OPT);

% test data normalization

DATAts.Xmin = DATAtr.Xmin;
DATAts.Xmax = DATAtr.Xmax;
DATAts.Xmed = DATAtr.Xmed;
DATAts.Xdp = DATAtr.Xdp;

DATAts = normalize(DATAts,OPT);

% Adjust Values for video function

DATAtr.Xmax = max(DATAtr.input,[],2);  % max value
DATAtr.Xmin = min(DATAtr.input,[],2);  % min value
DATAtr.Xmed = mean(DATAtr.input,2);    % mean value
DATAtr.Xdp = std(DATAtr.input,[],2);   % std value

% %%%%%%%%%%%%%% SHUFFLE TRAINING DATA %%%%%%%%%%%%%%%%%%%

I = randperm(size(DATAtr.input,2));
DATAtr.input = DATAtr.input(:,I);
DATAtr.output = DATAtr.output(:,I);
DATAtr.lbl = DATAtr.lbl(:,I);

% %%%%%%%%%%%%%% CLASSIFIER'S TRAINING %%%%%%%%%%%%%%%%%%%

PAR_acc{r} = class_train(DATAtr,HP);	% Calculate parameters

% %%%%%%%%% CLASSIFIER'S TEST AND STATISTICS %%%%%%%%%%%%%

OUTtr = class_test(DATAtr,PAR_acc{r});          	% Outputs with training data
STATS_tr_acc{r} = class_stats_1turn(DATAtr,OUTtr);  % Results with training data

OUTts = class_test(DATAts,PAR_acc{r});          	% Outputs with test data
STATS_ts_acc{r} = class_stats_1turn(DATAts,OUTts);  % Results with test data

end

display('Finish Algorithm')
display(datestr(now));

%% RESULTS / STATISTICS

% Statistics for n turns

nSTATS_tr = class_stats_nturns(STATS_tr_acc);
nSTATS_ts = class_stats_nturns(STATS_ts_acc);

% Get all Statistics in one Cell

nSTATS_all{1,1} = nSTATS_tr;
nSTATS_all{2,1} = nSTATS_ts;

%% GRAPHICS - DECISION BOUNDARY / ROC CURVE / PRECISION-RECALL

% % Plot Decision boundary (of last test)
% if (Nc == 2),
%     figure;
%     plot_class_boundary(DATA,PAR_acc{r},class_test);
% end
% 
% % Plot one ROC Curve (1 - spec x sens) for each class (of last test)
% for c = 1:Nc,
%     figure;
%     plot(STATS_ts_acc{r}.roc_fpr(c,:),STATS_ts_acc{r}.roc_tpr(c,:),'r.-');
%     axis([-0.1 1.1 -0.1 1.1])
%     hold on
%     plot([0,0,1],[0,1,1],'k-');
%     hold off
% end
% 
% % Plot one Precision-Recall Curve for each class (of last test)
% for c = 1:Nc,
%     figure;
%     plot(STATS_ts_acc{r}.roc_prec(c,:),STATS_ts_acc{r}.roc_rec(c,:),'r.-');
%     axis([-0.1 1.1 -0.1 1.1])
%     hold on
%     plot([0,0,1],[0,1,1],'k-');
%     hold off
% end

%% BOXPLOT OF TRAINING AND TEST ACCURACIES

class_stats_ncomp(nSTATS_all,NAMES);

%% SAVE DATA

% save(OPT.file);

%% END