function carb_estimation_main()

% Main file for Carb estimation using Food segmentation and area.
% Input Looks for a food image on a current directory.
% ========================================================================
% This file performs the following operations
% 1. Converts image to binary with a threshold and Canny edge detection is
%    performed to find the boundary of the plate.
% 2. Finds the best fitting elliptical shape of the plate boundary:
%    Reference https://www.mathworks.com/matlabcentral/fileexchange/33970-ellipse-detection-using-1d-hough-transform
% 3. Calculates the area of the plate using minor and major axis.
% 4. A mask is created for the plate by coverting to HSV and applied on the
%    original image
% 5. Food is segmented from the plate and Median Shift Clustering is
%    performed on the segmented food. 
%    Reference: https://www.mathworks.com/matlabcentral/fileexchange/52698-k-means--mean-shift-and-normalized-cut-segmentation
% 6. Features of the food items from the clusters are extracted and individual area is
%    calulated.
% 7. The CHO content of the detcted items are displayed.
% ========================================================================
% Author: Ganesh Rajasekharan
%

    %Read in the image
    I = im2double(imread('Pasta.png'));
    
    imshow(I);
    title('Original Image');
    pause(2);
       
    %Find the edge map for the plate boundary
    E = edge(rgb2gray(I),'canny', 0.95);
    %imshow(E);

    % set some parameters for the ellipse detector
    params.minMajorAxis = 0;
    params.maxMajorAxis = 600;
    params.numBest = 1;

    %[x, y, z] = size(E);

    % use the edge image to fit the ellipse
    fprintf('Identifying the best possible elliptical fit for the plate..\n');
    bestFits = ellipseDetection(E, params);

%     fprintf('*********');
%     disp(bestFits);
%     fprintf('*********');
    
    %Extract major and minor axes lengths
    a = bestFits(:, 3);
    b = bestFits(:, 4);
    
    %calculate area of the plate
    area_plate_pix = 3.14 * a * b;
    %area_plate_pix = int64(area_plate_pix);


    fprintf('Output %d best fits.\n', size(bestFits,1));

    figure;
    image(I);
    title('Elliptical Plate Identification')
    %ellipse drawing implementation: http://www.mathworks.com/matlabcentral/fileexchange/289
    ellipse(a,b,bestFits(:,5)*pi/180,bestFits(:,1),bestFits(:,2),'r');
    pause(3);


%%

%Convert the image to HSV and segment the food out of the plates.
	rgbImage = imread('Pasta.png');
    
	% Convert RGB image to HSV
	hsvImage = rgb2hsv(rgbImage);
	% Get the H,S,V channels
	hImage = hsvImage(:,:,1);
	sImage = hsvImage(:,:,2);
	vImage = hsvImage(:,:,3);

    % Set some high and low H,S,V thresholds for the image.
    h_low = 0;
    h_high = graythresh(hImage);
    
    sat_low = graythresh(sImage);
    sat_high = 1.0;
    
    val_low = graythresh(vImage);
    valueThresholdHigh = 1.0;

	% Apply calculated thresholds to channels
    % Reference: https://www.mathworks.com/matlabcentral/fileexchange/28512-simplecolordetectionbyhue--
	hueMask = (hImage >= h_low) & (hImage <= h_high);
	saturationMask = (sImage >= sat_low) & (sImage <= sat_high);
	valueMask = (vImage >= val_low) & (vImage <= valueThresholdHigh);
    
    rgb_mask = uint8(hueMask & saturationMask & valueMask);

	% Filter out small objects using a min area threshold
	min_area_threshold = 100;

	% Get rid of small objects.  Note: bwareaopen returns a logical.
	rgb_mask = uint8(bwareaopen(rgb_mask, min_area_threshold));

	% Borders are corrected using morphological closing.
	struct_elem = strel('disk', 4);
	rgb_mask = imclose(rgb_mask, struct_elem);

	% Holes are filled in
	rgb_mask = imfill(logical(rgb_mask), 'holes');

	rgb_mask = cast(rgb_mask, 'like', rgbImage); 

	% Use the object mask and apply it only to the colored of the image
	maskedImageR = rgb_mask .* rgbImage(:,:,1);
	maskedImageG = rgb_mask .* rgbImage(:,:,2);
	maskedImageB = rgb_mask .* rgbImage(:,:,3);

	% Form the RGB image by appending the channel masks with each other
	maskedRGBImage = cat(3, maskedImageR, maskedImageG, maskedImageB);
	% Show the masked off, original image.
    
	imshow(maskedRGBImage);
    title('Food Segementation using HSV');
    pause(2);
    
    %%
    % Apply mean shift clustering to the segmented food
    % meanshift bandwidth parameter
    bw   = 0.08;
    
    fprintf('Applying Mean Shift Clustering..\n');
    
    [Ims, Nms]   = Ms(maskedRGBImage,bw);
    
