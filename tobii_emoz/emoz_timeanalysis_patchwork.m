function Spatchw = emoz_timeanalysis_patchwork(Sta)
% Compute the mean critical times and extract the realigned mean proportions
% to defined the composite curve of mean proportions
% for each realigned version of fixation
% data. Critical times used for the realignment are:
% prop are arranged in a structure with embedded fields :
% prop. CORRECT_OR_NOT(1) . MEDIA_SELECTION(2) . RT_SELECTION(3)
% Fieldnames :
% (1) cor_answer or incor_answer
% (2) all_media ; good_media or bad_media
% (3) all_rt ; before_end_rt or after_end_rt
% exemple prop.cor_answer.all_media.all_rt
%____
%-CREx 20151220
% ANR RAPP C. Petrone http://www.lpl-aix.fr/~petrone/projectf.html
%-CREx-BLRI-AMU project: https://github.com/blri/eye_tracking_tobii/emoz

femo = fieldnames(Sta);
Ne = length(femo);

% This order is important for the calculation of mean critical times
falign = {'tbeg', 'tnoun', 'tverb', 'tend', 'tclick'};
Nal = length(falign);

tlabel = {'t_beg'; 't_noun'; 't_verb'; 't_end'; 't_click'};

Spatchw = [];

for i = 1 : Ne
    emo = femo{i};
    fspk = fieldnames(Sta.(emo));
    
    for j = 1 : length(fspk)
        spk = fspk{j};
        
        % Compute each mean critical time across media per alignement
        Salig = Sta.(emo).(spk).datalign;
        
        tmean = zeros(5, 1);
        for ia = 1 : Nal-2
            tcr = Salig.(falign{ia}).tcrit;
            tmean(ia+1) = mean(tcr.(falign{ia+1}));
        end
        
        % Special case for tclick mean time
        % (considering only good answers)
        ia = ia+1;
        corc = Sta.(emo).(spk).corclick;
        tmean(ia+1) = mean(Salig.(falign{ia}).(falign{ia+1})(corc==1));

        % Mean critical times for patchwork representation
        tcrit_mean = cumsum(tmean);
        % Duration of each patchwork portions
        durcut = tmean(2:end); 
        
        % Extract proportions for the patchwork
        % Start
        time = Salig.tbeg.time_tab;
        timep = time(time >= 0);
        
        propp = cell(Nal-1, 1);
        ecp = cell(Nal-1, 1);

        for k = 1 : Nal-1
            sal = falign{k};
            Scond = Salig.(sal);
            % Store all structures in cell before concatenation
            [propp{k}, ecp{k}] = cut_prop(Scond, [0 durcut(k)]);
        end
        
        [prop, ecprop, ptime] = concat_prop(propp, ecp, timep);
        
        Spatchw.(emo).(spk).time = ptime; 
        Spatchw.(emo).(spk).tcrit_mean = tcrit_mean;
        Spatchw.(emo).(spk).tcrit_label = tlabel;
        Spatchw.(emo).(spk).prop = prop;
        Spatchw.(emo).(spk).ecprop = ecprop;
    end
end


function [propcut, ecut] = cut_prop(Scond, tint)

    time = Scond.time_tab;
    Savg = Scond.avg;

    propcut = [];
    ecut = [];
    fcor = fieldnames(Savg);
    for ic = 1 : length(fcor)
        scor = fcor{ic};
        fmed = fieldnames(Savg.(scor));
        for im = 1 : length(fmed)
            smed = fmed{im};
            frt = fieldnames(Savg.(scor).(smed));
            for ir = 1 : length(frt)
                srt = frt{ir};
                prop = Savg.(scor).(smed).(srt).prop;
                ecprop = Savg.(scor).(smed).(srt).ecprop;

                ipart = find(time >= tint(1) & time <= tint(2));

                propcut.(scor).(smed).(srt) = prop(ipart);
                ecut.(scor).(smed).(srt) = ecprop(ipart);
            end
        end
    end
            
% Ugly function to concatenante all previously cut proportions
function [prop, ec, ptime] = concat_prop(propp, ecp, timep)
    Np = length(propp);
    Sini = propp{1};
    fcor = fieldnames(Sini);
    prop = Sini;
    ec = ecp{1};
    
    for ic = 1 : length(fcor)
        scor = fcor{ic};
        fmed = fieldnames(Sini.(scor));
        
        for im = 1 : length(fmed)
            smed = fmed{im};
            
            frt = fieldnames(Sini.(scor).(smed));
            
            for ir = 1 : length(frt)
                srt = frt{ir};
                prc = [];
                ecc = [];
                for k = 1 : Np
                    prc = [prc propp{k}.(scor).(smed).(srt)];  %#ok
                    ecc = [ecc ecp{k}.(scor).(smed).(srt)];    %#ok
                end
                prop.(scor).(smed).(srt) = prc;
                ec.(scor).(smed).(srt) = ecc;
                
            end
        end
    end
    ptime = timep(1 : length(prc));    