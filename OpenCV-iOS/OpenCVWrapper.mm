//
//  OpenCVWrapper.mm
//  OpenCV-iOS
//
//  Created by TerryLiu on 2/2/18.
//  Copyright © 2018 TerryLiu. All rights reserved.
//

#import "OpenCVWrapper.h"
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/highgui.hpp>
#import <opencv2/imgproc.hpp>
#import <opencv2/xfeatures2d.hpp>

@implementation OpenCVWrapper

using namespace cv;

+ (NSString *)OpenCVVString{
    return [NSString stringWithFormat:@"OpenCV Version %s", CV_VERSION];
}

+ (UIImage *)DetectFeatures:(UIImage*)image{
    
    Mat imageMat;
    UIImageToMat(image, imageMat);
    Mat imageGray;
    cvtColor(imageMat, imageGray, COLOR_BGR2GRAY);
    
    RNG rng(12345);
    int maxCorners = 25;
    std::vector<Point2f> corners;
    double qualityLevel = 0.01;
    double minDistance = 10;
    int blockSize = 3, gradiantSize = 3;
    bool useHarrisDetector = false;
    double k = 0.04;
    goodFeaturesToTrack(imageGray,
                        corners,
                        maxCorners,
                        qualityLevel,
                        minDistance,
                        Mat(),
                        blockSize,
                        gradiantSize,
                        useHarrisDetector,
                        k );
    int r = 4;
    for( size_t i = 0; i < corners.size(); i++ )
    { circle( imageMat, corners[i], r, Scalar(rng.uniform(0,255), rng.uniform(0,255), rng.uniform(0,255)), -1, 8, 0 ); }
        
    return MatToUIImage(imageMat);
}

+(UIImage *)SobelFilter:(UIImage *)image{
    
    Mat mat;
    UIImageToMat(image, mat);
    
    Mat gray;
    cvtColor(mat, gray, cv::COLOR_BGR2GRAY);
    
    Mat edge;
    Canny(gray, edge, 100, 200);
    
    UIImage *result = MatToUIImage(edge);
    return result;
}
@end