%     imshow(Ims);
%     title(['After Mean Shift clustering',' : ',num2str(Nms)]);
%     pause(2);
    
    %  imshow(Ims);
    %  [x, y] = getpts();
    %  P = regiongrowing(Ims,x,y,0.08);
    %
    %  figure, imshow(Ims-2*P);
    %  pause(2)
    
    % RGB = Ims;
    % gray = rgb2gray(RGB);
    % bw = im2bw(gray, 0.8);
    % L = bwlabel(bw);
    % stats = regionprops(L,'All');
    % area = [stats.Area];
    % disp(area);
    
%     H = fspecial('average', [10 10]);
%     Ims_filt = imfilter(Ims, H);
%     
%     imshow(Ims_filt);
    
 
    % RGB information
    % Bread : [R,G, B] = [222, 158, 23];
    % Pasta : [R,G, B] = [227, 199, 76];
    % Salad : [R,G, B] = [142, 120, 59];
    
    Iint = im2uint8(Ims);
    imshow(Iint);
    title('Image after Mean Shift Clustering');
    pause(2);
    
    black_pixel_count = 0;   
    bread_pixel_count = 0;
    pasta_pixel_count = 0;
    salad_pixel_count = 0;
    
    %CHO densities as grams per 100g - Source USDA database
    bread_cho_density = 45;
    pasta_cho_density = 24;
    salad_cho_density = 3;
    
    [x1,y1,~] = size(Iint);
    
    % Run through the image and classify pixels based on RGB values
    for x=1:1:x1
        for y=1:1:y1
            
            if (Iint(x,y, 1) == 0) && (Iint(x,y, 2) == 0) && (Iint(x,y,3) == 0)
                black_pixel_count = black_pixel_count + 1;
                continue;
            end

            if  ((Iint(x,y,1)>=215) && (Iint(x,y,1)<=230)) && ...
                ((Iint(x,y,2)>=140 && (Iint(x,y,2))<=170)) && ...
                ((Iint(x,y,3)>= 15 && (Iint(x,y,3))<=30))
                 bread_pixel_count = bread_pixel_count + 1 ;
                 continue;
            
            end
            
            if  ((Iint(x,y,1)>=215) && (Iint(x,y,1)<=230)) && ...
                ((Iint(x,y,2)>=190 && (Iint(x,y,2))<=210)) && ...
                ((Iint(x,y,3)>= 65 && (Iint(x,y,3))<=85))
                 pasta_pixel_count = pasta_pixel_count + 1 ;
                 continue
            end
            
            
            if  ((Iint(x,y,1)>=35) && (Iint(x,y,1)<=155)) && ...
                ((Iint(x,y,2)>=55 && (Iint(x,y,2))<=160)) && ...
                ((Iint(x,y,3)>= 8 && (Iint(x,y,3))<=70))
                salad_pixel_count = salad_pixel_count + 1;
                continue;
                
            end            
        end
    end
    
    %Compute surface area of plate constituents
    plate_total = area_plate_pix;
    area_plate_cm = 3.14 * 15 * 15;
    %area_plate_cm = int64(area_plate_cm);
    %bread_pixel_count = int64(bread_pixel_count);
    
    % Compute the individual areas using the plates area as scale
    plate_area_pixel = area_plate_cm / plate_total;
    plate_area_pixel = plate_area_pixel /100;
    
    %Convert pixel counts to surface area
    area_bread = (plate_area_pixel * bread_pixel_count);   
    area_pasta = (plate_area_pixel * pasta_pixel_count);   
    area_salad = (plate_area_pixel * salad_pixel_count);
    
    %Compute CHO from area and CHO density
    cho_bread = area_bread * bread_cho_density;
    cho_pasta = area_pasta * pasta_cho_density;
    cho_salad = area_salad * salad_cho_density;
    
    net_cho = cho_bread+cho_pasta+cho_salad;
    net_cho = int64(net_cho);
    
   
%     display(area_bread);
%     fprintf('-------------------------\n');
%     
%     display(area_pasta);
%     fprintf('-------------------------\n');
%     
%     display(area_salad);
%     fprintf('-------------------------\n');
%     
%        
%     fprintf('Bread pixel count');
%     disp(bread_pixel_count);
%     fprintf('-------------------------\n');
%         
%     
%     fprintf('Pasta pixel count');
%     disp(pasta_pixel_count);
%     fprintf('-------------------------\n');
%     
%     
%     fprintf('Salad pixel count');
%     disp(green_pixel_count);
%     fprintf('-------------------------\n');
%     
%     
%     fprintf('Black pixel count');
%     disp(black_pixel_count);
%     fprintf('-------------------------\n');
    

    
    % Display the net computed CHO with the image
    str1 = string('Total CHO present: %d grams');
    str2 = net_cho;
    caption = sprintf(str1,str2);
    
    figure;
    imshow(I);  
    title(caption,'FontSize', 14);
    
    fprintf('----------- "carb_estimation_main" Terminated-----------\n');

    
    
    
    
    
