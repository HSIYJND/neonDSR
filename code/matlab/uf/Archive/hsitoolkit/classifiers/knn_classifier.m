function knn_out = knn_classifier(hsi_img,train_data,mask)
%function knn_out = knn_classifier(hsi_img,train_data,mask)
%
%  a simple K nearest nieghbors classifier 
%
% 10/31/2012 - Taylor C. Glenn - tcg@cise.ufl.edu


if ~exist('mask','var'); mask = []; end

knn_out = img_det(@knn_cfr,hsi_img,train_data,mask);

end

function knn_out = knn_cfr(hsi_data,train_data)

K = 5;

% concatenate the training data
train = [train_data.Spectra];
n_train = size(train,2);

labels = zeros(n_train,1);
n_class = numel(train_data);
last = 0;
for i=1:n_class
    nt = size(train_data(i).Spectra,2);    
    labels((last+1):(last+nt)) = i;
    last = last+nt;
end

[n_band,n_pix] = size(hsi_data);


% classify by majority of K nearest neighbors
knn_out = zeros(n_pix,1);

idx = knnsearch(train',hsi_data','K',K);

for i=1:n_pix
    
%     dists = sum((repmat(hsi_data(:,i),[1,n_train])-train).^2,1);
%         
%     [sd,si] = sort(dists,'ascend');
%     
%     inds = si(1:K);

    counts = zeros(n_class,1);
    for j=1:K
        counts(labels(idx(i,j))) = counts(labels(idx(i,j)))+1;
    end
    [~,max_i] = max(counts);
    
    knn_out(i) = max_i;
    
    %if ~mod(i,1000), fprintf('.'); end
    
end
%fprintf('\n');

end
