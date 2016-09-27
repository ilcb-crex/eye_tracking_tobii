function Sta = emoz_timeanalysis_compute(Sdat, thrnorm)
% Compute the mean proportion of fixation and the confidence intervals
% for each condition and each realignment version depending on the used reference time 
% 
%____
%-CREx 20151220
% ANR RAPP C. Petrone http://www.lpl-aix.fr/~petrone/projectf.html
%-CREx-BLRI-AMU project: https://github.com/blri/eye_tracking_tobii/emoz


%  In Matlab, log(x), : logarithme néperien de x

cortyp = {'cor_answer', 'incor_answer'};
normtyp = {'all_media', 'good_media', 'bad_media'};
rttyp = {'all_rt', 'before_end_rt', 'after_end_rt'};

% Confidence interval parameters
pci = 0.95;
alpha = 1 - pci;

% To be 95% certain that the true population mean falls within the range 
% CI = [xbar - ec ;
%     xbar + ec];
               
emot = fieldnames(Sdat);

Sta = Sdat;
% For each emotion and speaker
for i = 1 : length(emot)
    emo = emot{i};
    fspk = fieldnames(Sdat.(emo));
    
    for j = 1 : length(fspk)   
        spk = fspk{j};
        falign = fieldnames(Sdat.(emo).(spk).datalign);
        
        for ia = 1 : length(falign)
            align =  falign{ia};
        
            Scond =  Sdat.(emo).(spk);
            Sdata = Scond.datalign.(align);
            
            % All fixations regardless answer
            fixall = Sdata.fix_taball;
            %--> Nmed x Nsubj x Ntime
            
            Nt = length(Sdata.time_tab);
            Nmed = length(fixall(:,1, 1));
            Nsubj = length(fixall(1,:,1));
            
            ccor = Scond.corclick;
            
            norm = Scond.norming;
            
            tclick = Sdata.tclick; % Nmed x Nsubj (=0 if no recording answer)
            tend = Sdata.tcrit.tend;
            
            %  [1] Separate between "correct" answers and "incorrect" answers
            % Corresponding indices
            %--> Nmed x Nsubj
            isep_cor = {ccor==1 ; ccor==0}; 
            
            % [2] Separate media according to norming thresholds
            %--> Nmed x 1
            isep_norm = {  ones(length(norm),1)==1
                            norm >= thrnorm.(emo)(1) & norm <= thrnorm.(emo)(2)
                            norm < thrnorm.(emo)(1) | norm > thrnorm.(emo)(2)
                            };
                        
            % [3] Separate according to reaction time
            %--> Nmed x Nsubj
            tsend = repmat(tend, 1, Nsubj);
            isep_rt = { tclick >= 0
                        tclick > 0 & tclick <= tsend 
                        tclick > tsend
                        };
                
            avg = [];
            % We work with logical indexation
            for ic = 1 : length(cortyp)
                scor = cortyp{ic};
                
                for in = 1 : length(normtyp)
                    snorm = normtyp{in};
                    
                    for ir = 1 : length(rttyp)
                        srt = rttyp{ir};
                        
                        % iok depend only on media and subject answer 
                        %--> Nmed x Nsubj % All media and subjects we keep
                        iok = isep_cor{ic} & repmat(isep_norm{in}, 1, Nsubj) & isep_rt{ir};
                        
                        %--> Nmed x Nsubj x Ntime
                        ifix = repmat(iok, [1 1 Nt]);  % 1 = data to keep, 0 : data to remove
                        
                       
                        %--> If ifix==0, put NaN value to remove this data
                        fixok = fixall;
                        fixok(ifix==0) = NaN;
                                               
                        % Compute proportion and logit at each time sample     
                        isone = isnan(fixok)==0 & fixok==ones(size(fixok));
                        iszer = isnan(fixok)==0 & fixok==zeros(size(fixok));  
                        
                        % Number of fixation per media and time sample
                        nones_med = squeeze(sum(isone, 2));    
                        nzeros_med = squeeze(sum(iszer, 2));
                        % OK but the total number of sample to compute the
                        % mean per time point isn't Nmed x Nsubj at all
                        % But the number of points that wasn't NaN
                        % Number of subject available per media and time
                        % points for computing proportions
                        Nsp = squeeze(sum(isnan(fixok)==0, 2));
                        
                        % Proportion per media (only when Nsp > 0)
                        prop = NaN(Nmed, Nt);
                        prop(Nsp > 0) = nones_med(Nsp > 0) ./ Nsp(Nsp > 0);
                        
                        % Logit per media 
                        % (only when nzeros_med > 0 et nones_med > 0) !
                        % => ok only if a lot of data are available
                        logit = NaN(Nmed, Nt);
                        Nz = nzeros_med > 0 & nones_med > 0;
                        logit(Nz) = log(nones_med(Nz)./nzeros_med(Nz));           
                        
                        
                        % At the beginning, idea to compute the CI of the proportion
                        % calculation 
                        % ec(Nmp > 0 ) = t_ci.*sqrt(P.*(ones(length(P),1) - P)./Nsp(Nsp>0));
                        % But what to do after ? How to consider these CI
                        % when computing the mean proportions ?
 
                        % Add only a confidence interval depending on the number
                        % of media use to compute the mean proportion
                        % and the associated std
                        
                        propmean = nanmean(prop);
                        propec = compute_ci(prop, alpha);
                        
                        logitmean = nanmean(logit);
                        logitec = compute_ci(logit, alpha);
                        
                        avg.(scor).(snorm).(srt).prop = propmean;
                        avg.(scor).(snorm).(srt).ecprop = propec;                        
                        avg.(scor).(snorm).(srt).logit = logitmean;
                        avg.(scor).(snorm).(srt).eclogit = logitec;
                        
                    end
                end
            end
            Sta.(emo).(spk).datalign.(align).avg = avg;
        end
    end
end

%-- Compute the confidence interval
function ec = compute_ci(val, alpha)
% Number of non-nan data samples
Ns = sum(isnan(val)==0);

% Critical coefficient
t_ci = tinv(1-alpha/2, Ns -1);

% Standart deviation
sigma = std(val);

% CI with alpha value inside nanmean(val)-ec and nanmean(val)+ec 
ec = t_ci.* sigma./sqrt(Ns);