function [ species, reflectances_flaash, rois, northings, eastings, flights ] = get_field_FLAASH_pixels(envi03, envi04, envi05)
%% As field data provided by Sarah Graves are in ATCOR atmospheric correction
% This function will retrieve the flaash atmospheric correction values.

[ species, reflectances, rois, northings, eastings, flights ] = get_field_pixels();

reflectances_flaash = reflectances;
for i=1:numel(species)
    if strcmp(flights(i), '3')
        envi = envi03;
    elseif  strcmp(flights(i), '4')
        envi = envi04;
    elseif  strcmp(flights(i), '5')
        envi = envi05;
    end
    
    x=0; y=0;
    for j=1:numel(envi.x')
        if envi.x(j) <= eastings(i) && j+1 <= numel(envi.x) && envi.x(j+1) >= eastings(i)
            x = j;
        end
    end
    
    for j=1:numel(envi.y')
        %northings(i)
        
        if j+1 <= numel(envi.y)
         % disp([envi.y(1) envi.y(j) envi.y(j+1) envi.y(numel(envi.y))])
        end
        
        if envi.y(j) >= northings(i) && j+1 <= numel(envi.y) && envi.y(j+1) <= northings(i) % because envi.y(1) > envi.y(2)
            y = j;
        end
    end
    reflectances_flaash(i, :) = envi.z(round(y),round(x),:);
end

end

