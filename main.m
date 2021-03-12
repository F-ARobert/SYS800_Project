%% Main file for image preprocessing Project SYS800

clc;
clear;

% Load data
data = readtable('data.csv');
%%
% Create list of img ids
ids = data.('ImgID'); % use {} to access strings

%% Constants
new_z_dim = 128;
% Blurring window size and Padding value
win_blur = 5;
pad = 0;
sigma = 0.5;

%% Cycle through each image and apply preprocessing

for i = 1:length(ids)
    % Load image
    name = ids{i};
    name = strcat('images/', name, '.TIF');
    try
        img = Tiff(name);
    catch ME
        display ('Error opening' + name + 'image');
    end
    
    % Create imag array
    img = create_3d_image(img);
    
    %% Step 1: resize image
    % Resize to 512x512x128x3
    % Red
    tic
    resized_img(:,:,:,1) = imresize3(img(:,:,:,1), [512 512 128], 'linear');
    %Green
    resized_img(:,:,:,2) = imresize3(img(:,:,:,2), [512 512 128], 'linear');
    %Blue
    resized_img(:,:,:,3) = imresize3(img(:,:,:,3), [512 512 128], 'linear');
    toc
    % Blue layer is empty. Can be ignore from now on.
    
    %% Step 2: Apply blurring kernel
    % use function imgaussfilt3 included in Matlab
    % Send array to GPU
    gpuArray(resized_img);
    tic
    Blurred_img(:,:,:,1) = imgaussfilt3(resized_img(:,:,:,1), sigma, ...
        'Padding', pad, 'FilterSize', win_blur);
    Blurred_img(:,:,:,2) = imgaussfilt3(resized_img(:,:,:,2), sigma,...
        'Padding', pad, 'FilterSize', win_blur);
    Blurred_img(:,:,:,3) = resized_img(:,:,:,3);
    toc
    % Retreive image from GPU
    % gather(Blurred_img);
    
    %% Step 3: Normalization of the image
    % Generate histogram
    hist_RG = [imhist(Blurred_img(:,:,:,1)) imhist(Blurred_img(:,:,:,2))];
    
    % Normalize
    avg = mean(hist_RG);
    min_val = min(hist_RG);
   
    norm_img(:,:,:,1) = (Blurred_img(:,:,:,1)-min_val(1))/(avg(1)-min_val(1));
    norm_img(:,:,:,2) = (Blurred_img(:,:,:,2)-min_val(2))/(avg(2)-min_val(2));
    norm_img(:,:,:,3) = Blurred_img(:,:,:,3);
end

