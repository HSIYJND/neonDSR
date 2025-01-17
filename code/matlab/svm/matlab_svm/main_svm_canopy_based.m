
init(); 
global setting;
addpath(strcat(setting.PREFIX,'/neonDSR/code/matlab/io'));
addpath(strcat(setting.PREFIX,'/neonDSR/code/matlab/io/csvIO'));
addpath(strcat(setting.PREFIX,'/neonDSR/code/matlab/svm'));
addpath(strcat(setting.PREFIX,'/neonDSR/code/matlab/svm/matlab_svm'));
addpath(strcat(setting.PREFIX,'/neonDSR/code/matlab/hyperspectral'));

[ species, reflectances, rois, northings, eastings, flights ] = get_field_ATCOR_pixels();

rng(setting.RANDOM_VALUE_SEED); 
% shuffle pixels
%permutation_idx = randperm(numel(species));
%species = species(permutation_idx);
%rois = rois(permutation_idx);
%reflectances = reflectances(permutation_idx, :);

% scale reflectance intensity values to [0,1]
for i=1: size(reflectances, 1)
    reflectances(i,:) = scalePixel(reflectances(i,:));
end


ndvi = toNDVI(reflectances);
green_ndvi_reflectances = reflectances;
for i=1:numel(ndvi)
        if ndvi(i) < setting.NDVI_THRESHOLD
            green_ndvi_reflectances(i, :)  = nan;
        end
        
        if green_ndvi_reflectances(i,setting.NIR_INDEX) < setting.NIR_THRESHOLD
            green_ndvi_reflectances(i, :)  = nan;
        end
    
end         
low_ndvi_indexes = ~any(~isnan(green_ndvi_reflectances), 2);

green_ndvi_species = species;
green_ndvi_rois = rois;
green_ndvi_reflectances(low_ndvi_indexes,:)=[]; % from 1269 to 712
green_ndvi_species(low_ndvi_indexes) = [];    %TODO grid search for parameters 
green_ndvi_rois(low_ndvi_indexes) = [];



nongreen_ndvi_reflectances = reflectances;
nongreen_ndvi_reflectances(~low_ndvi_indexes,:)=[];


%%

%%
matlabpool(8)



%% Display signals

visualize_reflectances(nongreen_ndvi_reflectances);
visualize_reflectances(green_ndvi_reflectances);


%%
tic
[libsvm_gaussian_atcor, libsvm_poly_atcor, libsvm_rbf_atcor] = get_svm_statistics_canopy_based(green_ndvi_species, green_ndvi_reflectances, green_ndvi_rois, 'libsvm');
toc

figure;
plot(setting.SVM_GAUSSIAN_SMOOTHING_WINDOWS, libsvm_gaussian_atcor);
xlabel('Gaussian window size'); ylabel('Accuracy (%)');
title(sprintf('Effects of Gaussian Window Size on Classification Accuracy \n (canopy-based) - Polynimial Kernel Order 3'));

figure;
%semilogx(polynomial_orders(1:numel(polynomial_orders)), svm_results_poly(1:numel(polynomial_orders)),'marker', 's');
%plot(setting.SVM_POLYNOMIAL_ORDERS, svm_poly_atcor);
plot(libsvm_poly_atcor)
figure 
surf(setting.LIBSVM_COST_VALUES, setting.SVM_POLYNOMIAL_ORDERS, libsvm_poly_atcor)
zlabel('Prediction Accuracy')
xlabel('C'); ylabel('Polynomial Degree');
[v,ind]=max(libsvm_poly_atcor);
[v1,ind1]=max(max(libsvm_poly_atcor));
disp(sprintf('The largest element in this matrix is %f at (%d,%d).', v1, ind(ind1), ind1 ));
title(sprintf('Effects of Polynomial Order on Classification Accuracy (canopy-based)'));

