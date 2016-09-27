function emoz_timeanalysis_paper_fig(Spatchw, figopt)
% Figures of composite curve of mean proportion of fixation
%
%____
%-CREx 20151220
% ANR RAPP C. Petrone http://www.lpl-aix.fr/~petrone/projectf.html
%-CREx-BLRI-AMU project: https://github.com/blri/eye_tracking_tobii/emoz

if ~isfield(figopt, 'savepath')
    figopt.savepath = pwd;
end
if ~isfield(figopt, 'xlimits')
    figopt.xlimits = [];
end
    
xlimits = figopt.xlimits;
supcond = figopt.supcond;
% supcond = {'neutral', 'incredulity'};
Ns = length(supcond(:,1));

figpath = make_dir(fullfile(figopt.savepath, 'PatchW_prop_fig'), 1);

% Figures of all data types
for i = 1 : Ns
    scond = strjoin(supcond(i,:),'_');
    fspk = fieldnames(Spatchw.(supcond{i,1}));
    for j = 1 : length(fspk)
        spk = fspk{j};
        figpspk = make_dir([figpath, filesep, spk], 0);
        
        figpsup = make_dir([figpspk, filesep, scond], 0);
      
        
        Sres = cell(2,1);
        Sres{1} = Spatchw.(supcond{i,1}).(spk);
        Sres{2} = Spatchw.(supcond{i,2}).(spk);

        Sprop = Sres{1}.prop;
        fcor = fieldnames(Sprop);
        
        if strcmp(spk, 'woman')
            tit = '(a) Female speaker';
        else
            tit = '(b) Male speaker';
        end

        for ic = 1 : 1 % length(fcor) - cor_answer
            scor = fcor{ic};
            fmed = fieldnames(Sprop.(scor));

            for im = 1 : length(fmed)
                smed = fmed{im};

%                 if strcmp(smed, 'bad_media')
%                     addt = '(only not clearly differentiated stimuli at the rating task (scores > 1.5 and < 4.5)'; 
%                 elseif strcmp(smed, 'good_media')
%                     addt = '(only well differienciated stimuli at the rating task (scores < 1.5 and > 4.5)';
%                 else
%                     addt = '(all stimuli regardless of the rating task results)';
%                 end
                
                frt = fieldnames(Sprop.(scor).(smed));

                for ir = length(frt) : length(frt) % 1 : length(frt) ONLY after_end_rt
                    srt = frt{ir};

                    strtyp = [scor,'-', smed, '-', srt];
 
                    Sres{1}.avg = Sres{1}.prop.(scor).(smed).(srt);
                    Sres{2}.avg = Sres{2}.prop.(scor).(smed).(srt);

                    if plot_prop(Sres, tit, supcond(i,:), xlimits)

                        strtyp(strtyp=='-') = '_';
                        namfig = ['prop_patchw_', spk, '_', scond,'_', strtyp];
                        
                        disp('Move legend if necessary... Press enter to keep all figures')
                        pause % place legend to good position
                        
                        export_fig([figpsup, filesep, namfig,'.png'], '-m2', '-zbuffer')                     
                        close
                    end
                end
            end
        end  
    end
end

function ok = plot_prop(Savg, tit, scond, xlimits)
ok = 1;
avg = {Savg{1}.avg ; Savg{2}.avg};

% Check if enough data to have a relevant plot

if ( sum(isnan(avg{1})==0)/length(avg{1}) < 0.4 ) ||...
        ( sum(isnan(avg{2})==0)/length(avg{2}) < 0.4 )
    ok = 0;
