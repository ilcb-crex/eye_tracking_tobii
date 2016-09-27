function Sdat = emoz_timeanalysis_prepare(Sdat)
% Reassign fixation values at common time samples (find fixations close to
% each "perfect time" point, the same for all media and conditions)
% (fsamlp = 60 Hz)
% New added fields to the input data structure Sdat : 
%   .fix_taball : all fixations regardless answer 
%               [ Nmed x Nsubj x Ntime ]
%   .time_tab : the associated common time vector ("perfect time vector")
%               [ Ntime x 1 ]
% Before averaging fixations across media and subjects at each time sample
% we need to define an ideal time vector (the same for all the data, i.e.
% all media and subjects)
% The data values will be allocated to each ideal time sample
% Check for time point that are the closest to perfect time point
% Put NaN when no data for any given time
%____
%-CREx 20151220
% ANR RAPP C. Petrone http://www.lpl-aix.fr/~petrone/projectf.html
%-CREx-BLRI-AMU project: https://github.com/blri/eye_tracking_tobii/emoz


% Perfect time vector
fperf = 60; % Sample frequency
time_perf = 0 : 1/fperf : 6; % 12s-duration
tpinv = -1.*time_perf(2:length(time_perf));
time_perf = [tpinv(end:-1:1) time_perf].*1000; % in ms

Ntime = length(time_perf);
% Check for values closest to the perfect time sample and fill no value 
% with NaN 
emot = fieldnames(Sdat);


% For each emotion and speaker
for i = 1 : length(emot)
    cond = emot{i};
    spk = fieldnames(Sdat.(cond));
    
    for j = 1 : length(spk)   
        
        % time and isfix are cellules of dim Nmed x Nsubj
        % Empty if the subject have given an answer before the noun was
        % pronounced
        sspk = spk{j};
        falign = fieldnames(Sdat.(cond).(sspk).datalign);
        
        for ia = 1 : length(falign)
            align = falign{ia};
            Scond =  Sdat.(cond).(sspk); 
            % Structure with fields : 
            %   - subj (Ns x 1 cell)
            %   - medianames (Nmed x 1 cell)
            %   - datalign.(align) 
            %       .time (Nmed x Nsubj cell with inconsistent time samples and length)
            %   	. isfix (Nmed x Nsubj cell indicating if AOI_cor has been fixated
            %       at each time sample)

            Nsubj = length(Scond.subj);
            Nmed = length(Scond.medianames);
            
            time = Scond.datalign.(align).time; 
            fix = Scond.datalign.(align).isfix;

            fix_taball = NaN(Nmed, Nsubj, Ntime);
            % For each media
            for im = 1 : Nmed
                for k = 1 : Nsubj
                    tsu = time{im, k};
                    fixsu = fix{im, k};
                    fix_taball(im, k, :) = put_perfix(time_perf, tsu, fixsu);
                end            
            end
            Sdat.(cond).(sspk).datalign.(align).time_tab = time_perf;
            Sdat.(cond).(sspk).datalign.(align).fix_taball = fix_taball;
        end  
    end
end

% Find the fixation that fall closest to the perfect time point
function fix_perf = put_perfix(time_perf, timec, fixc)
    dt = (time_perf(2) - time_perf(1))/2;
    Np = length(time_perf);
    fix_perf = NaN(1, Np);
    for i = 1 : Np
        isp = find(timec >= time_perf(i)-dt & timec <= time_perf(i) + dt);
        if ~isempty(isp)
            if length(isp) > 1
                disp('Several time point find around perfect time sample')
                disp(['t_perf = ', num2str(time_perf(i)), ' s'])
                % Took point with minimal distance from perfect time
                [~, ibest] = min(abs(timec(isp) - time_perf(i)));
                isp = isp(ibest);
            end
            fix_perf(i) = fixc(isp);
        end
    end
            
            
