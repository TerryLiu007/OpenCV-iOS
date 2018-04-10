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
using namespace cv::xfeatures2d;




+ (NSString *)OpenCVVString{
    return [NSString stringWithFormat:@"OpenCV Version %s", CV_VERSION];
}




+(UIImage *)CannyEdge:(UIImage *)image{
    
    Mat mat;
    UIImageToMat(image, mat);
    Mat gray;
    cvtColor(mat, gray, COLOR_BGR2GRAY);
    
    Mat edge;
    Canny(gray, edge, 100, 200);
    
    return MatToUIImage(edge);
}




+ (UIImage *)BilateralFilter:(UIImage *)image{
    
    Mat mat;
    UIImageToMat(image, mat);
    cvtColor(mat, mat, COLOR_BGRA2BGR);
    Mat bilateral;
    bilateralFilter(mat, bilateral, 10, 75, 75);
    
    return MatToUIImage(bilateral);
}




+ (UIImage *)DetectColor:(UIImage *)image{
    
    Mat bgr;
    UIImageToMat(image, bgr);
    Mat hsv;
    cvtColor(bgr, hsv, COLOR_BGR2HSV);
    
    Mat mask;
    inRange(hsv, Scalar(0,0,240), Scalar(255,255,255), mask);
    Mat kernel = cv::getStructuringElement(MORPH_ELLIPSE, cv::Size(5,5));
    morphologyEx(mask, mask, MORPH_OPEN, kernel);
    
    Mat result;
    bitwise_and(hsv, hsv, result, mask);
    cvtColor(result, result, COLOR_HSV2BGR);

    return MatToUIImage(result);
}




+ (UIImage *)DetectFeatures:(UIImage*)image{
    
    Mat imageMat;
    UIImageToMat(image, imageMat);
    Mat imageGray;
    cvtColor(imageMat, imageGray, COLOR_BGR2GRAY);
    
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
    { circle( imageMat, corners[i], r, Scalar(255), -1, 8, 0 ); }
    
    return MatToUIImage(imageMat);
}




std::vector<KeyPoint> keypoints_object;
Mat descriptors_object;
Mat img_object(640, 480, CV_8UC1);
Ptr<ORB> detector_orb = ORB::create();
Ptr<BRISK> detector_brisk = BRISK::create();
Ptr<AKAZE> detector_akaze = AKAZE::create();
Ptr<SURF> detector_surf = SURF::create(400);