figure;
%semilogx(setting.SVM_RBF_SIGMA_VALUES, svm_rbf_atcor);
%grid on
plot(libsvm_rbf_atcor)
figure 
surf(setting.LIBSVM_COST_VALUES, setting.SVM_RBF_SIGMA_VALUES, libsvm_rbf_atcor)
zlabel('Prediction Accuracy')
xlabel('C'); ylabel('Polynomial Degree');
[v,ind]=max(libsvm_rbf_atcor);
[v1,ind1]=max(max(libsvm_rbf_atcor));
disp(sprintf('The largest element in this matrix is %f at (%d,%d).', v1, ind(ind1), ind1 ));
xlabel('SVM Kernel - RBF (\sigma)'); ylabel('Accuracy (%)');
title('Effects of RBF Kernel \sigma on SVM Classification Accuracy (canopy-based)');









tic
[svm_gaussian_atcor, svm_poly_atcor, svm_rbf_atcor] = get_svm_statistics_canopy_based(green_ndvi_species, green_ndvi_reflectances, green_ndvi_rois, 'matlab');
toc

figure;
plot(setting.SVM_GAUSSIAN_SMOOTHING_WINDOWS, svm_gaussian_atcor);
xlabel('Gaussian window size'); ylabel('Accuracy (%)');
title(sprintf('Effects of Gaussian Window Size on Classification Accuracy \n (canopy-based) - Polynimial Kernel Order 3'));

figure;
%semilogx(polynomial_orders(1:numel(polynomial_orders)), svm_results_poly(1:numel(polynomial_orders)),'marker', 's');
%plot(setting.SVM_POLYNOMIAL_ORDERS, svm_poly_atcor);
plot(svm_poly_atcor)
figure 
surf(setting.LIBSVM_COST_VALUES, setting.SVM_POLYNOMIAL_ORDERS, svm_poly_atcor)
zlabel('Prediction Accuracy')
xlabel('C'); ylabel('Polynomial Degree');
[v,ind]=max(svm_poly_atcor); [v1,ind1]=max(max(svm_poly_atcor)); disp(sprintf('Max in svm_poly_atcor is %f at (%d,%d).', v1, ind(ind1), ind1 ));
title(sprintf('Effects of Polynomial Order on Classification Accuracy (canopy-based)'));

figure;
%semilogx(setting.SVM_RBF_SIGMA_VALUES, svm_rbf_atcor);
%grid on
plot(svm_rbf_atcor)
figure 
surf(setting.LIBSVM_COST_VALUES, setting.SVM_RBF_SIGMA_VALUES, svm_rbf_atcor)
zlabel('Prediction Accuracy')
xlabel('C'); ylabel('Polynomial Degree');
[v,ind]=max(svm_rbf_atcor); [v1,ind1]=max(max(svm_rbf_atcor)); disp(sprintf('Max in svm_rbf_atcor is %f at (%d,%d).', v1, ind(ind1), ind1 ));
xlabel('SVM Kernel - RBF (\sigma)'); ylabel('Accuracy (%)');
title('Effects of RBF Kernel \sigma on SVM Classification Accuracy (canopy-based)');






















%% ON ALL PIXELS NOT JUST REMOVED NDVIS



tic
[libsvm_gaussian_atcorFULL, libsvm_poly_atcorFULL, libsvm_rbf_atcorFULL] = get_svm_statistics_canopy_based(species, reflectances, rois, 'libsvm');
toc

figure;
plot(setting.SVM_GAUSSIAN_SMOOTHING_WINDOWS, libsvm_gaussian_atcorFULL);
xlabel('Gaussian window size'); ylabel('Accuracy (%)');
title(sprintf('Effects of Gaussian Window Size on Classification Accuracy \n (canopy-based) - Polynimial Kernel Order 3'));

figure;
%semilogx(polynomial_orders(1:numel(polynomial_orders)), svm_results_poly(1:numel(polynomial_orders)),'marker', 's');
%plot(setting.SVM_POLYNOMIAL_ORDERS, svm_poly_atcor);
plot(libsvm_poly_atcorFULL)
figure 
surf(setting.LIBSVM_COST_VALUES, setting.SVM_POLYNOMIAL_ORDERS, libsvm_poly_atcorFULL)
zlabel('Prediction Accuracy')
xlabel('C'); ylabel('Polynomial Degree');
[v,ind]=max(libsvm_poly_atcorFULL); [v1,ind1]=max(max(libsvm_poly_atcorFULL)); disp(sprintf('Max in libsvm_poly_atcorFULL is %f at (%d,%d).', v1, ind(ind1), ind1 ));
title(sprintf('Effects of Polynomial Order on Classification Accuracy (canopy-based)'));

