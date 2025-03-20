function record = tp_mito_close(record, params, processparams)
%TP_MITO_CLOSE computes for ROIs whether there is a mito type ROI close
%
%  RECORD = TP_MITO_CLOSE(RECORD, [PARAMS])
% 
%       PARAMS is results of TPREADCONFIG(RECORD) and can be given as an
%       argument to save time
%
% 2013-2015, Alexander Heimel
%
if nargin<2
    params = tpreadconfig(record);
end

if isempty(params)
    logmsg('No image information. Cannot link ROIs');
    return
end
if nargin<3 || isempty(processparams)
    processparams = tpprocessparams(record);
end

roilist = record.ROIs.celllist;
n_rois = length(roilist);
ind_mito = strmatch('mito',{roilist.type});
ind_no_mito = setdiff(1:length(roilist),ind_mito);

r = zeros(n_rois,3);
for i = 1:n_rois
    r(i,1) = sum(roilist(i).xi)/length(roilist(i).xi); % take center
    r(i,2) = sum(roilist(i).yi)/length(roilist(i).yi); % take center
    r(i,3) = sum(roilist(i).zi)/length(roilist(i).zi); % take center
end

r = r.*repmat([params.x_step params.y_step params.z_step],size(r,1),1); 

ind_mito_present = ind_mito([roilist(ind_mito).present]==1);

for i = 1:length(record.measures) %ind_no_mito(:)'
    record.measures(i).mito_close = false;
    record.measures(i).distance2mito = inf;
    for j = ind_mito_present(:)'
        if j==i 
            continue
        end
       if roilist(j).neurite(1)==roilist(i).neurite(1)
           record.measures(i).distance2mito  = ...
               min(record.measures(i).distance2mito, norm(r(i,:)-r(j,:)) );
       end
    end
    if record.measures(i).distance2mito == inf
        record.measures(i).distance2mito = NaN;
    end
    if record.measures(i).distance2mito <=processparams.max_bouton_mito_distance_um
        record.measures(i).mito_close = true;
    end
end

% set mito close true for mito's themselves
for i = ind_mito(:)' 
%    record.measures(i).mito_close = true;
%    record.measures(i).distance2mito = 0;
% no longer setting distance2mito to zero, 2016-04-24
end


