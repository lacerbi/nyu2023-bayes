%% Bayesian model fitting made easy with Variational Bayesian Monte Carlo
% Tutorial for the Center for Neural Science, NYU - Jan 2023
% by Luigi Acerbi (2023)

% To run this tutorial, run one section at a time ("Run Section" command).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Tutorial on Bayesian inference for model fitting using the VBMC package.
% In this tutorial, we will learn how to estimate model parameters (aka fit 
% our models) in a fully Bayesian manner, which will yield a posterior 
% distribution as opposed to a single point estimate.

clear;
% Add utility folders to MATLAB path
baseFolder = fileparts(which('nyu2023_bayes_tutorial_matlab.m'));
addpath([baseFolder,filesep(),'utils']);

% During this tutorial, we are going to use data from the International 
% Brain Laboratory (IBL; https://www.internationalbrainlab.com/) publicly 
% released behavioral mouse dataset, from exemplar mouse `KS014`. 
% See The IBL et al. (2021) https://elifesciences.org/articles/63711 for 
% more information about the task and datasets. 
%
% These data can also be inspected via the IBL DataJoint public interface: 
% https://data.internationalbrainlab.org/mouse/18a54f60-534b-4ed5-8bda-b434079b8ab8
%
% For convenience, the data of all behavioral sessions from examplar mouse 
% `KS014` have been already downloaded in the `data` folder and 
% preprocessed into a `.csv` file. In this tutorial, we will only work with 
% data from the training sessions (`KS014_train.csv`).

filename = './data/KS014_train.csv';
data = csvread(filename,1);
% We add a last column to represent "signed contrasts"
data = [data, data(:,4).*data(:,5)];

% The columns of 'data' are now (each row is a trial):
% 1. trial_num
% 2. session_num
% 3. stim_probability   (unused in training sessions)
% 4. contrast           (from 0 to 100)
% 5. position           (-1 left, 1 right)
% 6. response_choice    (-1 left, 1 right)
% 7. trial_correct      (1 yes, 0 no)
% 8. reaction_time      (seconds)
% 9. signed contrasts   (from -100 to 100)

fprintf('Loaded file %s.\n', filename);
fprintf('Total # of trials: %d\n', size(data,1));
fprintf('Sessions: %s\n', mat2str(unique(data(:,2))'));
data(1:5,:)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% I. Inspecting the data

% The first thing to do with any dataset is to get familiar with it by 
% running simple visualizations. Just plot stuff!
% Here we plot data from individual sessions. What can we see from here?

figure(1);
subplot(1,2,1);
plot_psychometric_data(data, 2);
subplot(1,2,2);
plot_psychometric_data(data, 15);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% II. Psychometric function model

% Now let's try plotting the psychometric function model for different 
% values of the parameters (use both the symmetric and asymmetric 
% psychometric function).
% The parameters are: [bias, slope/noise, lapse rate, lapse bias]
% Try and match the data from one of the sessions.

theta0 = [-20,40,0.2,0.5]; % Arbitrary parameter values - try different ones
session_num = 15;

close all;
figure(1);
plot_psychometric_data(data,session_num);
hold on;

stim = linspace(-100,100,201);      % Create stimulus grid for plotting    
p_right = psychofun(theta0,stim);   % Compute psychometric function values
plot(stim,p_right,'LineWidth',1,'Color','k','DisplayName','model');

legend('Location','NorthWest','Box','off','FontSize',12);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% III. Psychometric function log-likelihood

% The psychofun_loglike.m file defines the log likelihood function of the 
% psychometric function model for a given dataset and model parameter 
% vector, log p(data|theta).

% Now try to get the best fit for this session, as we did before, but by 
% finding better and better values of the log-likelihood. 
% Higher values of the log-likelihood are better.

session_num = 14; % Let's use a different session
theta0 = [-20,40,0.2,0.5];
session_data = data(data(:,2) == session_num,:);

ll = psychofun_loglike(theta0,session_data);
% print('Log-likelihood value: ' + "{:.3f}".format(ll))

figure(1); hold off;
plot_psychometric_data(data,session_num);
hold on;
p_right = psychofun(theta0,stim);   % Compute psychometric function values
plot(stim,p_right,'LineWidth',1,'Color','k','DisplayName','model');
legend('Location','NorthWest','Box','off','FontSize',12);
text(-100,0.7,['Log-likelihood: ' num2str(ll)],'FontSize',12);

% Note that we could fit the model to the data by finding the single "best" 
% parameter vector that maximizes the log-likelihood, a common technique 
% known as *maximum-likelihood estimation*. However, we are going to go full 
% Bayesian!

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% IV. Bayesian inference "by hand"

% As a first exercise, we fix the parameters of our psychometric function 
% model except for one, and calculate a (one-dimensional) posterior 
% distribution for the free parameter, given the other parameters. 
%
% Here we take sigma as the free parameter and fix the others.
% Our goal then is to infer: p(sigma|mu_star,lambda_star,gamma_star,data).

% Fixed parameter values (here ~ maximum-likelihood values)
mu_star = -10;          % bias
lambda_star = 0.26;     % lapse_rate
gamma_star = 0.54;      % lapse_bias

% We define hard lower/upper bounds for sigma
lb = 1; ub = 100;

% Define a grid for sigma
sigma_range = linspace(0, ub + 1, 1001);
dsigma = sigma_range(2) - sigma_range(1);   % Grid spacing

% Define the prior over sigma as a uniform box between lb and ub (0 outside)
prior_pdf = 1/(ub - lb) * ((sigma_range >= lb) & (sigma_range <= ub));

% Just to see what happens: change the prior to a (truncated) Gaussian
%prior_pdf = normpdf(sigma_range,5,6) .* ((sigma_range >= lb) & (sigma_range <= ub));
%prior_pdf = prior_pdf ./ (sum(prior_pdf)*dsigma);   % Normalize

% Plot prior pdf
figure;
subplot(1,2,1);
plot(sigma_range,prior_pdf,'-k','LineWidth',1);
xlabel('\sigma')
ylabel('p(\sigma)');
title('Prior pdf');
set(gca,'TickDir','out');
box off;
set(gcf,'Color','w');
xlim([0,110]);
ylim([0,0.15]);

pause

% Define the log-likelihood function (just like in the optimization tutorial)
session_num = 12;   % Pick session data
session_data = data(data(:,2) == session_num,:);
loglike = @(sigma_) psychofun_loglike([mu_star,sigma_,lambda_star,gamma_star],session_data);

% Now we directly compute the log posterior using Bayes rule (in log space)

% Define a grid to store the log posterior
logpost = zeros(1, numel(sigma_range));

% Compute log of unnormalized posterior, log (likelihood * prior), for each
% value in the grid
for i = 1:numel(sigma_range)
    sigma = sigma_range(i);
    logpost(i) = loglike(sigma) + log(prior_pdf(i));    % Unnormalized
end

% Normalize log posterior
post = exp(logpost - max(logpost)); % Subtract maximum for numerical stability
post = post ./ sum(post * dsigma);  % This is a density

fprintf('Posterior integral: %.3f.\n', sum(post * dsigma)); % Integrates to 1

% Plot posterior pdf
subplot(1,2,2);
plot(sigma_range,post,'-k','LineWidth',1);
xlabel('\sigma')
ylabel('p(\sigma | \mu_*, \lambda_*, \gamma_*, data)');
title('Posterior pdf');
set(gca,'TickDir','out');
box off;
set(gcf,'Color','w');
xlim([0,110]);
ylim([0,0.15]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% V. A closer look at priors

close all;

% We recommend to define "hard" lower and upper bounds for the parameters. 
% We also define "plausible" bounds which we generally associate with a 
% higher prior probability of the parameters.

% Define hard parameter bounds
lb = [-100,1,0,0];
ub = [100,100,1,1];

% Define plausible range
plb = [-25,5,0.05,0.2];
pub = [25,25,0.40,0.8];

% Number of variables
D = numel(lb);

parameter_names{1} = 'bias (\mu)';
parameter_names{2} = 'threshold (\sigma)';
parameter_names{3} = 'lapse rate (\lambda)';
parameter_names{4} = 'lapse bias (\gamma)';

% We need to define a prior for the parameters. This choice is up to you!
% A common choice is to define the prior separately for each parameter.
% Below, we plot the prior separtely for each dimension.

% A simple choice is a non-informative uniformly flat prior between the 
% hard bounds (implemented by `munifboxpdf`).

figure(1);
for d = 1:D
    x = linspace(lb(d),ub(d),1e3)';
    subplot(2,ceil(D/2),d);
    plot(x, munifboxpdf(x,lb(d),ub(d)), 'k-', 'LineWidth', 1);
    set(gca,'TickDir','out');
    xlabel(parameter_names{d})
    ylabel('prior pdf')
    box off;
end
set(gcf,'Color','w');
pause;

% Alternatively, for each parameter we define the prior to be flat within 
% the plausible range, and then falls to zero towards the hard bounds. This
% is a trapezoidal or "tent" prior, implemented by the provided `mtrapezpdf` 
% function.

figure(2);
for d = 1:D
    x = linspace(lb(d),ub(d),1e3)';
    subplot(2,ceil(D/2),d);
    plot(x, mtrapezpdf(x,lb(d),plb(d),pub(d),ub(d)), 'k-', 'LineWidth', 1);
    set(gca,'TickDir','out');
    xlabel(parameter_names{d})
    ylabel('prior pdf')
    box off;
end
set(gcf,'Color','w');
pause;

% As above, but we impose smooth transitions (using splines), which are 
% both nicer and better behaved numerically (no sharp edges).
% The provided `msplinetrapezpdf` function implements this kind of prior.

figure(3);
for d = 1:D
    x = linspace(lb(d),ub(d),1e3)';
    subplot(2,ceil(D/2),d);
    plot(x, msplinetrapezpdf(x,lb(d),plb(d),pub(d),ub(d)), 'k-', 'LineWidth', 1);
    set(gca,'TickDir','out');
    xlabel(parameter_names{d})
    ylabel('prior pdf')
    box off;
end
set(gcf,'Color','w');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% VI. Running Bayesian inference

% Pick session data
session_num = 14;
session_data = data(data(:,2) == session_num,:);

% Define the smoothed trapezoidal prior
prior_fun = @(theta_) msplinetrapezpdf(theta_,lb,plb,pub,ub);

% Alternatively, this implements a box-uniform prior
% prior_fun = @(theta_) munifboxpdf(theta_,lb,ub);

% Define objective function: log-joint (log likelihood + log prior)
fun = @(theta_) psychofun_loglike(theta_,session_data) + log(prior_fun(theta_));

% Generate random starting point inside the plausible box
theta0 = rand(1,D).*(pub-plb) + plb;

% Get the maximum-a-posteriori (MAP) estimate using BADS

% Check that BADS is installed (and on the MATLAB path)
test = which('bads');
if ~isempty(test)
    options = bads('defaults');
    options.Display = 'iter';
    theta_MAP = bads(@(x) -fun(x),theta0,lb,ub,plb,pub,[],options);
else
    % BADS not installed, use fmincon
    options.Display = 'iter';
    theta_MAP = fmincon(@(x) -fun(x),theta0,[],[],[],[],lb,ub,[],options);
end

% Run inference using Variational Bayesian Monte Carlo (VBMC):
% https://github.com/lacerbi/vbmc

% Check that VBMC is installed (and on the MATLAB path)
test = which('vbmc');
if isempty(test)
    error(['To run this part of the tutorial, you need to install ' ...
        '<a href = "https://github.com/lacerbi/vbmc">Variational Bayesian Monte Carlo (VBMC)</a>.']);
end

% We start the algorithm from the MAP (not necessary but it helps)
options = vbmc('defaults');
options.Display = 'iter';
options.Plot = 'on';
[vp,elbo,elbo_sd,exitflag,output] = vbmc(fun,theta_MAP,lb,ub,plb,pub,options);

% VBMC returns:
% - vp: the (approximate) posterior distribution
% - elbo: the lower bound to the log marginal likelihood (log evidence),
%   can be used as a principled metric for model comparison (similar to AIC, BIC)
% - elbo_sd: standard deviation of the estimate of the elbo
% - exitflag: a success flag
% - output: a struct with information about the run

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% VII. Posterior usages: visualization, uncertainty, prediction

close all;

% First, let's visualize the posterior - sampling from the variational
% posterior is very easy (the posterior is a mixture of Gaussians)
Nsamples = 1e5;                     % How many samples
thetas = vbmc_rnd(vp,Nsamples);     % Sample from the variational posterior
cornerplot(thetas,parameter_names); % Plot samples

pause

% We can use samples from the posterior to calculate/report uncertainty
for d = 1:D
    fprintf('%s: Mean: %.2f, Median %.2f, Std %.2f, 95%% CI [%.2f, %.2f]\n', ...
        parameter_names{d}, mean(thetas(:,d)), median(thetas(:,d)), std(thetas(:,d)), ...
        quantile(thetas(:,d), 0.025), quantile(thetas(:,d), 0.975));
end

% We could also look at other summary statistics of the posterior, such as
% correlations between parameters, etc.
    
pause

% Finally, we plot posterior predictions (the "Bayesian fit"), also known
% as "posterior predictive check" (we check that our fit matches the data!)

% Plot data first
figure(2);
plot_psychometric_data(data,session_num);

% Compute psychometric function values for each sample
stim = linspace(-100,100,201);
p_right = zeros(Nsamples,201); 
for i = 1:Nsamples; p_right(i,:) = psychofun(thetas(i,:),stim); end
median_pred = quantile(p_right,0.5,1);  % Median prediction
bottom_pred = quantile(p_right,0.025,1);  % Bottom 2.5% prediction
top_pred = quantile(p_right,0.975,1);     % Top 97.5% prediction

% Plot median and 95% CI (as shaded area) of the posterior prediction
hold on;
patch([stim,fliplr(stim)],[bottom_pred,fliplr(top_pred)],'k','EdgeColor','none','FaceAlpha',0.2);
plot(stim,median_pred,'LineWidth',1,'Color','k','DisplayName','model');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% For further information on VBMC and more advanced example usages, check
% out the advanced examples and FAQ: https://github.com/acerbilab/vbmc/wiki

% Check out our group GitHub page for more information on our software:
% https://github.com/acerbilab