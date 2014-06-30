function heightMap = getHeightMap( lidar_file )



%disp(['Time: ' datestr(now, 'HH:MM:SS')])
%addpath('/cise/homes/msnia/zproject/neonDSR/code/matlab/lidar/');
%lidar_file = '/cise/homes/msnia/neon/lidar/DL20100901_osbs_FL09_discrete_lidar_NEON-L1B/DL20100901_osbs_FL09_discrete_lidar_NEON-L1B.las';
params = 'xyz'; % 'A'
[s, h, v] = lasread(lidar_file, params);
zmean= mean(s.Z); % elevation
zstd = std(s.Z);
nonoutlier_elevations_indexes = s.Z <zmean + 3 * zstd;
s.Z = s.Z(nonoutlier_elevations_indexes);
s.X = s.X(nonoutlier_elevations_indexes);
s.Y = s.Y(nonoutlier_elevations_indexes);

figure, hist(s.Z, 40);
lasview(lastrim(s,50000),'z'); %sam
%disp(['Time: ' datestr(now, 'HH:MM:SS')])

%lidar bining and averaging
Zmap = lidarBining(s,1);
figure, hist(Zmap(:), 40), title('elevation') , grid on,   set(gca,'YTick',[0:25:15000]);
figure, imagesc(Zmap');

heightMap = lidarElevationToHeight(Zmap, 3);
hm = heightMap(:);
figure, hist(hm(hm > 2), 40),  title('height'), grid on,   set(gca,'YTick',[0:25:15000])



figure, imagesc(heightMap');



% takes 10 miutes to draw contour
%step = 150;
%x=linspace(min(s.X),max(s.X),step);
%y=linspace(min(s.Y),max(s.Y),step);
%[X,Y]=meshgrid(x,y);
%F=TriScatteredInterp(s.X,s.Y,s.Z-1);
%contourf(X,Y,F(X,Y),100,'LineColor','none');

end
