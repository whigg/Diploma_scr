function plotStrain(Strain, scale)
% funiction to plot Strain field on 2D plot
%
% input : Strain [Lambda1, Lambga2, Omega1] - data matrix for all points,
% Omega in [deg]
%                   
%         Long, Lat       - coord-s, of points
%         scale           - scale of arrows   
% 
% output:
%
% command:
% [fig] = plotStrain(Strain, Long, Lat)
%
% Alexandr Sokolov, DGFI
% 07.11.2016
Long    = Strain(:,1); 
Lat     = Strain(:,2);
Lambda1 = Strain(:,3);
Lambda2 = Strain(:,4);
Omega   = Strain(:,5);

%% convert data to quiver plot
% main axis:
dx_L1 = Lambda1.*cosd(Omega);
dy_L1 = Lambda1.*sind(Omega);

% minor axis
dx_L2 = Lambda2.*cosd(Omega+90);
dy_L2 = Lambda2.*sind(Omega+90);

%% plot strain map
% fig = figure(1);
% hold on; grid on
% axis equal
% geoshow(Z, refvec, 'DisplayType', 'texturemap');
% demcmap(Z);
% cptcmap('Europe')
% Earth_coast(2)
% pl1 = quiver(Long, Lat,  dx_L1*scale,  dy_L1*scale, 0, 'b');
% pl2 = quiver(Long, Lat, -dx_L1*scale, -dy_L1*scale, 0, 'b');

% pl3 = quiver(Long + dx_rL2*scale, Lat + dy_L2*scale, -dx_L2*scale, -dy_L2*scale, 0, 'r');
% pl4 = quiver(Long - dx_L2*scale, Lat - dy_L2*scale, +dx_L2*scale, +dy_L2*scale, 0, 'r');

pl5 = quiver(Long, Lat, dx_L1*scale, dy_L1*scale, 0, 'b');
pl3 = quiver(Long, Lat, dx_L2*scale, dy_L2*scale, 0, 'r');

% title('Strain field')
% legend([pl1, pl3], 'major axis', 'minor axis')

% hold off
end