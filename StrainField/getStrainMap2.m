function [StrainStack] = getStrainMap2(Deformation)
% compute strain field
% result is Stack [p,7]
%
% Alexandr Sokolov, KEG
% 23.11.2016

%% wrap stack into 2D grid
Grid = stack2grid(Deformation);

LongGrid = squeeze(Grid(:,:,1));
LatGrid  = squeeze(Grid(:,:,2));
VelGrid =  squeeze(Grid(:,:,3:end));

StepLong = LongGrid(1,2) - LongGrid(1,1);
StepLat  = LatGrid(2,1)  - LatGrid(1,1); 

sizeGrid = size(LongGrid);
StrainGrid = NaN( [sizeGrid(1)-1, sizeGrid(2)-1, 7] );

% points order  :  Bx
%                  AC

%% compute Strain

row = 0;
for iLong = 1:size(Grid,2)-1
   for iLat = 1:size(Grid,1)-1
       PointA = [LongGrid(iLat, iLong),     LatGrid(iLat,     iLong)];
       PointB = [LongGrid(iLat, iLong),     LatGrid(iLat + 1, iLong)];
       PointC = [LongGrid(iLat, iLong + 1), LatGrid(iLat,     iLong)];
       VelA = squeeze(VelGrid(iLat,    iLong,:)); 
       VelB = squeeze(VelGrid(iLat + 1,iLong,:));
       VelC = squeeze(VelGrid(iLat,    iLong + 1,:));
    
       % get Strain b/w grid ponts
       StrainBlock = getStrain3(PointA, PointB, PointC, VelA, VelB, VelC);
       
       % put into grid, 3D matrix
%        StrainGrid(iLong, iLat, :) = StrainBlock;
%      Save result in Stack
       row = row + 1;
       StrainStack(row,:) = StrainBlock;
   end
end   


end