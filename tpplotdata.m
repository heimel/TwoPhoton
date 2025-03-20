function tpplotdata( data, t, listofcells, listofcellnames, params,process_params, timeint,figname,record)
%TPPLOTDATA plot calcium cell data
%
%   TPPLOTDATA( DATA, T, LISTOFCELLS, LISTOFCELLNAMES,  )
%
%    DATA is cell MxN array containing the fluorescence signal with M recording intervals
%       and N cells
%    T is cell MxN array with timestamps
%
%  2010, Alexander Heimel
%

if nargin<9
    record = [];
end
if nargin<8
    figname = 'Data';
end

n_cells = size(data,2);


figure('Name',figname,'NumberTitle','off');

% figure positioning and size
set(gcf,'PaperPositionMode','auto');
    p=get(gcf,'position');
    p(3)=p(3)*2;
    set(gcf,'position',p);


colors={[1 0 0],[0 1 0],[0 0 1],[1 1 0],[0 1 1],[1 0 1],[0.5 0 0],[0 0.5 0],[0 0 0.5],[0.5 0.5 0],[0.5 0.5 0.5]};
%mcolors=reshape([colors{:}],length(cc),3)
% check if data is normalized
%if abs(mean(data{1}))<4 % then probably normalized
%    stack_lines = 1;
%else
%    stack_lines = 0;
%end


% curves
switch process_params.method
    case 'event_detection'
    stack_lines = 0;
        marker = '.';
        linestyle = 'none';
        ylab = 'Peak \Delta F/F';
       % for i=1:numel(data)
        %    ind = find(data{i}==0);
       %     data{i}(ind) = nan;
       % end
        n_panelrows = 2;
    case 'normalize'
    stack_lines = 1;
        marker='none';
        linestyle = '-';
        ylab = '\Delta F/F';
        n_panelrows = 1;
    case 'none'
    stack_lines = 0;
        marker='none';
        linestyle = '-';
        ylab = 'F';
        n_panelrows = 1;
end

if ~isempty(record)
    n_panelrows = n_panelrows + 1;
end

h_traces  = subplot(n_panelrows,2,1);
        
for interval = 1:size(data,1)
    for i=1:size(data,2)
        hold on;
        ind=mod(i-1,length(colors))+1;
        plot(t{interval,i}, data{interval,i} + stack_lines * (i-1) * 0.2 ,'linestyle',linestyle,'color',colors{ind},'marker',marker);
    end
end
% if length(listofcells)<10
%     legend(listofcellnames,'Location','EastOutside');
% end
ylabel(ylab); 
xlabel('Time (s)');
mark_intervals( timeint )
xlims = xlim;


% show data as color image
subplot(n_panelrows,2,2);
try % to see if equal number of samples for each cell
    imgdata = [];
    markers = [];
    marker_labels = {};
    marker_index = 1;
    for interval = 1:size(data,1);
        if isempty(t{interval,1})
            continue
        end
        intervaldata = [];
        markers(marker_index) = size(imgdata,2);
        
        marker_labels{marker_index}=round(nanmean(nanmean([t{interval,1}]))/1000);
        for c = 1:size(data,2)
            intervaldata = [intervaldata; data{interval,c}'];
        end
        imgdata = [imgdata intervaldata];
        marker_index = marker_index + 1;
    end
    imagesc(imgdata);
    set(gca,'YDir','normal')
    set(gca,'Xtick',markers);
    set(gca,'Xticklabel',marker_labels);
    ylabel('Cell');
    xlabel('Time (ks)');
    colormap jet
catch 
    delete(gca);
end





% global events
switch process_params.method
    case 'event_detection'
        participating_fraction=[];
        global_t = [];
        for interval = 1:size(data,1)
            participating_fraction = [participating_fraction; mean([data{interval,:}]>0,2)];
            global_t = [global_t;nanmean([t{interval,:}],2)];
        end
       
        if isempty(timeint)
            timeint = [-inf inf];
        end
        y = {};
        x = {};
        for i = 1:size( timeint,1 )
            log_ind = (global_t > timeint(i,1) & global_t<timeint(i,2));
           y{i} = participating_fraction(log_ind);
           x{i} = global_t(log_ind);
        end
        
        % plot fraction vs time
        subplot(n_panelrows,2,3);
        hold on
        for i=1:length(x)
         plot(x{i},y{i},'.','color',colors{i});
        end
        ylabel('Participating fraction');
        xlabel('Time (s)');
        mark_intervals( timeint )
        ylim([0 1]);

        % plot cumhistograms for each requested interval
        h=subplot(n_panelrows,2,4);
       
        graph(y,[],'style','cumul','axishandle',h,...
            'xlab','Participating fraction','ylab','Fraction',...
            'color',colors);
        bigger_linewidth(-4);
        smaller_font(14);
        ylim([0 1]);
        
    otherwise
end

if ~isempty(record)
    h_timeline = subplot(n_panelrows,2,((n_panelrows-1)*2)+1);
    plot_stimulus_timeline(record,xlims);
    p_traces = get(h_traces,'position');
    p_timeline = get(h_timeline,'position');
    p_timeline(4) = 0.1;
    p_timeline(2) = p_traces(2)-p_timeline(4);
    set(h_timeline,'position',p_timeline);
    set(h_traces,'xtick',[]);
end

return

function mark_intervals( timeint, h)
hold on;
if nargin<2
    h = gca;
end

ax = axis(h);
for i = 1:size(timeint,1)
    line( [timeint(i,1) timeint(i,1)],[ax(3) ax(4)],'color',[0 1 0]);
    line( [timeint(i,2) timeint(i,2)],[ax(3) ax(4)],'color',[1 0 0 ]);

    text( timeint(i,1), ax(3)-0.05*(ax(4)-ax(3)), ' >','HorizontalAlignment','right');
    text( timeint(i,2), ax(3)-0.05*(ax(4)-ax(3)), '< ','HorizontalAlignment','left');
    
end







