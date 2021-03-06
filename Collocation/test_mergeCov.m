% test_mergeCov

clc


len = length(names_all);
[Cov2] = megreCov(CovVenuSNX, names_all);

if size(Cov2,1)/3 == 198
    disp('ok')
end
    
CovENU = Cov2;

%% test extractCovariance
clc
% CovENUSel = extractCovariance(CovENU, [2:4], [1 2])
CovENUSelected = extractCovariance(CovENU, Selected, [1 2 3],'no split');

%%
% sel = sel(1:3);
CovENUSel = extractCovariance(CovENU, sel, [2 1], 'split');
[V_pred_point2] = solve_WLSC(iLat, iLong, lat(sel), long(sel), Vn_res(sel)*1000, Ve_res(sel)*1000,CovENUSel,'exp1', '-v', 'bias', 'tail 0', 'no corr');   % WLSC 
            

%%
clear LatGrid LongGrid V_pred V_pred* V_def1 V_def2 Error V_SigPred rmsFit
clc
tic
range = 1:length(lat);
Max_Dist = 150; % km
lim = 10;
p = 0;
step = 0.25;
for iLong =  -4:1:16
    for iLat =  44:1:50
        arc = greatcircleArc(iLat, iLong, lat, long) * 111 ; % km
        sel = range(arc < Max_Dist);    
        sel = intersect(sel, Selected);
        if length(sel) < lim % add more stations
            add = sort(arc);
            add = add(1:lim); % ad 2 sites, ast is prop already included
            iadd = ismember(arc,add);
            inew = range(iadd);
            sel = unique(sort([sel, inew]));
            sel = intersect(sel, Selected);
        end
        if length(sel) > 1 % do LSC !!! 
            p = p + 1; % point Number
%             [CovSet] = getSelectCOV(CovVenuSNX, sel);

            [V_pred_point1] = solve_LSC(iLat, iLong, lat(sel), long(sel), Vn_res(sel)*1000, Ve_res(sel)*1000,'exp1', '-v', 'bias', 'tail 0', 'no corr');   % LSC 
            CovENUSel = extractCovariance(CovENU, sel, [2 1], 'split');
            [V_pred_point2, rmsFitting, V_noise_pred] = solve_WLSC(iLat, iLong, lat(sel), long(sel), Vn_res(sel)*1000, Ve_res(sel)*1000,CovENUSel,'exp1', '-v', 'bias', 'tail 0', 'no corr');   % WLSC 
            V_def1(p,:) = V_pred_point1'/1000;
            V_def2(p,:) = V_pred_point2'/1000;
            rmsFit(p,:) = rmsFitting/1000; % [mm/yr]
            V_SigPred(p,:) = V_noise_pred;
            LatGrid(p,1)  = iLat;
            LongGrid(p,1) = iLong;
        end
    end
end
t2 = toc

%%
% Error = (V_def1 - V_def2)*10;
clc
%
s = 250;  % [mm/yr]
close all
clr = lines(8);
fig7 = figure(7);
hold on
axis equal
xlim([-6 19])
ylim([41 53])
% etopo_fig = showETOPO(ETOPO_Alps.Etopo_Europe, ETOPO_Alps.refvec_Etopo);
plot(Orogen_Alp(:,1),Orogen_Alp(:,2),'--m')
plot(Adriatics(:,1),Adriatics(:,2) , '--k')
quiver(long(Selected), lat(Selected), Ve_res(Selected)*s, Vn_res(Selected)*s,  0, 'r', 'lineWidth',1)
quiver(long(iOutliers),lat(iOutliers),Ve_res(iOutliers)*s,Vn_res(iOutliers)*s, 0, 'Color',[.5 .5 .5], 'lineWidth',1)
% quiver(LongGrid,      LatGrid,      V_def1(:,2)*s,   V_def1(:,1)*s,    0, 'b', 'lineWidth',1)
% quiver(LongGrid,      LatGrid,      V_def2(:,2)*s,   V_def2(:,1)*s,    0, 'b', 'lineWidth',1)
% quiver(LongGrid,      LatGrid,      Error(:,2)*s,    Error(:,1)*s,     0, 'g', 'lineWidth',1)

plotErrorElipses('Cov', CovENU,                          long,     lat,     Ve_res,      Vn_res,      s, 0.95, 'r')
plotErrorElipses('Sig', [V_SigPred(:,2),V_SigPred(:,1)], LongGrid, LatGrid, V_def2(:,2), V_def2(:,1), s, 0.95, 'b')
plotErrorElipses('Sig', [rmsFit(:,2),rmsFit(:,1)]*1000,  LongGrid, LatGrid, V_def2(:,2), V_def2(:,1), s, 0.95, 'm')


