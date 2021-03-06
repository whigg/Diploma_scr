% test_LSC

close all
% clear all
clc

%%
clc
clear LongGrid_2 LatGrid_2 V_pred1 V_pred2 V_pred3
tic
range = 1:length(lat);
Max_Dist = 150;
lim = 10;
p = 0;
for iLong = 3.5 % -6:1:18
    for iLat =  46.5 %  42:1:49
        arc = distance(iLat, iLong,lat, long) * 111 ; % km
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
        if ~(isempty(sel))
            p = p + 1;
            V_pred1(p,:) = solve_LSC(iLat, iLong, lat(sel), long(sel), Vn_res(sel)*1000, Ve_res(sel)*1000, 'exp1', '-v','bias','tail 0')'/1000; % [mm/yr]
%             V_pred2(p,:) = solve_LSC(iLat, iLong, lat(sel), long(sel), Vn_res(sel)*1000, Ve_res(sel)*1000, 'Gaussian',  'bias','tail 0')'/1000; % [mm/yr]
%             V_pred3(p,:) = solve_LSC(iLat, iLong, lat(sel), long(sel), Vn_res(sel)*1000, Ve_res(sel)*1000, 'Hirvonen',  'bias','tail 0')'/1000; % [mm/yr]
            LongGrid_2(p,1) = iLong;
            LatGrid_2(p,1)  = iLat;    
        end
    end
end
toc

%%
figure
hold on
grid on
axis equal
plot(Ve_res(sel), Vn_res(sel), '.b')
ellipce_2D([std(Ve_res(sel)), std(Vn_res(sel))], 0, [mean(Ve_res(sel)), mean(Vn_res(sel))], 1)

%%
solve_LSC(iLat, iLong, lat(sel), long(sel), Vn_res(sel)*1000, Ve_res(sel)*1000, 'exp1',    '-v','plot','hist','bias','tail 0')'/1000;
solve_LSC(iLat, iLong, lat(sel), long(sel), Vn_res(sel)*1000, Ve_res(sel)*1000, 'Gaussian','-v','plot','hist','bias','tail 0')'/1000; % [mm/yr]
solve_LSC(iLat, iLong, lat(sel), long(sel), Vn_res(sel)*1000, Ve_res(sel)*1000, 'Hirvonen','-v','plot','hist','bias','tail 0')'/1000; % [mm/yr]

%%
s = 1000*0.2;
try
    close (fig3)
end
fig3 = figure(3);
hold on
grid on
geoshow(Z, refvec, 'DisplayType', 'texturemap');
demcmap(Z);
cptcmap('Europe')
% Earth_coast(2)
% plot(long,lat,'or')
% plot(LongGrid_2, LatGrid_2,'om')
% plot(long(sel),lat(sel),'ok')
quiver(LongGrid_2,    LatGrid_2,     V_pred1(:,2)*s,      V_pred1(:,1)*s,0,'b')
% quiver(LongGrid_2,    LatGrid_2,     V_pred2(:,2)*s,      V_pred2(:,1)*s,0,'m')
% quiver(LongGrid_2,    LatGrid_2,     V_pred3(:,2)*s,      V_pred3(:,1)*s,0,'k')
quiver(long(Selected),lat(Selected), Ve_res(Selected)*s, Vn_res(Selected)*s, 0, 'r')
ellipce_2D([km2deg(Max_Dist,6378*cosd(iLat)) , Max_Dist/111], 0, [iLong, iLat], 1)
xlim([min(LongGrid_2)-3 max(LongGrid_2)+3])
ylim([min(LatGrid_2 )-3 max(LatGrid_2 )+3])

 
 