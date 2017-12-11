# Computer Vision based Carbohydrates Estimator.

## What is this?

Computer Vision based carbohydrate estimator which detects CHO from an image of food.

 This estimator performs the following operations
 1. Converts image to binary with a threshold and Canny edge detection is
    performed to find the boundary of the plate.
 2. Finds the best fitting elliptical shape of the plate boundary:
    Reference https://www.mathworks.com/matlabcentral/fileexchange/33970-ellipse-detection-using-1d-hough-transform
 3. Calculates the area of the plate using minor and major axis.
 4. A mask is created for the plate by coverting to HSV and applied on the
    original image
 5. Food is segmented from the plate and Median Shift Clustering is
    performed on the segmented food. 
    Reference: https://www.mathworks.com/matlabcentral/fileexchange/52698-k-means--mean-shift-and-normalized-cut-segmentation
 6. Features of the food items from the clusters are extracted and individual area is
    calulated.
 7. The CHO content of the detcted items are displayed.

## Getting Started
1. Run the carb_estimation_main.m in the unzipped folder file with all the files present in the directory.

## Contact
Open an issue here.
