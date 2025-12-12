clc;
clear;

in_dir  = fullfile(pwd, 'images');  
out_dir = fullfile(pwd, 'results');  

img_path_list = dir(fullfile(in_dir, '*.jpg'));   
img_num = length(img_path_list);

times = zeros(img_num, 1);

for r = 1:img_num
    name    = img_path_list(r).name;
    in_path = fullfile(in_dir,  name);   
    save_path = fullfile(out_dir, name); 

    image_uint8 = imread(in_path);
    J0 = im2double(image_uint8);         

    tic;

    J1 = noises_light(J0);   

    [height, width, channels] = size(J1);
    win = 3;
    J2 = zeros(height, width, channels);

    for i = 1:height
        rmin = max(1, i-win);
        rmax = min(height, i+win);
        for j = 1:width
            cmin = max(1, j-win);
          cmax = min(width, j+win);
          patch = J1(rmin:rmax, cmin:cmax, :);
          max_value = squeeze(max(max(patch, [], 1), [], 2));
         J2(i, j, :) = max_value;
        end
    end

    JJ2 = imboxfilt(J2, [7, 7]);   

    imd = J1;     
    blocksize   = 95;
    showFigure  = 0;
    A1 = findAirlight2(imd, blocksize, showFigure);

    a   = 1;
    A_G = A1(2); 
    A_B = A1(3);
    if A1(2) <= A1(3)
       A_R = a*(A1(3)-A1(1))*A1(3) + A1(1);
      A_G = a*(A1(3)-A1(2))*A1(3) + A1(2);
    else
      A_R = a*(A1(2)-A1(1))*A1(2) + A1(1);
      A_B = a*(A1(2)-A1(3))*A1(2) + A1(3);
    end

    I2(:,:,1) = imd(:,:,1) ./ A_R;
    I2(:,:,2) = imd(:,:,2) ./ A_G;
    I2(:,:,3) = imd(:,:,3) ./ A_B;
    I2 = imadjust(I2, stretchlim(I2));
    I2 = im2double(I2);

    [tr, tg, tb] = Transmisson(J1);
    t0  = 0.1;
    Tr  = max(tr, t0);
    Tg  = max(tg, t0);
    Tb  = max(tb, t0);

    Ir = (I2(:,:,1) - JJ2(:,:,1) .* (1 - Tr)) ./ Tr;
    Ig = (I2(:,:,2) - JJ2(:,:,2) .* (1 - Tg)) ./ Tg;
    Ib = (I2(:,:,3) - JJ2(:,:,3) .* (1 - Tb)) ./ Tb;
    I  = cat(3, Ir, Ig, Ib);

    enhanced_img = contrast_optimized(I);

    times(r) = toc;
    imwrite(enhanced_img, save_path);
end

meanTime = mean(times);
fprintf('meanTime：%.4f s\n', meanTime);