+(UIImage *)ORBMatching:(UIImage *)inputScene withTemplate:(UIImage *)inputObject withRedetect:(BOOL)redetect{
    
    // Convert UIImage to Mat in grayscale
    Mat mat_scene;
    UIImageToMat(inputScene, mat_scene);
    Mat img_scene;
    cvtColor(mat_scene, img_scene, cv::COLOR_BGR2GRAY);

    // Detect features of the object if needed
    if(redetect && inputObject != NULL)
    {
        Mat mat_object;
        UIImageToMat(inputObject, mat_object);
        cv::resize(mat_object, img_object, img_object.size(), INTER_AREA);
        cvtColor(img_object, img_object, cv::COLOR_BGR2GRAY);
        
        detector_orb->detectAndCompute( img_object, Mat(), keypoints_object, descriptors_object );
    }

    if(!descriptors_object.data)
    {
        int maxCorners = 25;
        std::vector<Point2f> corners;
        double qualityLevel = 0.01;
        double minDistance = 10;
        int blockSize = 3, gradiantSize = 3;
        bool useHarrisDetector = false;
        double k = 0.04;
        
        goodFeaturesToTrack(img_scene,
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
        { circle( mat_scene, corners[i], r, Scalar(255), -1, 8, 0 ); }
        
        return MatToUIImage(mat_scene);
    }
 
    std::vector<KeyPoint> keypoints_scene;
    Mat descriptors_scene;
    detector_orb->detectAndCompute( img_scene, Mat(), keypoints_scene, descriptors_scene );
    
    
    if (keypoints_scene.size() < 12)
    {
        return MatToUIImage(mat_scene);
    }
    
    //std::vector< DMatch > matches;
    std::vector< DMatch > good_matches;
    
    //Matching descriptor vectors using BF with Crosscheck
    BFMatcher matcher(NORM_HAMMING, true);
    matcher.match( descriptors_object, descriptors_scene, good_matches );
    
    // Localize the object
    std::vector<Point2f> obj;
    std::vector<Point2f> scene;
    for( size_t i = 0; i < good_matches.size(); i++ )
    {
        // Get the keypoints from the good matches
        obj.push_back( keypoints_object[ good_matches[i].queryIdx ].pt );
        scene.push_back( keypoints_scene[ good_matches[i].trainIdx ].pt );
    }
    Mat H = findHomography( obj, scene, RANSAC, 6.0);
    
    // Get the corners from the object ( the object to be "detected" )
    std::vector<Point2f> obj_corners(4);
    obj_corners[0] = cvPoint(0,0);
    obj_corners[1] = cvPoint( img_object.cols, 0 );
    obj_corners[2] = cvPoint( img_object.cols, img_object.rows );
    obj_corners[3] = cvPoint( 0, img_object.rows );
    std::vector<Point2f> scene_corners(4);
    perspectiveTransform( obj_corners, scene_corners, H);
    
    if(isContourConvex(scene_corners)){
        // Draw lines between the corners ( the mapped object in the scene )
        line( mat_scene, scene_corners[0], scene_corners[1], Scalar(255), 4 );
        line( mat_scene, scene_corners[1], scene_corners[2], Scalar(255), 4 );
        line( mat_scene, scene_corners[2], scene_corners[3], Scalar(255), 4 );
        line( mat_scene, scene_corners[3], scene_corners[0], Scalar(255), 4 );
        
    }
    return MatToUIImage(mat_scene);
}





+(UIImage *)BRISKMatching:(UIImage *)inputScene withTemplate:(UIImage *)inputObject withRedetect:(BOOL)redetect{
    
    // Convert UIImage to Mat in grayscale
    Mat mat_scene;
    UIImageToMat(inputScene, mat_scene);
    Mat img_scene;
    cvtColor(mat_scene, img_scene, cv::COLOR_BGR2GRAY);
    
    // Detect features of the object if needed
    if(redetect && inputObject != NULL)
    {
        Mat mat_object;
        UIImageToMat(inputObject, mat_object);
        cv::resize(mat_object, img_object, img_object.size(), INTER_AREA);
        cvtColor(img_object, img_object, cv::COLOR_BGR2GRAY);
        
        detector_brisk->detectAndCompute( img_object, Mat(), keypoints_object, descriptors_object );
    }
    
    if(!descriptors_object.data)
    {
        int maxCorners = 25;
        std::vector<Point2f> corners;
        double qualityLevel = 0.01;
        double minDistance = 10;
        int blockSize = 3, gradiantSize = 3;
        bool useHarrisDetector = false;
        double k = 0.04;
        
        goodFeaturesToTrack(img_scene,
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
        { circle( mat_scene, corners[i], r, Scalar(255), -1, 8, 0 ); }
        
        return MatToUIImage(mat_scene);
    }

    std::vector<KeyPoint> keypoints_scene;
    Mat descriptors_scene;
    detector_brisk->detectAndCompute( img_scene, Mat(), keypoints_scene, descriptors_scene );
    
    if (keypoints_scene.size() < 12)
    {
        return MatToUIImage(mat_scene);
    }
    
    //std::vector< DMatch > matches;
    std::vector< DMatch > good_matches;
    
    //Matching descriptor vectors using BF with Crosscheck
    BFMatcher matcher(NORM_HAMMING, true);
    matcher.match( descriptors_object, descriptors_scene, good_matches );
    
    // Localize the object
    std::vector<Point2f> obj;
    std::vector<Point2f> scene;
    for( size_t i = 0; i < good_matches.size(); i++ )
    {
        // Get the keypoints from the good matches
        obj.push_back( keypoints_object[ good_matches[i].queryIdx ].pt );
        scene.push_back( keypoints_scene[ good_matches[i].trainIdx ].pt );
    }
    Mat H = findHomography( obj, scene, RANSAC, 6.0);
    
    // Get the corners from the object ( the object to be "detected" )
    std::vector<Point2f> obj_corners(4);
    obj_corners[0] = cvPoint(0,0);
    obj_corners[1] = cvPoint( img_object.cols, 0 );
    obj_corners[2] = cvPoint( img_object.cols, img_object.rows );
    obj_corners[3] = cvPoint( 0, img_object.rows );
    std::vector<Point2f> scene_corners(4);
    perspectiveTransform( obj_corners, scene_corners, H);
    
    if(isContourConvex(scene_corners)){
        // Draw lines between the corners ( the mapped object in the scene )
        line( mat_scene, scene_corners[0], scene_corners[1], Scalar(255), 4 );
        line( mat_scene, scene_corners[1], scene_corners[2], Scalar(255), 4 );
        line( mat_scene, scene_corners[2], scene_corners[3], Scalar(255), 4 );
        line( mat_scene, scene_corners[3], scene_corners[0], Scalar(255), 4 );
        
    }
    return MatToUIImage(mat_scene);
}



+(UIImage *)AKAZEMatching:(UIImage *)inputScene withTemplate:(UIImage *)inputObject withRedetect:(BOOL)redetect{
    
    // Convert UIImage to Mat in grayscale
    Mat mat_scene;
    UIImageToMat(inputScene, mat_scene);
    Mat img_scene;
    cvtColor(mat_scene, img_scene, cv::COLOR_BGR2GRAY);
    
    // Detect features of the object if needed
    if(redetect && inputObject != NULL)
    {
        Mat mat_object;
        UIImageToMat(inputObject, mat_object);
        cv::resize(mat_object, img_object, img_object.size(), INTER_AREA);
        cvtColor(img_object, img_object, cv::COLOR_BGR2GRAY);
        
        detector_akaze->detectAndCompute( img_object, Mat(), keypoints_object, descriptors_object );
    }
    
    if(!descriptors_object.data)
    {
        int maxCorners = 25;
        std::vector<Point2f> corners;
        double qualityLevel = 0.01;
        double minDistance = 10;
        int blockSize = 3, gradiantSize = 3;
        bool useHarrisDetector = false;
        double k = 0.04;
        
        goodFeaturesToTrack(img_scene,
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
        { circle( mat_scene, corners[i], r, Scalar(255), -1, 8, 0 ); }
        
        return MatToUIImage(mat_scene);
    }
    
    std::vector<KeyPoint> keypoints_scene;
    Mat descriptors_scene;
    detector_akaze->detectAndCompute( img_scene, Mat(), keypoints_scene, descriptors_scene );
    
    if (keypoints_scene.size() < 12)
    {
        return MatToUIImage(mat_scene);
    }
    
    //std::vector< DMatch > matches;
    std::vector< DMatch > good_matches;
    
    //Matching descriptor vectors using BF with Crosscheck
    BFMatcher matcher(NORM_HAMMING, true);
    matcher.match( descriptors_object, descriptors_scene, good_matches );
    
    // Localize the object
    std::vector<Point2f> obj;
    std::vector<Point2f> scene;
    for( size_t i = 0; i < good_matches.size(); i++ )
    {
        // Get the keypoints from the good matches
        obj.push_back( keypoints_object[ good_matches[i].queryIdx ].pt );
        scene.push_back( keypoints_scene[ good_matches[i].trainIdx ].pt );
    }
    Mat H = findHomography( obj, scene, RANSAC, 6.0);
    
    // Get the corners from the object ( the object to be "detected" )
    std::vector<Point2f> obj_corners(4);
    obj_corners[0] = cvPoint(0,0);
    obj_corners[1] = cvPoint( img_object.cols, 0 );
    obj_corners[2] = cvPoint( img_object.cols, img_object.rows );
    obj_corners[3] = cvPoint( 0, img_object.rows );
    std::vector<Point2f> scene_corners(4);
    perspectiveTransform( obj_corners, scene_corners, H);
    
    if(isContourConvex(scene_corners)){
        // Draw lines between the corners ( the mapped object in the scene )
        line( mat_scene, scene_corners[0], scene_corners[1], Scalar(255), 4 );
        line( mat_scene, scene_corners[1], scene_corners[2], Scalar(255), 4 );
        line( mat_scene, scene_corners[2], scene_corners[3], Scalar(255), 4 );
        line( mat_scene, scene_corners[3], scene_corners[0], Scalar(255), 4 );
        
    }
    return MatToUIImage(mat_scene);
}




+(UIImage *)SURFMatching:(UIImage *)inputScene withTemplate:(UIImage *)inputObject withRedetect:(BOOL)redetect{
    
    // Convert UIImage to Mat in grayscale
    Mat mat_scene;
    UIImageToMat(inputScene, mat_scene);
    Mat img_scene;
    cvtColor(mat_scene, img_scene, cv::COLOR_BGR2GRAY);
    
    // Detect features of the object if needed
    if(redetect && inputObject != NULL)
    {
        Mat mat_object;
        UIImageToMat(inputObject, mat_object);
        cv::resize(mat_object, img_object, img_object.size(), INTER_AREA);
        cvtColor(img_object, img_object, cv::COLOR_BGR2GRAY);
        
        detector_surf->detectAndCompute( img_object, Mat(), keypoints_object, descriptors_object );
    }

    if(!descriptors_object.data)
    {
        int maxCorners = 25;
        std::vector<Point2f> corners;
        double qualityLevel = 0.01;
        double minDistance = 10;
        int blockSize = 3, gradiantSize = 3;
        bool useHarrisDetector = false;
        double k = 0.04;
        
        goodFeaturesToTrack(img_scene,
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
        { circle( mat_scene, corners[i], r, Scalar(255), -1, 8, 0 ); }
        
        return MatToUIImage(mat_scene);
    }

    std::vector<KeyPoint> keypoints_scene;
    Mat descriptors_scene;
    detector_surf->detectAndCompute( img_scene, Mat(), keypoints_scene, descriptors_scene );
    
    if (keypoints_scene.size() < 12)
    {
        return MatToUIImage(mat_scene);
    }
    
    //std::vector< DMatch > matches;
    std::vector< DMatch > good_matches;
    
     //Matching descriptor vectors using BF with Crosscheck
     BFMatcher matcher(NORM_L2, true);
     matcher.match( descriptors_object, descriptors_scene, good_matches );
    
//    // Matching descriptor vectors using BF with ratio test
//    BFMatcher matcher(NORM_L2);
//    std::vector< std::vector<DMatch> > nn_matches;
//    matcher.knnMatch(descriptors_object, descriptors_scene, nn_matches, 2);
//
//    for(size_t i = 0; i < nn_matches.size(); i++) {
//        DMatch first = nn_matches[i][0];
//        float dist1 = nn_matches[i][0].distance;
//        float dist2 = nn_matches[i][1].distance;
//        if(dist1 < 0.75 * dist2) {
//            good_matches.push_back(first);
//        }
//    }

    // Localize the object
    std::vector<Point2f> obj;
    std::vector<Point2f> scene;
    for( size_t i = 0; i < good_matches.size(); i++ )
    {
        // Get the keypoints from the good matches
        obj.push_back( keypoints_object[ good_matches[i].queryIdx ].pt );
        scene.push_back( keypoints_scene[ good_matches[i].trainIdx ].pt );
    }
    Mat H = findHomography( obj, scene, RANSAC, 6.0);
    
    // Get the corners from the object ( the object to be "detected" )
    std::vector<Point2f> obj_corners(4);
    obj_corners[0] = cvPoint(0,0);
    obj_corners[1] = cvPoint( img_object.cols, 0 );
    obj_corners[2] = cvPoint( img_object.cols, img_object.rows );
    obj_corners[3] = cvPoint( 0, img_object.rows );
    std::vector<Point2f> scene_corners(4);
    perspectiveTransform( obj_corners, scene_corners, H);
    
    if(isContourConvex(scene_corners)){
        // Draw lines between the corners ( the mapped object in the scene )
        line( mat_scene, scene_corners[0], scene_corners[1], Scalar(255), 4 );
        line( mat_scene, scene_corners[1], scene_corners[2], Scalar(255), 4 );
        line( mat_scene, scene_corners[2], scene_corners[3], Scalar(255), 4 );
        line( mat_scene, scene_corners[3], scene_corners[0], Scalar(255), 4 );
        
    }
    return MatToUIImage(mat_scene);
}

@end