figure;
%semilogx(setting.SVM_RBF_SIGMA_VALUES, svm_rbf_atcor);
%grid on
plot(libsvm_rbf_atcorFULL)
figure 
surf(setting.LIBSVM_COST_VALUES, setting.SVM_RBF_SIGMA_VALUES, libsvm_rbf_atcorFULL)
zlabel('Prediction Accuracy')
xlabel('C'); ylabel('Polynomial Degree');
[v,ind]=max(libsvm_rbf_atcorFULL); [v1,ind1]=max(max(libsvm_rbf_atcorFULL)); disp(sprintf('Max in libsvm_rbf_atcorFULL is %f at (%d,%d).', v1, ind(ind1), ind1 ));
xlabel('SVM Kernel - RBF (\sigma)'); ylabel('Accuracy (%)');
title('Effects of RBF Kernel \sigma on SVM Classification Accuracy (canopy-based)');









tic
[svm_gaussian_atcorFULL, svm_poly_atcorFULL, svm_rbf_atcorFULL] = get_svm_statistics_canopy_based(species, reflectances, rois, 'matlab');
toc

figure;
plot(setting.SVM_GAUSSIAN_SMOOTHING_WINDOWS, svm_gaussian_atcorFULL);
xlabel('Gaussian window size'); ylabel('Accuracy (%)');
title(sprintf('Effects of Gaussian Window Size on Classification Accuracy \n (canopy-based) - Polynimial Kernel Order 3'));

figure;
%semilogx(polynomial_orders(1:numel(polynomial_orders)), svm_results_poly(1:numel(polynomial_orders)),'marker', 's');
%plot(setting.SVM_POLYNOMIAL_ORDERS, svm_poly_atcor);
plot(svm_poly_atcorFULL)
figure 
surf(setting.LIBSVM_COST_VALUES, setting.SVM_POLYNOMIAL_ORDERS, svm_poly_atcorFULL)
zlabel('Prediction Accuracy')
xlabel('C'); ylabel('Polynomial Degree');
[v,ind]=max(svm_poly_atcorFULL);
[v1,ind1]=max(max(svm_poly_atcorFULL));
disp(sprintf('The largest element in this matrix is %f at (%d,%d).', v1, ind(ind1), ind1 ));
title(sprintf('Effects of Polynomial Order on Classification Accuracy (canopy-based)'));

figure;
%semilogx(setting.SVM_RBF_SIGMA_VALUES, svm_rbf_atcor);
%grid on
plot(svm_rbf_atcorFULL)
figure 
surf(setting.LIBSVM_COST_VALUES, setting.SVM_RBF_SIGMA_VALUES, svm_rbf_atcorFULL)
zlabel('Prediction Accuracy')
xlabel('C'); ylabel('Polynomial Degree');
[v,ind]=max(svm_rbf_atcorFULL);
[v1,ind1]=max(max(svm_rbf_atcorFULL));
disp(sprintf('The largest element in this matrix is %f at (%d,%d).', v1, ind(ind1), ind1 ));
xlabel('SVM Kernel - RBF (\sigma)'); ylabel('Accuracy (%)');
title('Effects of RBF Kernel \sigma on SVM Classification Accuracy (canopy-based)');

%% FLAASH
% best performance confusion matrix


[ speciesFLAASH, reflectancesFLAASH, roisFLAASH, northingsFLAASH, eastingsFLAASH, flightsFLAASH ] = get_field_FLAASH_pixels(envi03, envi04, envi05);
[svm_gaussian_flaash, svm_poly_flaash, svm_rbf_flaash] = get_svm_statistics_canopy_based(speciesFLAASH, reflectancesFLAASH, roisFLAASH);


%%

% the final result of cross-validation would be trained on all the data
% using the parameters that had the best accuracy in average of its k-fold
% runs.