else

    time = {Savg{1}.time ; Savg{2}.time};
    
    % Color of the 2 avg curves
    col = color_group(2);
    
    % Time marker colors
    colmark = [ 0.039   0.75    0.039   % t_noun
                1.00    0.20    0.40    % t_verb
                0.00    0.69    1.00  % t_end_sound
                1.00    0.65 	0.00]; % t_click
            
    % xlimits and ylimits
    if isempty(xlimits)
        xlf = [min(min(time{1}), min(time{2})) max(max(time{1}), max(time{2}))];
        xlf(2) = xlf(2) + 100;
    else
        xlf = xlimits;
    end
    
    ylf = [0 1];
         
    figure
    set(gcf, 'visible', 'on', 'units', 'centimeters', 'position', [5 5 19.2 10])
    set(gca, 'position',  [0.1077 0.1349 0.8511 0.7381])
    hold on
    
    ph = zeros(3,1);
    ph(1) = plot(time{1}, avg{1});
    ph(2) = plot(time{2}, avg{2});
    ph(3) = plot(time{2}, avg{2});
    % set(ph, 'linewidth', 1.2);
    set(ph(1), 'color', col(1,:), 'linewidth', 1.1)
    set(ph(2), 'color', col(2,:), 'linewidth', 0.5)
    set(ph(3), 'color', col(2,:), 'linestyle', '--', 'linewidth', 1.8)

    xlim(xlf)    
    ylim(ylf)
        
   % tleg = {'t_{beg}'; 't_{noun}' ; 't_{verb}'; 't_{object}';'t_{click}'};
    
    tleg = {'t_{beg}'; 't\_end\_Subject' ; 't\_end\_Verb'; 't\_end\_Object';'t\_click'};
    % TODO : to add to the results structure as tcrit_label field !!
    % when computing Spatchw !
    
    % Add mean time of interest
    for ir = 1 : 2

        tcrit = Savg{ir}.tcrit_mean(2:end-1);
        ycrit = spline(time{ir}, avg{ir}, tcrit);
        
        % Add mean reaction time
        tclick = Savg{ir}.tcrit_mean(end);
        
        if isnan(avg{ir}(find(time{ir}>= tclick, 1, 'first')))
            yclick = 0.5;
        else           
            yclick = spline(time{ir}, avg{ir}, tclick);
        end
        tmark = [tcrit; tclick];
        ymark = [ycrit; yclick];
        Nm = length(tmark);
        hmark = zeros(Nm, 1);
        for im = 1 : length(tmark)
            hmark(im) = plot(tmark(im), ymark(im),'o','markersize',8);
            set(hmark(im), 'markerfaceColor', colmark(im, :), 'markeredgeColor', 'none');
        end
        hedge = plot(tmark, ymark,'o', 'markersize',8, 'linewidth', 1);
        set(hedge, 'markeredgeColor', col(ir,:), 'markerfaceColor', 'none'); 
    end

    % Change ytick in "%" 
    ytck = 0 : 0.1 : 1;
    set(gca, 'ytick', ytck', 'yticklabel', num2str(ytck'*100))
    
    % Change xtick with 200 ms-step
    set(gca, 'xtick', 0 : 200 : xlf(end))
    
    set(gca, 'fontsize', 11)
    
    % Add landmark lines 
    line(xlf, [0.50 0.50], 'color', [0.3 0.3 0.3])
    line([0 0], ylf, 'color', [0.3 0.3 0.3])
   
    box on
    grid on
    
    % Add legend
    hleg = [ph([1 3]); hmark];
    sleg = [scond , tleg(2:end)']; 
    lg = legend(hleg, sleg, 'location', 'southeast');
    
    % Change line property for the 2nd line
%     hline = findobj('tag', sleg{2});
%     set(hline, 'linewidth', 1.5
    set(lg, 'fontsize', 11, 'selected', 'on') 
    % Selected to on to change manually the location if needed
    % (problem with the eps saving format - better rendering as png file ;
    % so, no post-processing on Inkscape possible to move the legend
    % location if needed)
                          
    xlabel('Time from t_{ beg} (ms)', 'fontsize', 12)
    ylabel('Mean proportion in the consistent AOI (%)', 'fontsize', 11)
    
    % Add title
    annotation(gcf,'textbox', [0.1028 0.9021 0.8472 0.0741],...
        'string', tit, 'interpreter','none','FontSize',12,...
        'fontweight', 'bold', 'LineStyle','none',...
        'HorizontalAlignment','left', 'FitBoxToText','off'); 
   
end

    