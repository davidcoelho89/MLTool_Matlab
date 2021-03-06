%% Machine Learning ToolBox

% Sample used to run isk2nn and a Stationary DataSet
% Author: David Nascimento Coelho
% Last Update: 2020/05/11

close;          % Close all windows
clear;          % Clear all variables
clc;            % Clear command window

format long e;  % Output data style (float)

%% GENERAL DEFINITIONS

% 6 - iris / 7 - motor failure / 10 - Vertebral Column / 
% 19 - cervical cancer / 20 - Sensorless Drive / 22 - Wall Following /

% General options' structure

OPT.prob = 19;              % Which problem will be solved / used
OPT.prob2 = 02;             % More details about a specific data set
OPT.norm = 3;               % Normalization definition
OPT.lbl = 1;                % Labeling definition. 1: [-1 +1] pattern
OPT.Nr = 10;              	% Number of repetitions of the algorithm
OPT.hold = 2;               % Hold out method
OPT.ptrn = 0.7;             % Percentage of samples for training
OPT.file = 'cervical_isk2nn_hpo1_norm3_Dm2_Ss1_Us1_Ps2_gau_nn.mat';     

% Grid Search Parameters

GSp.fold = 5;       % number of data partitions for cross validation
GSp.type = 2;       % Takes into account also the dicitionary size
GSp.lambda = 2; 	% Jpbc = Ds + lambda * Err

%% HYPERPARAMETERS - DEFAULT

HP.Dm = 2;                  % Design Method
HP.Ss = 1;                  % Sparsification strategy
HP.v1 = 0.8;                % Sparseness parameter 1 
HP.v2 = 0.9;                % Sparseness parameter 2
HP.Us = 1;                  % Update strategy
HP.eta = 0.1;               % Update rate
HP.Ps = 2;                  % Prunning strategy
HP.min_score = -10;         % Score that leads the sample to be pruned
HP.max_prot = 600;          % Max number of prototypes
HP.min_prot = 1;            % Min number of prototypes
HP.Von = 0;                 % Enable / disable video 
HP.K = 1;                   % Number of nearest neighbors (classify)
HP.knn_type = 2;            % Type of knn aproximation
HP.Ktype = 2;               % Kernel Type (2: Gaussian / see kernel_func())
HP.sig2n = 0.001;           % Kernel Regularization parameter
HP.sigma = 2;               % Kernel width (gauss, exp, cauchy, log, kmod)
HP.alpha = 0.1;             % Dot product multiplier (poly 1 / sigm 0.1)
HP.theta = 0.1;             % Dot product adding (poly 1 / sigm 0.1)
HP.gamma = 2;               % polynomial order (poly 2 or 3)

%% HYPERPARAMETERS - FOR OPTIMIZATION

HPgs = HP;
HPgs.v1 = 2.^linspace(-4,3,8);
HPgs.v2 = HPgs.v1(end) + 0.001;
HPgs.sigma = 2.^linspace(-10,9,20);

%% DATA LOADING, PRE-PROCESSING, VISUALIZATION

DATA = data_class_loading(OPT);     % Load Data Set

DATA = label_encode(DATA,OPT);      % adjust labels for the problem

% plot_data_pairplot(DATA);           % See pairplot of attributes

%% ACCUMULATORS

NAMES = {'train','test'};           % Acc of names for plots
DATA_acc = cell(OPT.Nr,1);       	% Acc of Data
PAR_acc = cell(OPT.Nr,1);         	% Acc of Parameters and Hyperparameters
STATS_tr_acc = cell(OPT.Nr,1);   	% Acc of Statistics of training data
STATS_ts_acc = cell(OPT.Nr,1);   	% Acc of Statistics of test data
nSTATS_all = cell(2,1);             % Acc of General statistics

%% HOLD OUT / NORMALIZE / SHUFFLE / HPO / TRAINING / TEST / STATISTICS

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

% Get Normalization Parameters

PARnorm = normalize_fit(DATAtr,OPT);

% Training data normalization

DATAtr = normalize_transform(DATAtr,PARnorm);

% Test data normalization

DATAts = normalize_transform(DATAts,PARnorm);

% Adjust Values for video function

DATA = normalize_transform(DATA,PARnorm);
DATAtr.Xmax = max(DATA.input,[],2);  % max value
DATAtr.Xmin = min(DATA.input,[],2);  % min value
DATAtr.Xmed = mean(DATA.input,2);    % mean value
DATAtr.Xdp = std(DATA.input,[],2);   % std value

% %%%%%%%%%%%%%% SHUFFLE TRAINING DATA %%%%%%%%%%%%%%%%%%%

I = randperm(size(DATAtr.input,2));
DATAtr.input = DATAtr.input(:,I);
DATAtr.output = DATAtr.output(:,I);
DATAtr.lbl = DATAtr.lbl(:,I);

% %%%%%%%%%%% HYPERPARAMETER OPTIMIZATION %%%%%%%%%%%%%%%%

% Using Grid Search and Cross-Validation
HP = grid_search_cv(DATAtr,HPgs,@isk2nn_train,@isk2nn_classify,GSp);

% %%%%%%%%%%%%%% CLASSIFIER'S TRAINING %%%%%%%%%%%%%%%%%%%

% Calculate model's parameters
PAR_acc{r} = isk2nn_train(DATAtr,HP);

% %%%%%%%%% CLASSIFIER'S TEST AND STATISTICS %%%%%%%%%%%%%

% Results and Statistics with training data
OUTtr = isk2nn_classify(DATAtr,PAR_acc{r});
STATS_tr_acc{r} = class_stats_1turn(DATAtr,OUTtr);

% Results and Statistics with test data
OUTts = isk2nn_classify(DATAts,PAR_acc{r});
STATS_ts_acc{r} = class_stats_1turn(DATAts,OUTts);

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

% Compare Training and Test Statistics

class_stats_ncomp(nSTATS_all,NAMES);

%% GRAPHICS - OF LAST TURN

% Get Data, Parameters, Statistics
DATAf.input = [DATAtr.input, DATAts.input];
DATAf.output = [DATAtr.output, DATAts.output];
PAR = PAR_acc{r};
STATS = STATS_ts_acc{r};

% Classifier Decision Boundaries
plot_class_boundary(DATAf,PAR,@isk2nn_classify);

% ROC Curve (one for each class)
plot_stats_roc_curve(STATS);

% Precision-Recall (one for each class)
plot_stats_precision_recall(STATS)

% See Class Boundary Video (of last turn)
% if (HP.Von == 1),
%     VID = PAR_acc{r}.VID
%     figure;
%     movie(VID)
% end

%% SAVE VARIABLES AND VIDEO

% % Save All Variables
% save(OPT.file);
% 
% % Save Class Boundary Video (of last turn)
% v = VideoWriter('video.mp4','MPEG-4'); % v = VideoWriter('video.avi');
% v.FrameRate = 1;
% open(v);
% writeVideo(v,VID);
% close(v);

%% END