%% BASIC classification

%# command to split training/testing sets
% [trainIdx testIdx] = crossvalind('HoldOut', species, 1/3);

% load and draw the group-scatter plot of the data

load fisheriris
SL = meas(51:end,1);
SW = meas(51:end,2);
group = species(51:end);
h1 = gscatter(SL,SW,group,'rb','v^',[],'off');
set(h1,'LineWidth',2)
legend('Fisher versicolor','Fisher virginica',...
       'Location','NW')
xlabel('Sepal Length')
ylabel('Sepal Width')
   
% Generate a grid of measurements on the same scale:
[X,Y] = meshgrid(linspace(4.5,8),linspace(2,4));
X = X(:); Y = Y(:);

% classify the generate points
[C,err,P,logp,coeff] = classify([X Y],[SL SW],...
                                group,'quadratic'); 
                   % linear, linear, quadratic, diagquadratic, mahalanobis
                            
% Visualize the classification:
hold on;
gscatter(X,Y,C,'rb','.',1,'off');
K = coeff(1,2).const;
L = coeff(1,2).linear; 
Q = coeff(1,2).quadratic;
% Function to compute K + L*v + v'*Q*v for multiple vectors
% v=[x;y]. Accepts x and y as scalars or column vectors.
f = @(x,y) K + [x y]*L + sum(([x y]*Q) .* [x y], 2);

h2 = ezplot(f,[4.5 8 2 4]);
set(h2,'Color','m','LineWidth',2)
axis([4.5 8 2 4])

title('{\bf Classification with Fisher Training Data}')