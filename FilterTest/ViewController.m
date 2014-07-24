//
//  ViewController.m
//  FilterTest
//
//  Created by Zakk Hoyt on 7/23/14.
//  Copyright (c) 2014 Zakk Hoyt. All rights reserved.
//

#import "ViewController.h"
#import "GPUImage.h"
#import "JAMAccurateSlider.h"

#import "ImageViewController.h"





static NSString *SegueMainToImage = @"SegueMainToImage";

@interface ViewController () <GPUImageVideoCameraDelegate>
{
    
    
    
    BOOL faceThinking;

}

@property (nonatomic, strong) CIDetector *faceDetector;
@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
@property (nonatomic, strong) GPUImageOutput<GPUImageInput> *filter;

@property (nonatomic, strong) GPUImagePicture *sourcePicture;

@property (nonatomic, strong) GPUImageUIElement *uiElementInput;

@property (nonatomic, strong) GPUImageFilterPipeline *pipeline;
@property (nonatomic, strong) UIView *faceView;
@property (nonatomic, strong) GPUImageView *filterView;



@property (weak, nonatomic) IBOutlet UIView *gpuView;
@property (weak, nonatomic) IBOutlet JAMAccurateSlider *slider1;
@property (weak, nonatomic) IBOutlet JAMAccurateSlider *slider2;
@property (weak, nonatomic) IBOutlet JAMAccurateSlider *slider3;
@property (weak, nonatomic) IBOutlet JAMAccurateSlider *slider4;

@property (weak, nonatomic) IBOutlet UILabel *label1;
@property (weak, nonatomic) IBOutlet UILabel *label2;
@property (weak, nonatomic) IBOutlet UILabel *label3;
@property (weak, nonatomic) IBOutlet UILabel *label4;


@property (weak, nonatomic) IBOutlet UISwitch *facesSwitch;
@property (weak, nonatomic) IBOutlet UILabel *facesLabel;


@property (weak, nonatomic) IBOutlet UIButton *shutterButton;

@property (nonatomic) BOOL hasLoaded;
@end

@implementation ViewController

- (id)initWithFilterType:(GPUImageShowcaseFilterType)newFilterType;
{
    self = [super initWithNibName:@"ShowcaseFilterViewController" bundle:nil];
    if (self)
    {
        self.filterType = newFilterType;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc;
{
}

#pragma mark UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([GPUImageContext supportsFastTextureUpload])
    {
        NSDictionary *detectorOptions = [[NSDictionary alloc] initWithObjectsAndKeys:CIDetectorAccuracyLow, CIDetectorAccuracy, nil];
        self.faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
        faceThinking = NO;
    }
    

}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
//    [self setupFilter];
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    if(self.hasLoaded == NO){
        self.hasLoaded = YES;
        [self setupFilter];
    }
        
}

- (void)viewWillDisappear:(BOOL)animated
{
    // Note: I needed to stop camera capture before the view went off the screen in order to prevent a crash from the camera still sending frames
    [self.videoCamera stopCameraCapture];
    
	[super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:SegueMainToImage]){
        ImageViewController *vc = segue.destinationViewController;
        vc.image = sender;
    }
}

- (void)setupFilter;
{
    //    self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    //    self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
    //    self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1920x1080 cameraPosition:AVCaptureDevicePositionBack];
    self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    self.facesSwitch.hidden = YES;
    self.facesLabel.hidden = YES;
    BOOL needsSecondImage = NO;
    
    self.slider1.hidden = YES;
    self.slider2.hidden = YES;
    self.slider3.hidden = YES;
    self.slider4.hidden = YES;
    
    self.label1.hidden = YES;
    self.label2.hidden = YES;
    self.label3.hidden = YES;
    self.label4.hidden = YES;
    
    self.shutterButton.hidden = NO;
    self.shutterButton.alpha = 1.0;
    switch (self.filterType)
    {
        case GPUIMAGE_SEPIA:
        {
            self.title = @"Sepia Tone";
            [self setLabelsTexts:@[@"Sepia Tone"]];
            [self setSlidersValues:@[@(0), @(1.0), @(1.0)]];
            self.filter = [[GPUImageSepiaFilter alloc] init];
        }; break;
        case GPUIMAGE_PIXELLATE:
        {
            self.title = @"Pixellate";
            
            [self setLabelsTexts:@[@"Fractional Width"]];
            [self setSlidersValues:@[@(0), @(0.05), @(0.5)]];
            self.filter = [[GPUImagePixellateFilter alloc] init];
        }; break;
        case GPUIMAGE_POLARPIXELLATE:
        {
            self.title = @"Polar Pixellate";
            [self setLabelsTexts:@[@"Center", @"Pixel Size X", @"Pixel Size Y"]];
            [self setSlidersValues:@[@(-0.1), @(0.05), @(0.1),
                                     @(0.0), @(0.05), @(0.5),
                                     @(0.0), @(0.05), @(0.5)]];

            self.slider1.hidden = NO;
            
            [self.slider1 setValue:0.05];
            [self.slider1 setMinimumValue:-0.1];
            [self.slider1 setMaximumValue:0.1];
            
            self.filter = [[GPUImagePolarPixellateFilter alloc] init];
        }; break;
        case GPUIMAGE_PIXELLATE_POSITION:
        {
            self.title = @"Pixellate (position)";
            [self setLabelsTexts:@[@"Radius", @"Fractional Width of a Pixel", @"Pixel Size X", @"Pixel Size Y"]];
            [self setSlidersValues:@[@(0), @(0.25), @(0.5),
                                     @(0), @(0.05), @(0.5),
                                     @(0.0), @(0.5), @(1.0),
                                     @(0.0), @(0.5), @(1.0)]];
            self.filter = [[GPUImagePixellatePositionFilter alloc] init];
        }; break;
        case GPUIMAGE_POLKADOT:
        {
            self.title = @"Polka Dot";
            self.slider1.hidden = NO;
            
            [self.slider1 setValue:0.05];
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:0.3];
            
            self.filter = [[GPUImagePolkaDotFilter alloc] init];
        }; break;
        case GPUIMAGE_HALFTONE:
        {
            self.title = @"Halftone";
            self.slider1.hidden = NO;
            
            [self.slider1 setValue:0.01];
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:0.05];
            
            self.filter = [[GPUImageHalftoneFilter alloc] init];
        }; break;
        case GPUIMAGE_CROSSHATCH:
        {
            self.title = @"Crosshatch";
            self.slider1.hidden = NO;
            
            [self.slider1 setValue:0.03];
            [self.slider1 setMinimumValue:0.01];
            [self.slider1 setMaximumValue:0.06];
            
            self.filter = [[GPUImageCrosshatchFilter alloc] init];
        }; break;
        case GPUIMAGE_COLORINVERT:
        {
            self.title = @"Color Invert";
            self.slider1.hidden = YES;
            
            self.filter = [[GPUImageColorInvertFilter alloc] init];
        }; break;
        case GPUIMAGE_GRAYSCALE:
        {
            self.title = @"Grayscale";
            self.slider1.hidden = YES;
            
            self.filter = [[GPUImageGrayscaleFilter alloc] init];
        }; break;
        case GPUIMAGE_MONOCHROME:
        {
            self.title = @"Monochrome";
            self.slider1.hidden = NO;
            
            [self.slider1 setValue:1.0];
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:1.0];
            
            self.filter = [[GPUImageMonochromeFilter alloc] init];
            [(GPUImageMonochromeFilter *)self.filter setColor:(GPUVector4){0.0f, 0.0f, 1.0f, 1.f}];
        }; break;
        case GPUIMAGE_FALSECOLOR:
        {
            self.title = @"False Color";
            self.slider1.hidden = YES;
            
            self.filter = [[GPUImageFalseColorFilter alloc] init];
		}; break;
        case GPUIMAGE_SOFTELEGANCE:
        {
            self.title = @"Soft Elegance (Lookup)";
            self.slider1.hidden = YES;
            
            self.filter = [[GPUImageSoftEleganceFilter alloc] init];
        }; break;
        case GPUIMAGE_MISSETIKATE:
        {
            self.title = @"Miss Etikate (Lookup)";
            self.slider1.hidden = YES;
            
            self.filter = [[GPUImageMissEtikateFilter alloc] init];
        }; break;
        case GPUIMAGE_AMATORKA:
        {
            self.title = @"Amatorka (Lookup)";
            self.slider1.hidden = YES;
            
            self.filter = [[GPUImageAmatorkaFilter alloc] init];
        }; break;
            
        case GPUIMAGE_SATURATION:
        {
            self.title = @"Saturation";
            [self setLabelsTexts:@[@"Saturation"]];
            [self setSlidersValues:@[@(0.0), @(1.0), @(2.0)]];
            self.filter = [[GPUImageSaturationFilter alloc] init];
        }; break;
        case GPUIMAGE_CONTRAST:
        {
            self.title = @"Contrast";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:4.0];
            [self.slider1 setValue:1.0];
            
            self.filter = [[GPUImageContrastFilter alloc] init];
        }; break;
        case GPUIMAGE_BRIGHTNESS:
        {
            self.title = @"Brightness";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:-1.0];
            [self.slider1 setMaximumValue:1.0];
            [self.slider1 setValue:0.0];
            
            self.filter = [[GPUImageBrightnessFilter alloc] init];
        }; break;
        case GPUIMAGE_LEVELS:
        {
            self.title = @"Levels";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:1.0];
            [self.slider1 setValue:0.0];
            
            self.filter = [[GPUImageLevelsFilter alloc] init];
        }; break;
        case GPUIMAGE_RGB:
        {
            self.title = @"RGB";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:2.0];
            [self.slider1 setValue:1.0];
            
            self.filter = [[GPUImageRGBFilter alloc] init];
        }; break;
        case GPUIMAGE_HUE:
        {
            self.title = @"Hue";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:360.0];
            [self.slider1 setValue:90.0];
            
            self.filter = [[GPUImageHueFilter alloc] init];
        }; break;
        case GPUIMAGE_WHITEBALANCE:
        {
            self.title = @"White Balance";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:2500.0];
            [self.slider1 setMaximumValue:7500.0];
            [self.slider1 setValue:5000.0];
            
            self.filter = [[GPUImageWhiteBalanceFilter alloc] init];
        }; break;
        case GPUIMAGE_EXPOSURE:
        {
            self.title = @"Exposure";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:-4.0];
            [self.slider1 setMaximumValue:4.0];
            [self.slider1 setValue:0.0];
            
            self.filter = [[GPUImageExposureFilter alloc] init];
        }; break;
        case GPUIMAGE_SHARPEN:
        {
            self.title = @"Sharpen";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:-1.0];
            [self.slider1 setMaximumValue:4.0];
            [self.slider1 setValue:0.0];
            
            self.filter = [[GPUImageSharpenFilter alloc] init];
        }; break;
        case GPUIMAGE_UNSHARPMASK:
        {
            self.title = @"Unsharp Mask";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:5.0];
            [self.slider1 setValue:1.0];
            
            self.filter = [[GPUImageUnsharpMaskFilter alloc] init];
            
            //            [(GPUImageUnsharpMaskFilter *)self.filter setIntensity:3.0];
        }; break;
        case GPUIMAGE_GAMMA:
        {
            self.title = @"Gamma";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:3.0];
            [self.slider1 setValue:1.0];
            
            self.filter = [[GPUImageGammaFilter alloc] init];
        }; break;
        case GPUIMAGE_TONECURVE:
        {
            self.title = @"Tone curve";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:1.0];
            [self.slider1 setValue:0.5];
            
            self.filter = [[GPUImageToneCurveFilter alloc] init];
            [(GPUImageToneCurveFilter *)self.filter setBlueControlPoints:[NSArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(0.0, 0.0)], [NSValue valueWithCGPoint:CGPointMake(0.5, 0.5)], [NSValue valueWithCGPoint:CGPointMake(1.0, 0.75)], nil]];
        }; break;
        case GPUIMAGE_HIGHLIGHTSHADOW:
        {
            self.title = @"Highlights and Shadows";
            self.slider1.hidden = NO;
            
            [self.slider1 setValue:1.0];
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:1.0];
            
            self.filter = [[GPUImageHighlightShadowFilter alloc] init];
        }; break;
		case GPUIMAGE_HAZE:
        {
            self.title = @"Haze / UV";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:-0.2];
            [self.slider1 setMaximumValue:0.2];
            [self.slider1 setValue:0.2];
            
            self.filter = [[GPUImageHazeFilter alloc] init];
        }; break;
		case GPUIMAGE_AVERAGECOLOR:
        {
            self.title = @"Average Color";
            self.slider1.hidden = YES;
            
            self.filter = [[GPUImageAverageColor alloc] init];
        }; break;
		case GPUIMAGE_LUMINOSITY:
        {
            self.title = @"Luminosity";
            self.slider1.hidden = YES;
            
            self.filter = [[GPUImageLuminosity alloc] init];
        }; break;
		case GPUIMAGE_HISTOGRAM:
        {
            self.title = @"Histogram";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:4.0];
            [self.slider1 setMaximumValue:32.0];
            [self.slider1 setValue:16.0];
            
            self.filter = [[GPUImageHistogramFilter alloc] initWithHistogramType:kGPUImageHistogramRGB];
        }; break;
		case GPUIMAGE_THRESHOLD:
        {
            self.title = @"Luminance Threshold";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:1.0];
            [self.slider1 setValue:0.5];
            
            self.filter = [[GPUImageLuminanceThresholdFilter alloc] init];
        }; break;
		case GPUIMAGE_ADAPTIVETHRESHOLD:
        {
            self.title = @"Adaptive Threshold";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:1.0];
            [self.slider1 setMaximumValue:20.0];
            [self.slider1 setValue:1.0];
            
            self.filter = [[GPUImageAdaptiveThresholdFilter alloc] init];
        }; break;
		case GPUIMAGE_AVERAGELUMINANCETHRESHOLD:
        {
            self.title = @"Avg. Lum. Threshold";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:2.0];
            [self.slider1 setValue:1.0];
            
            self.filter = [[GPUImageAverageLuminanceThresholdFilter alloc] init];
        }; break;
        case GPUIMAGE_CROP:
        {
            self.title = @"Crop";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.2];
            [self.slider1 setMaximumValue:1.0];
            [self.slider1 setValue:0.5];
            
            self.filter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.0, 0.0, 1.0, 0.25)];
        }; break;
		case GPUIMAGE_MASK:
		{
            self.title = @"Mask";
            self.slider1.hidden = YES;
            needsSecondImage = YES;
            
            self.filter = [[GPUImageMaskFilter alloc] init];
			
			[(GPUImageFilter*)self.filter setBackgroundColorRed:0.0 green:1.0 blue:0.0 alpha:1.0];
        }; break;
        case GPUIMAGE_TRANSFORM:
        {
            self.title = @"Transform (2-D)";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:6.28];
            [self.slider1 setValue:2.0];
            
            self.filter = [[GPUImageTransformFilter alloc] init];
            [(GPUImageTransformFilter *)self.filter setAffineTransform:CGAffineTransformMakeRotation(2.0)];
            //            [(GPUImageTransformFilter *)self.filter setIgnoreAspectRatio:YES];
        }; break;
        case GPUIMAGE_TRANSFORM3D:
        {
            self.title = @"Transform (3-D)";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:6.28];
            [self.slider1 setValue:0.75];
            
            self.slider2.hidden = NO;
            
            [self.slider2 setMinimumValue:0.0];
            [self.slider2 setMaximumValue:6.28];
            [self.slider2 setValue:0.75];
            
            
            
            
            self.filter = [[GPUImageTransformFilter alloc] init];
            CATransform3D perspectiveTransform = CATransform3DIdentity;
            perspectiveTransform.m34 = 0.4;
            perspectiveTransform.m33 = 0.4;
            perspectiveTransform = CATransform3DScale(perspectiveTransform, 0.75, 0.75, 0.75);
            perspectiveTransform = CATransform3DRotate(perspectiveTransform, 0.75, 0.0, 1.0, 0.0);
            
            [(GPUImageTransformFilter *)self.filter setTransform3D:perspectiveTransform];
		}; break;
        case GPUIMAGE_SOBELEDGEDETECTION:
        {
            self.title = @"Sobel Edge Detection";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:1.0];
            [self.slider1 setValue:0.25];
            
            self.filter = [[GPUImageSobelEdgeDetectionFilter alloc] init];
        }; break;
        case GPUIMAGE_XYGRADIENT:
        {
            self.title = @"XY Derivative";
            self.slider1.hidden = YES;
            
            self.filter = [[GPUImageXYDerivativeFilter alloc] init];
        }; break;
        case GPUIMAGE_HARRISCORNERDETECTION:
        {
            self.title = @"Harris Corner Detection";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.01];
            [self.slider1 setMaximumValue:0.70];
            [self.slider1 setValue:0.20];
            
            self.filter = [[GPUImageHarrisCornerDetectionFilter alloc] init];
            [(GPUImageHarrisCornerDetectionFilter *)self.filter setThreshold:0.20];
        }; break;
        case GPUIMAGE_NOBLECORNERDETECTION:
        {
            self.title = @"Noble Corner Detection";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.01];
            [self.slider1 setMaximumValue:0.70];
            [self.slider1 setValue:0.20];
            
            self.filter = [[GPUImageNobleCornerDetectionFilter alloc] init];
            [(GPUImageNobleCornerDetectionFilter *)self.filter setThreshold:0.20];
        }; break;
        case GPUIMAGE_SHITOMASIFEATUREDETECTION:
        {
            self.title = @"Shi-Tomasi Feature Detection";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.01];
            [self.slider1 setMaximumValue:0.70];
            [self.slider1 setValue:0.20];
            
            self.filter = [[GPUImageShiTomasiFeatureDetectionFilter alloc] init];
            [(GPUImageShiTomasiFeatureDetectionFilter *)self.filter setThreshold:0.20];
        }; break;
        case GPUIMAGE_HOUGHTRANSFORMLINEDETECTOR:
        {
            self.title = @"Line Detection";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.2];
            [self.slider1 setMaximumValue:1.0];
            [self.slider1 setValue:0.6];
            
            self.filter = [[GPUImageHoughTransformLineDetector alloc] init];
            [(GPUImageHoughTransformLineDetector *)self.filter setLineDetectionThreshold:0.60];
        }; break;
            
        case GPUIMAGE_PREWITTEDGEDETECTION:
        {
            self.title = @"Prewitt Edge Detection";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:1.0];
            [self.slider1 setValue:1.0];
            
            self.filter = [[GPUImagePrewittEdgeDetectionFilter alloc] init];
        }; break;
        case GPUIMAGE_CANNYEDGEDETECTION:
        {
            self.title = @"Canny Edge Detection";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:1.0];
            [self.slider1 setValue:1.0];
            
            self.filter = [[GPUImageCannyEdgeDetectionFilter alloc] init];
        }; break;
        case GPUIMAGE_THRESHOLDEDGEDETECTION:
        {
            self.title = @"Threshold Edge Detection";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:1.0];
            [self.slider1 setValue:0.25];
            
            self.filter = [[GPUImageThresholdEdgeDetectionFilter alloc] init];
        }; break;
        case GPUIMAGE_LOCALBINARYPATTERN:
        {
            self.title = @"Local Binary Pattern";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:1.0];
            [self.slider1 setMaximumValue:5.0];
            [self.slider1 setValue:1.0];
            
            self.filter = [[GPUImageLocalBinaryPatternFilter alloc] init];
        }; break;
        case GPUIMAGE_BUFFER:
        {
            self.title = @"Image Buffer";
            self.slider1.hidden = YES;
            
            self.filter = [[GPUImageBuffer alloc] init];
        }; break;
        case GPUIMAGE_LOWPASS:
        {
            self.title = @"Low Pass";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:1.0];
            [self.slider1 setValue:0.5];
            
            self.filter = [[GPUImageLowPassFilter alloc] init];
        }; break;
        case GPUIMAGE_HIGHPASS:
        {
            self.title = @"High Pass";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:1.0];
            [self.slider1 setValue:0.5];
            
            self.filter = [[GPUImageHighPassFilter alloc] init];
        }; break;
        case GPUIMAGE_MOTIONDETECTOR:
        {
            [self.videoCamera rotateCamera];
            
            self.title = @"Motion Detector";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:1.0];
            [self.slider1 setValue:0.5];
            
            self.filter = [[GPUImageMotionDetector alloc] init];
        }; break;
        case GPUIMAGE_SKETCH:
        {
            self.title = @"Sketch";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:1.0];
            [self.slider1 setValue:0.25];
            
            self.filter = [[GPUImageSketchFilter alloc] init];
        }; break;
        case GPUIMAGE_THRESHOLDSKETCH:
        {
            self.title = @"Threshold Sketch";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:1.0];
            [self.slider1 setValue:0.25];
            
            self.filter = [[GPUImageThresholdSketchFilter alloc] init];
        }; break;
        case GPUIMAGE_TOON:
        {
            self.title = @"Toon";
            self.slider1.hidden = YES;
            
            self.filter = [[GPUImageToonFilter alloc] init];
        }; break;
        case GPUIMAGE_SMOOTHTOON:
        {
            self.title = @"Smooth Toon";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:1.0];
            [self.slider1 setMaximumValue:6.0];
            [self.slider1 setValue:1.0];
            
            self.filter = [[GPUImageSmoothToonFilter alloc] init];
        }; break;
        case GPUIMAGE_TILTSHIFT:
        {
            self.title = @"Tilt Shift";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.2];
            [self.slider1 setMaximumValue:0.8];
            [self.slider1 setValue:0.5];
            
            self.filter = [[GPUImageTiltShiftFilter alloc] init];
            [(GPUImageTiltShiftFilter *)self.filter setTopFocusLevel:0.4];
            [(GPUImageTiltShiftFilter *)self.filter setBottomFocusLevel:0.6];
            [(GPUImageTiltShiftFilter *)self.filter setFocusFallOffRate:0.2];
        }; break;
        case GPUIMAGE_CGA:
        {
            self.title = @"CGA Colorspace";
            self.slider1.hidden = YES;
            
            self.filter = [[GPUImageCGAColorspaceFilter alloc] init];
        }; break;
        case GPUIMAGE_CONVOLUTION:
        {
            self.title = @"3x3 Convolution";
            self.slider1.hidden = YES;
            
            self.filter = [[GPUImage3x3ConvolutionFilter alloc] init];
            //            [(GPUImage3x3ConvolutionFilter *)self.filter setConvolutionKernel:(GPUMatrix3x3){
            //                {-2.0f, -1.0f, 0.0f},
            //                {-1.0f,  1.0f, 1.0f},
            //                { 0.0f,  1.0f, 2.0f}
            //            }];
            [(GPUImage3x3ConvolutionFilter *)self.filter setConvolutionKernel:(GPUMatrix3x3){
                {-1.0f,  0.0f, 1.0f},
                {-2.0f, 0.0f, 2.0f},
                {-1.0f,  0.0f, 1.0f}
            }];
            
            //            [(GPUImage3x3ConvolutionFilter *)self.filter setConvolutionKernel:(GPUMatrix3x3){
            //                {1.0f,  1.0f, 1.0f},
            //                {1.0f, -8.0f, 1.0f},
            //                {1.0f,  1.0f, 1.0f}
            //            }];
            //            [(GPUImage3x3ConvolutionFilter *)self.filter setConvolutionKernel:(GPUMatrix3x3){
            //                { 0.11f,  0.11f, 0.11f},
            //                { 0.11f,  0.11f, 0.11f},
            //                { 0.11f,  0.11f, 0.11f}
            //            }];
        }; break;
        case GPUIMAGE_EMBOSS:
        {
            self.title = @"Emboss";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:5.0];
            [self.slider1 setValue:1.0];
            
            self.filter = [[GPUImageEmbossFilter alloc] init];
        }; break;
        case GPUIMAGE_LAPLACIAN:
        {
            self.title = @"Laplacian";
            self.slider1.hidden = YES;
            
            self.filter = [[GPUImageLaplacianFilter alloc] init];
        }; break;
        case GPUIMAGE_POSTERIZE:
        {
            self.title = @"Posterize";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:1.0];
            [self.slider1 setMaximumValue:20.0];
            [self.slider1 setValue:10.0];
            
            self.filter = [[GPUImagePosterizeFilter alloc] init];
        }; break;
        case GPUIMAGE_SWIRL:
        {
            self.title = @"Swirl";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:2.0];
            [self.slider1 setValue:1.0];
            
            self.filter = [[GPUImageSwirlFilter alloc] init];
        }; break;
        case GPUIMAGE_BULGE:
        {
            self.title = @"Bulge";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:-1.0];
            [self.slider1 setMaximumValue:1.0];
            [self.slider1 setValue:0.5];
            
            self.filter = [[GPUImageBulgeDistortionFilter alloc] init];
        }; break;
        case GPUIMAGE_SPHEREREFRACTION:
        {
            self.title = @"Sphere Refraction";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:1.0];
            [self.slider1 setValue:0.15];
            
            self.filter = [[GPUImageSphereRefractionFilter alloc] init];
            [(GPUImageSphereRefractionFilter *)self.filter setRadius:0.15];
        }; break;
        case GPUIMAGE_GLASSSPHERE:
        {
            self.title = @"Glass Sphere";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:1.0];
            [self.slider1 setValue:0.15];
            
            self.filter = [[GPUImageGlassSphereFilter alloc] init];
            [(GPUImageGlassSphereFilter *)self.filter setRadius:0.15];
        }; break;
        case GPUIMAGE_PINCH:
        {
            self.title = @"Pinch";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:-2.0];
            [self.slider1 setMaximumValue:2.0];
            [self.slider1 setValue:0.5];
            
            self.filter = [[GPUImagePinchDistortionFilter alloc] init];
        }; break;
        case GPUIMAGE_STRETCH:
        {
            self.title = @"Stretch";
            self.slider1.hidden = YES;
            
            self.filter = [[GPUImageStretchDistortionFilter alloc] init];
        }; break;
        case GPUIMAGE_DILATION:
        {
            self.title = @"Dilation";
            self.slider1.hidden = YES;
            
            self.filter = [[GPUImageRGBDilationFilter alloc] initWithRadius:4];
		}; break;
        case GPUIMAGE_EROSION:
        {
            self.title = @"Erosion";
            self.slider1.hidden = YES;
            
            self.filter = [[GPUImageRGBErosionFilter alloc] initWithRadius:4];
		}; break;
        case GPUIMAGE_OPENING:
        {
            self.title = @"Opening";
            self.slider1.hidden = YES;
            
            self.filter = [[GPUImageRGBOpeningFilter alloc] initWithRadius:4];
		}; break;
        case GPUIMAGE_CLOSING:
        {
            self.title = @"Closing";
            self.slider1.hidden = YES;
            
            self.filter = [[GPUImageRGBClosingFilter alloc] initWithRadius:4];
		}; break;
            
        case GPUIMAGE_PERLINNOISE:
        {
            self.title = @"Perlin Noise";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:1.0];
            [self.slider1 setMaximumValue:30.0];
            [self.slider1 setValue:8.0];
            
            self.filter = [[GPUImagePerlinNoiseFilter alloc] init];
        }; break;
        case GPUIMAGE_VORONOI:
        {
            self.title = @"Voronoi";
            self.slider1.hidden = YES;
            
            GPUImageJFAVoronoiFilter *jfa = [[GPUImageJFAVoronoiFilter alloc] init];
            [jfa setSizeInPixels:CGSizeMake(1024.0, 1024.0)];
            
            self.sourcePicture = [[GPUImagePicture alloc] initWithImage:[UIImage imageNamed:@"voroni_points2.png"]];
            
            [self.sourcePicture addTarget:jfa];
            
            self.filter = [[GPUImageVoronoiConsumerFilter alloc] init];
            
            [jfa setSizeInPixels:CGSizeMake(1024.0, 1024.0)];
            [(GPUImageVoronoiConsumerFilter *)self.filter setSizeInPixels:CGSizeMake(1024.0, 1024.0)];
            
            [self.videoCamera addTarget:self.filter];
            [jfa addTarget:self.filter];
            [self.sourcePicture processImage];
        }; break;
        case GPUIMAGE_MOSAIC:
        {
            self.title = @"Mosaic";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.002];
            [self.slider1 setMaximumValue:0.05];
            [self.slider1 setValue:0.025];
            
            self.filter = [[GPUImageMosaicFilter alloc] init];
            [(GPUImageMosaicFilter *)self.filter setTileSet:@"squares.png"];
            [(GPUImageMosaicFilter *)self.filter setColorOn:NO];
            //[(GPUImageMosaicFilter *)self.filter setTileSet:@"dotletterstiles.png"];
            //[(GPUImageMosaicFilter *)self.filter setTileSet:@"curvies.png"];
            
            [self.filter setInputRotation:kGPUImageRotateRight atIndex:0];
            
        }; break;
        case GPUIMAGE_CHROMAKEY:
        {
            self.title = @"Chroma Key (Green)";
            self.slider1.hidden = NO;
            needsSecondImage = YES;
            
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:1.0];
            [self.slider1 setValue:0.4];
            
            self.filter = [[GPUImageChromaKeyBlendFilter alloc] init];
            [(GPUImageChromaKeyBlendFilter *)self.filter setColorToReplaceRed:0.0 green:1.0 blue:0.0];
        }; break;
        case GPUIMAGE_CHROMAKEYNONBLEND:
        {
            self.title = @"Chroma Key (Green)";
            self.slider1.hidden = NO;
            needsSecondImage = YES;
            
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:1.0];
            [self.slider1 setValue:0.4];
            
            self.filter = [[GPUImageChromaKeyFilter alloc] init];
            [(GPUImageChromaKeyFilter *)self.filter setColorToReplaceRed:0.0 green:1.0 blue:0.0];
        }; break;
        case GPUIMAGE_ADD:
        {
            self.title = @"Add Blend";
            self.slider1.hidden = YES;
            needsSecondImage = YES;
            
            self.filter = [[GPUImageAddBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_DIVIDE:
        {
            self.title = @"Divide Blend";
            self.slider1.hidden = YES;
            needsSecondImage = YES;
            
            self.filter = [[GPUImageDivideBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_MULTIPLY:
        {
            self.title = @"Multiply Blend";
            self.slider1.hidden = YES;
            needsSecondImage = YES;
            
            self.filter = [[GPUImageMultiplyBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_OVERLAY:
        {
            self.title = @"Overlay Blend";
            self.slider1.hidden = YES;
            needsSecondImage = YES;
            
            self.filter = [[GPUImageOverlayBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_LIGHTEN:
        {
            self.title = @"Lighten Blend";
            self.slider1.hidden = YES;
            needsSecondImage = YES;
            
            self.filter = [[GPUImageLightenBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_DARKEN:
        {
            self.title = @"Darken Blend";
            self.slider1.hidden = YES;
            
            needsSecondImage = YES;
            self.filter = [[GPUImageDarkenBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_DISSOLVE:
        {
            self.title = @"Dissolve Blend";
            self.slider1.hidden = NO;
            needsSecondImage = YES;
            
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:1.0];
            [self.slider1 setValue:0.5];
            
            self.filter = [[GPUImageDissolveBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_SCREENBLEND:
        {
            self.title = @"Screen Blend";
            self.slider1.hidden = YES;
            needsSecondImage = YES;
            
            self.filter = [[GPUImageScreenBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_COLORBURN:
        {
            self.title = @"Color Burn Blend";
            self.slider1.hidden = YES;
            needsSecondImage = YES;
            
            self.filter = [[GPUImageColorBurnBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_COLORDODGE:
        {
            self.title = @"Color Dodge Blend";
            self.slider1.hidden = YES;
            needsSecondImage = YES;
            
            self.filter = [[GPUImageColorDodgeBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_LINEARBURN:
        {
            self.title = @"Linear Burn Blend";
            self.slider1.hidden = YES;
            needsSecondImage = YES;
            
            self.filter = [[GPUImageLinearBurnBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_EXCLUSIONBLEND:
        {
            self.title = @"Exclusion Blend";
            self.slider1.hidden = YES;
            needsSecondImage = YES;
            
            self.filter = [[GPUImageExclusionBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_DIFFERENCEBLEND:
        {
            self.title = @"Difference Blend";
            self.slider1.hidden = YES;
            needsSecondImage = YES;
            
            self.filter = [[GPUImageDifferenceBlendFilter alloc] init];
        }; break;
		case GPUIMAGE_SUBTRACTBLEND:
        {
            self.title = @"Subtract Blend";
            self.slider1.hidden = YES;
            needsSecondImage = YES;
            
            self.filter = [[GPUImageSubtractBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_HARDLIGHTBLEND:
        {
            self.title = @"Hard Light Blend";
            self.slider1.hidden = YES;
            needsSecondImage = YES;
            
            self.filter = [[GPUImageHardLightBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_SOFTLIGHTBLEND:
        {
            self.title = @"Soft Light Blend";
            self.slider1.hidden = YES;
            needsSecondImage = YES;
            
            self.filter = [[GPUImageSoftLightBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_COLORBLEND:
        {
            self.title = @"Color Blend";
            self.slider1.hidden = YES;
            needsSecondImage = YES;
            
            self.filter = [[GPUImageColorBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_HUEBLEND:
        {
            self.title = @"Hue Blend";
            self.slider1.hidden = YES;
            needsSecondImage = YES;
            
            self.filter = [[GPUImageHueBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_SATURATIONBLEND:
        {
            self.title = @"Saturation Blend";
            self.slider1.hidden = YES;
            needsSecondImage = YES;
            
            self.filter = [[GPUImageSaturationBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_LUMINOSITYBLEND:
        {
            self.title = @"Luminosity Blend";
            self.slider1.hidden = YES;
            needsSecondImage = YES;
            
            self.filter = [[GPUImageLuminosityBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_NORMALBLEND:
        {
            self.title = @"Normal Blend";
            self.slider1.hidden = YES;
            needsSecondImage = YES;
            
            self.filter = [[GPUImageNormalBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_POISSONBLEND:
        {
            self.title = @"Poisson Blend";
            self.slider1.hidden = NO;
            needsSecondImage = YES;
            
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:1.0];
            [self.slider1 setValue:0.5];
            
            self.filter = [[GPUImagePoissonBlendFilter alloc] init];
        }; break;
        case GPUIMAGE_OPACITY:
        {
            self.title = @"Opacity Adjustment";
            self.slider1.hidden = NO;
            needsSecondImage = YES;
            
            [self.slider1 setValue:1.0];
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:1.0];
            
            self.filter = [[GPUImageOpacityFilter alloc] init];
        }; break;
        case GPUIMAGE_CUSTOM:
        {
            self.title = @"Custom";
            self.slider1.hidden = YES;
            
            self.filter = [[GPUImageFilter alloc] initWithFragmentShaderFromFile:@"CustomFilter"];
        }; break;
        case GPUIMAGE_KUWAHARA:
        {
            self.title = @"Kuwahara";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:3.0];
            [self.slider1 setMaximumValue:8.0];
            [self.slider1 setValue:3.0];
            
            self.filter = [[GPUImageKuwaharaFilter alloc] init];
        }; break;
        case GPUIMAGE_KUWAHARARADIUS3:
        {
            self.title = @"Kuwahara (Radius 3)";
            self.slider1.hidden = YES;
            
            self.filter = [[GPUImageKuwaharaRadius3Filter alloc] init];
        }; break;
        case GPUIMAGE_VIGNETTE:
        {
            self.title = @"Vignette";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.5];
            [self.slider1 setMaximumValue:0.9];
            [self.slider1 setValue:0.75];
            
            self.filter = [[GPUImageVignetteFilter alloc] init];
        }; break;
        case GPUIMAGE_GAUSSIAN:
        {
            self.title = @"Gaussian Blur";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:24.0];
            [self.slider1 setValue:2.0];
            
            self.filter = [[GPUImageGaussianBlurFilter alloc] init];
        }; break;
        case GPUIMAGE_BOXBLUR:
        {
            self.title = @"Box Blur";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:24.0];
            [self.slider1 setValue:2.0];
            
            self.filter = [[GPUImageBoxBlurFilter alloc] init];
		}; break;
        case GPUIMAGE_MEDIAN:
        {
            self.title = @"Median";
            self.slider1.hidden = YES;
            
            self.filter = [[GPUImageMedianFilter alloc] init];
		}; break;
        case GPUIMAGE_MOTIONBLUR:
        {
            self.title = @"Motion Blur";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:180.0f];
            [self.slider1 setValue:0.0];
            
            self.filter = [[GPUImageMotionBlurFilter alloc] init];
        }; break;
        case GPUIMAGE_ZOOMBLUR:
        {
            self.title = @"Zoom Blur";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:2.5f];
            [self.slider1 setValue:1.0];
            
            self.filter = [[GPUImageZoomBlurFilter alloc] init];
        }; break;
        case GPUIMAGE_IOSBLUR:
        {
            self.title = @"iOS 7 Blur";
            self.slider1.hidden = YES;
            
            self.filter = [[GPUImageiOSBlurFilter alloc] init];
        }; break;
        case GPUIMAGE_UIELEMENT:
        {
            self.title = @"UI Element";
            self.slider1.hidden = YES;
            
            self.filter = [[GPUImageSepiaFilter alloc] init];
		}; break;
        case GPUIMAGE_GAUSSIAN_SELECTIVE:
        {
            self.title = @"Selective Blur";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:.75f];
            [self.slider1 setValue:40.0/320.0];
            
            self.filter = [[GPUImageGaussianSelectiveBlurFilter alloc] init];
            [(GPUImageGaussianSelectiveBlurFilter*)self.filter setExcludeCircleRadius:40.0/320.0];
        }; break;
        case GPUIMAGE_GAUSSIAN_POSITION:
        {
            self.title = @"Selective Blur";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:.75f];
            [self.slider1 setValue:40.0/320.0];
            
            self.filter = [[GPUImageGaussianBlurPositionFilter alloc] init];
            [(GPUImageGaussianBlurPositionFilter*)self.filter setBlurRadius:40.0/320.0];
        }; break;
        case GPUIMAGE_BILATERAL:
        {
            self.title = @"Bilateral Blur";
            self.slider1.hidden = NO;
            
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:10.0];
            [self.slider1 setValue:1.0];
            
            self.filter = [[GPUImageBilateralFilter alloc] init];
        }; break;
        case GPUIMAGE_FILTERGROUP:
        {
            self.title = @"Filter Group";
            self.slider1.hidden = NO;
            
            [self.slider1 setValue:0.05];
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:0.3];
            
            self.filter = [[GPUImageFilterGroup alloc] init];
            
            GPUImageSepiaFilter *sepiaFilter = [[GPUImageSepiaFilter alloc] init];
            [(GPUImageFilterGroup *)self.filter addFilter:sepiaFilter];
            
            GPUImagePixellateFilter *pixellateFilter = [[GPUImagePixellateFilter alloc] init];
            [(GPUImageFilterGroup *)self.filter addFilter:pixellateFilter];
            
            [sepiaFilter addTarget:pixellateFilter];
            [(GPUImageFilterGroup *)self.filter setInitialFilters:[NSArray arrayWithObject:sepiaFilter]];
            [(GPUImageFilterGroup *)self.filter setTerminalFilter:pixellateFilter];
        }; break;
            
        case GPUIMAGE_FACES:
        {
            self.facesSwitch.hidden = NO;
            self.facesLabel.hidden = NO;
            
            [self.videoCamera rotateCamera];
            self.title = @"Face Detection";
            self.slider1.hidden = YES;
            
            [self.slider1 setValue:1.0];
            [self.slider1 setMinimumValue:0.0];
            [self.slider1 setMaximumValue:2.0];
            
            self.filter = [[GPUImageSaturationFilter alloc] init];
            [self.videoCamera setDelegate:self];
            break;
        }
            
        default: self.filter = [[GPUImageSepiaFilter alloc] init]; break;
    }
    
    if (self.filterType == GPUIMAGE_FILECONFIG)
    {
        self.title = @"File Configuration";
        self.pipeline = [[GPUImageFilterPipeline alloc] initWithConfigurationFile:[[NSBundle mainBundle] URLForResource:@"SampleConfiguration" withExtension:@"plist"]
                                                                       input:self.videoCamera output:(GPUImageView*)self.view];
        
        //        [pipeline addFilter:rotationFilter atIndex:0];
    }
    else
    {
        
        if (self.filterType != GPUIMAGE_VORONOI)
        {
            [self.videoCamera addTarget:self.filter];
        }
        
//        self.videoCamera.runBenchmark = YES;
        CGRect frame = self.gpuView.frame;
        NSLog(@"%@", NSStringFromCGRect(frame));
        self.filterView = [[GPUImageView alloc]initWithFrame:self.view.bounds];
        [self.gpuView addSubview:self.filterView];
        
        [self.gpuView bringSubviewToFront:self.label1];
        [self.gpuView bringSubviewToFront:self.label2];
        [self.gpuView bringSubviewToFront:self.label3];
        [self.gpuView bringSubviewToFront:self.label4];
        
        [self.gpuView bringSubviewToFront:self.slider1];
        [self.gpuView bringSubviewToFront:self.slider2];
        [self.gpuView bringSubviewToFront:self.slider3];
        [self.gpuView bringSubviewToFront:self.slider4];
        
        [self.gpuView bringSubviewToFront:self.shutterButton];
        [self.gpuView bringSubviewToFront:self.facesLabel];
        [self.gpuView bringSubviewToFront:self.facesSwitch];
        
        if (needsSecondImage)
        {
			UIImage *inputImage;
			
			if (self.filterType == GPUIMAGE_MASK)
			{
				inputImage = [UIImage imageNamed:@"mask"];
			}
            /*
             else if (self.filterType == GPUIMAGE_VORONOI) {
             inputImage = [UIImage imageNamed:@"voroni_points.png"];
             }*/
            else {
				// The picture is only used for two-image blend self.filters
				inputImage = [UIImage imageNamed:@"WID-small.jpg"];
			}
			
            //            sourcePicture = [[GPUImagePicture alloc] initWithImage:inputImage smoothlyScaleOutput:NO];
            self.sourcePicture = [[GPUImagePicture alloc] initWithImage:inputImage smoothlyScaleOutput:YES];
            [self.sourcePicture processImage];
            [self.sourcePicture addTarget:self.filter];
        }
        
        
        if (self.filterType == GPUIMAGE_HISTOGRAM)
        {
            // I'm adding an intermediary self.filter because glReadPixels() requires something to be rendered for its glReadPixels() operation to work
            [self.videoCamera removeTarget:self.filter];
            GPUImageGammaFilter *gammaFilter = [[GPUImageGammaFilter alloc] init];
            [self.videoCamera addTarget:gammaFilter];
            [gammaFilter addTarget:self.filter];
            
            GPUImageHistogramGenerator *histogramGraph = [[GPUImageHistogramGenerator alloc] init];
            
            [histogramGraph forceProcessingAtSize:CGSizeMake(256.0, 330.0)];
            [self.filter addTarget:histogramGraph];
            
            GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
            blendFilter.mix = 0.75;
            [blendFilter forceProcessingAtSize:CGSizeMake(256.0, 330.0)];
            
            [self.videoCamera addTarget:blendFilter];
            [histogramGraph addTarget:blendFilter];
            
            [blendFilter addTarget:self.filterView];
        }
        else if ( (self.filterType == GPUIMAGE_HARRISCORNERDETECTION) || (self.filterType == GPUIMAGE_NOBLECORNERDETECTION) || (self.filterType == GPUIMAGE_SHITOMASIFEATUREDETECTION) )
        {
            GPUImageCrosshairGenerator *crosshairGenerator = [[GPUImageCrosshairGenerator alloc] init];
            crosshairGenerator.crosshairWidth = 15.0;
            [crosshairGenerator forceProcessingAtSize:CGSizeMake(480.0, 640.0)];
            
            [(GPUImageHarrisCornerDetectionFilter *)self.filter setCornersDetectedBlock:^(GLfloat* cornerArray, NSUInteger cornersDetected, CMTime frameTime) {
                [crosshairGenerator renderCrosshairsFromArray:cornerArray count:cornersDetected frameTime:frameTime];
            }];
            
            GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
            [blendFilter forceProcessingAtSize:CGSizeMake(480.0, 640.0)];
            GPUImageGammaFilter *gammaFilter = [[GPUImageGammaFilter alloc] init];
            [self.videoCamera addTarget:gammaFilter];
            [gammaFilter addTarget:blendFilter];
            
            [crosshairGenerator addTarget:blendFilter];
            
            [blendFilter addTarget:self.filterView];
        }
        else if (self.filterType == GPUIMAGE_HOUGHTRANSFORMLINEDETECTOR)
        {
            GPUImageLineGenerator *lineGenerator = [[GPUImageLineGenerator alloc] init];
            //            lineGenerator.crosshairWidth = 15.0;
            [lineGenerator forceProcessingAtSize:CGSizeMake(480.0, 640.0)];
            [lineGenerator setLineColorRed:1.0 green:0.0 blue:0.0];
            [(GPUImageHoughTransformLineDetector *)self.filter setLinesDetectedBlock:^(GLfloat* lineArray, NSUInteger linesDetected, CMTime frameTime){
                [lineGenerator renderLinesFromArray:lineArray count:linesDetected frameTime:frameTime];
            }];
            
            GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
            [blendFilter forceProcessingAtSize:CGSizeMake(480.0, 640.0)];
            GPUImageGammaFilter *gammaFilter = [[GPUImageGammaFilter alloc] init];
            [self.videoCamera addTarget:gammaFilter];
            [gammaFilter addTarget:blendFilter];
            
            [lineGenerator addTarget:blendFilter];
            
            [blendFilter addTarget:self.filterView];
        }
        else if (self.filterType == GPUIMAGE_UIELEMENT)
        {
            GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
            blendFilter.mix = 1.0;
            
            NSDate *startTime = [NSDate date];
            
            UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 240.0f, 320.0f)];
            timeLabel.font = [UIFont systemFontOfSize:17.0f];
            timeLabel.text = @"Time: 0.0 s";
            timeLabel.textAlignment = NSTextAlignmentCenter;
            timeLabel.backgroundColor = [UIColor clearColor];
            timeLabel.textColor = [UIColor whiteColor];
            
            self.uiElementInput = [[GPUImageUIElement alloc] initWithView:timeLabel];
            
            [self.filter addTarget:blendFilter];
            [self.uiElementInput addTarget:blendFilter];
            
            [blendFilter addTarget:self.filterView];
            
            __unsafe_unretained GPUImageUIElement *weakUIElementInput = self.uiElementInput;
            
            [self.filter setFrameProcessingCompletionBlock:^(GPUImageOutput * filter, CMTime frameTime){
                timeLabel.text = [NSString stringWithFormat:@"Time: %f s", -[startTime timeIntervalSinceNow]];
                [weakUIElementInput update];
            }];
        }
        else if (self.filterType == GPUIMAGE_BUFFER)
        {
            GPUImageDifferenceBlendFilter *blendFilter = [[GPUImageDifferenceBlendFilter alloc] init];
            
            [self.videoCamera removeTarget:self.filter];
            
            GPUImageGammaFilter *gammaFilter = [[GPUImageGammaFilter alloc] init];
            [self.videoCamera addTarget:gammaFilter];
            [gammaFilter addTarget:blendFilter];
            [self.videoCamera addTarget:self.filter];
            
            [self.filter addTarget:blendFilter];
            
            [blendFilter addTarget:self.filterView];
        }
        else if ( (self.filterType == GPUIMAGE_OPACITY) || (self.filterType == GPUIMAGE_CHROMAKEYNONBLEND) )
        {
            [self.sourcePicture removeTarget:self.filter];
            [self.videoCamera removeTarget:self.filter];
            [self.videoCamera addTarget:self.filter];
            
            GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
            blendFilter.mix = 1.0;
            [self.sourcePicture addTarget:blendFilter];
            [self.filter addTarget:blendFilter];
            
            [blendFilter addTarget:self.filterView];
        }
        else if ( (self.filterType == GPUIMAGE_SPHEREREFRACTION) || (self.filterType == GPUIMAGE_GLASSSPHERE) )
        {
            // Provide a blurred image for a cool-looking background
            GPUImageGaussianBlurFilter *gaussianBlur = [[GPUImageGaussianBlurFilter alloc] init];
            [self.videoCamera addTarget:gaussianBlur];
            gaussianBlur.blurRadiusInPixels = 5.0;
            
            GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
            blendFilter.mix = 1.0;
            [gaussianBlur addTarget:blendFilter];
            [self.filter addTarget:blendFilter];
            
            [blendFilter addTarget:self.filterView];
            
        }
        else if (self.filterType == GPUIMAGE_AVERAGECOLOR)
        {
            GPUImageSolidColorGenerator *colorGenerator = [[GPUImageSolidColorGenerator alloc] init];
            [colorGenerator forceProcessingAtSize:[self.filterView sizeInPixels]];
            
            [(GPUImageAverageColor *)self.filter setColorAverageProcessingFinishedBlock:^(CGFloat redComponent, CGFloat greenComponent, CGFloat blueComponent, CGFloat alphaComponent, CMTime frameTime) {
                [colorGenerator setColorRed:redComponent green:greenComponent blue:blueComponent alpha:alphaComponent];
                //                NSLog(@"Average color: %f, %f, %f, %f", redComponent, greenComponent, blueComponent, alphaComponent);
            }];
            
            [colorGenerator addTarget:self.filterView];
        }
        else if (self.filterType == GPUIMAGE_LUMINOSITY)
        {
            GPUImageSolidColorGenerator *colorGenerator = [[GPUImageSolidColorGenerator alloc] init];
            [colorGenerator forceProcessingAtSize:[self.filterView sizeInPixels]];
            
            [(GPUImageLuminosity *)self.filter setLuminosityProcessingFinishedBlock:^(CGFloat luminosity, CMTime frameTime) {
                [colorGenerator setColorRed:luminosity green:luminosity blue:luminosity alpha:1.0];
            }];
            
            [colorGenerator addTarget:self.filterView];
        }
        else if (self.filterType == GPUIMAGE_IOSBLUR)
        {
            [self.videoCamera removeAllTargets];
            [self.videoCamera addTarget:self.filterView];
            GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc] init];
            cropFilter.cropRegion = CGRectMake(0.0, 0.5, 1.0, 0.5);
            [self.videoCamera addTarget:cropFilter];
            [cropFilter addTarget:self.filter];
            
            CGRect currentViewFrame = self.filterView.bounds;
            GPUImageView *blurOverlayView = [[GPUImageView alloc] initWithFrame:CGRectMake(0.0, round(currentViewFrame.size.height / 2.0), currentViewFrame.size.width, currentViewFrame.size.height - round(currentViewFrame.size.height / 2.0))];
            [self.filterView addSubview:blurOverlayView];
            [self.filter addTarget:blurOverlayView];
        }
        else if (self.filterType == GPUIMAGE_MOTIONDETECTOR)
        {
            self.faceView = [[UIView alloc] initWithFrame:CGRectMake(100.0, 100.0, 100.0, 100.0)];
            self.faceView.layer.borderWidth = 1;
            self.faceView.layer.borderColor = [[UIColor redColor] CGColor];
            [self.view addSubview:self.faceView];
            self.faceView.hidden = YES;
            
            __weak ViewController * weakSelf = self;
            [(GPUImageMotionDetector *) self.filter setMotionDetectionBlock:^(CGPoint motionCentroid, CGFloat motionIntensity, CMTime frameTime) {
                if (motionIntensity > 0.01)
                {
                    CGFloat motionBoxWidth = 1500.0 * motionIntensity;
                    CGSize viewBounds = weakSelf.view.bounds.size;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        weakSelf.faceView.frame = CGRectMake(round(viewBounds.width * motionCentroid.x - motionBoxWidth / 2.0), round(viewBounds.height * motionCentroid.y - motionBoxWidth / 2.0), motionBoxWidth, motionBoxWidth);
                        weakSelf.self.faceView.hidden = NO;
                    });
                    
                }
                else
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        weakSelf.faceView.hidden = YES;
                    });
                }
                
            }];
            
            [self.videoCamera addTarget:self.filterView];
        }
        else
        {
            [self.filter addTarget:self.filterView];
        }
    }
    
    [self.videoCamera startCameraCapture];
}

-(void)setLabelsTexts:(NSArray*)texts{
    for(NSUInteger index = 0; index < texts.count; index++){
        NSString *text = texts[index];
        if(index == 0){
            self.label1.text = text;
            self.label1.hidden = NO;
        } else if(index == 1){
            self.label2.text = text;
            self.label2.hidden = NO;
        } else if(index == 2){
            self.label3.text = text;
            self.label3.hidden = NO;
        } else if(index == 3){
            self.label4.text = text;
            self.label4.hidden = NO;
        }
    }
}


// [self setLabelsTexts:@[@""]];
// [self setSlidersValues:@[@(), @(), @()]];
-(void)setSlidersValues:(NSArray*)values{
    for(NSUInteger index = 0; index < values.count; index+=3){
        NSNumber *minNumber = values[index];
        NSNumber *number = values[index+1];
        NSNumber *maxNumber = values[index+2];
        if(index == 0){
            self.slider1.minimumValue = minNumber.floatValue;
            self.slider1.value = number.floatValue;
            self.slider1.maximumValue = maxNumber.floatValue;
            
        } else if(index == 1){
            self.slider2.minimumValue = minNumber.floatValue;
            self.slider2.value = number.floatValue;
            self.slider2.maximumValue = maxNumber.floatValue;
            
        } else if(index == 2){
            self.slider3.minimumValue = minNumber.floatValue;
            self.slider3.value = number.floatValue;
            self.slider3.maximumValue = maxNumber.floatValue;
            
        } else if(index == 3){
            self.slider4.minimumValue = minNumber.floatValue;
            self.slider4.value = number.floatValue;
            self.slider4.maximumValue = maxNumber.floatValue;
            
        }
        if(index / 3 == 0){
            self.slider1.hidden = NO;
        } else if(index / 3 == 1){
            self.slider2.hidden = NO;
        } else if(index / 3 == 2){
            self.slider3.hidden = NO;
        } else if(index / 3 == 3){
            self.slider4.hidden = NO;
        }
    }
}


-(UIImage*)takePicture{
    UIGraphicsBeginImageContext(self.filterView.bounds.size);
    [self.filterView drawViewHierarchyInRect:self.filterView.bounds afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

#pragma mark IBActions

-(IBAction)shutterButtonTouchUpInside{

    UIImage *image = [self takePicture];
    [self performSegueWithIdentifier:SegueMainToImage sender:image];
}

- (IBAction)updateFilterFromSlider:(id)sender;
{
    [self.videoCamera resetBenchmarkAverage];
    switch(self.filterType)
    {
        case GPUIMAGE_SEPIA: [(GPUImageSepiaFilter *)self.filter setIntensity:[(UISlider *)sender value]]; break;
        case GPUIMAGE_PIXELLATE: [(GPUImagePixellateFilter *)self.filter setFractionalWidthOfAPixel:[(UISlider *)sender value]]; break;
        case GPUIMAGE_POLARPIXELLATE: {
            [(GPUImagePolarPixellateFilter *)self.filter setPixelSize:CGSizeMake(self.slider1.value, self.slider1.value)];
            [(GPUImagePolarPixellateFilter *)self.filter setCenter:CGPointMake(self.slider2.value, self.slider3.value)];
        } break;
        case GPUIMAGE_PIXELLATE_POSITION: {
            [(GPUImagePixellatePositionFilter *)self.filter setRadius:self.slider1.value];
            [(GPUImagePixellatePositionFilter *)self.filter setFractionalWidthOfAPixel:self.slider2.value];
            [(GPUImagePixellatePositionFilter *)self.filter setCenter:CGPointMake(self.slider3.value, self.slider4.value)];
        }  break;
        case GPUIMAGE_POLKADOT: [(GPUImagePolkaDotFilter *)self.filter setFractionalWidthOfAPixel:[(UISlider *)sender value]]; break;
        case GPUIMAGE_HALFTONE: [(GPUImageHalftoneFilter *)self.filter setFractionalWidthOfAPixel:[(UISlider *)sender value]]; break;
        case GPUIMAGE_SATURATION: [(GPUImageSaturationFilter *)self.filter setSaturation:[(UISlider *)sender value]]; break;
        case GPUIMAGE_CONTRAST: [(GPUImageContrastFilter *)self.filter setContrast:[(UISlider *)sender value]]; break;
        case GPUIMAGE_BRIGHTNESS: [(GPUImageBrightnessFilter *)self.filter setBrightness:[(UISlider *)sender value]]; break;
        case GPUIMAGE_LEVELS: {
            float value = [(UISlider *)sender value];
            [(GPUImageLevelsFilter *)self.filter setRedMin:value gamma:1.0 max:1.0 minOut:0.0 maxOut:1.0];
            [(GPUImageLevelsFilter *)self.filter setGreenMin:value gamma:1.0 max:1.0 minOut:0.0 maxOut:1.0];
            [(GPUImageLevelsFilter *)self.filter setBlueMin:value gamma:1.0 max:1.0 minOut:0.0 maxOut:1.0];
        }; break;
        case GPUIMAGE_EXPOSURE: [(GPUImageExposureFilter *)self.filter setExposure:[(UISlider *)sender value]]; break;
        case GPUIMAGE_MONOCHROME: [(GPUImageMonochromeFilter *)self.filter setIntensity:[(UISlider *)sender value]]; break;
        case GPUIMAGE_RGB: [(GPUImageRGBFilter *)self.filter setGreen:[(UISlider *)sender value]]; break;
        case GPUIMAGE_HUE: [(GPUImageHueFilter *)self.filter setHue:[(UISlider *)sender value]]; break;
        case GPUIMAGE_WHITEBALANCE: [(GPUImageWhiteBalanceFilter *)self.filter setTemperature:[(UISlider *)sender value]]; break;
        case GPUIMAGE_SHARPEN: [(GPUImageSharpenFilter *)self.filter setSharpness:[(UISlider *)sender value]]; break;
        case GPUIMAGE_HISTOGRAM: [(GPUImageHistogramFilter *)self.filter setDownsamplingFactor:round([(UISlider *)sender value])]; break;
        case GPUIMAGE_UNSHARPMASK: [(GPUImageUnsharpMaskFilter *)self.filter setIntensity:[(UISlider *)sender value]]; break;
            //        case GPUIMAGE_UNSHARPMASK: [(GPUImageUnsharpMaskFilter *)self.filter setBlurSize:[(UISlider *)sender value]]; break;
        case GPUIMAGE_GAMMA: [(GPUImageGammaFilter *)self.filter setGamma:[(UISlider *)sender value]]; break;
        case GPUIMAGE_CROSSHATCH: [(GPUImageCrosshatchFilter *)self.filter setCrossHatchSpacing:[(UISlider *)sender value]]; break;
        case GPUIMAGE_POSTERIZE: [(GPUImagePosterizeFilter *)self.filter setColorLevels:round([(UISlider*)sender value])]; break;
        case GPUIMAGE_HAZE: [(GPUImageHazeFilter *)self.filter setDistance:[(UISlider *)sender value]]; break;
        case GPUIMAGE_SOBELEDGEDETECTION: [(GPUImageSobelEdgeDetectionFilter *)self.filter setEdgeStrength:[(UISlider *)sender value]]; break;
        case GPUIMAGE_PREWITTEDGEDETECTION: [(GPUImagePrewittEdgeDetectionFilter *)self.filter setEdgeStrength:[(UISlider *)sender value]]; break;
        case GPUIMAGE_SKETCH: [(GPUImageSketchFilter *)self.filter setEdgeStrength:[(UISlider *)sender value]]; break;
        case GPUIMAGE_THRESHOLD: [(GPUImageLuminanceThresholdFilter *)self.filter setThreshold:[(UISlider *)sender value]]; break;
        case GPUIMAGE_ADAPTIVETHRESHOLD: [(GPUImageAdaptiveThresholdFilter *)self.filter setBlurRadiusInPixels:[(UISlider*)sender value]]; break;
        case GPUIMAGE_AVERAGELUMINANCETHRESHOLD: [(GPUImageAverageLuminanceThresholdFilter *)self.filter setThresholdMultiplier:[(UISlider *)sender value]]; break;
        case GPUIMAGE_DISSOLVE: [(GPUImageDissolveBlendFilter *)self.filter setMix:[(UISlider *)sender value]]; break;
        case GPUIMAGE_POISSONBLEND: [(GPUImagePoissonBlendFilter *)self.filter setMix:[(UISlider *)sender value]]; break;
        case GPUIMAGE_LOWPASS: [(GPUImageLowPassFilter *)self.filter setFilterStrength:[(UISlider *)sender value]]; break;
        case GPUIMAGE_HIGHPASS: [(GPUImageHighPassFilter *)self.filter setFilterStrength:[(UISlider *)sender value]]; break;
        case GPUIMAGE_MOTIONDETECTOR: [(GPUImageMotionDetector *)self.filter setLowPassFilterStrength:[(UISlider *)sender value]]; break;
        case GPUIMAGE_CHROMAKEY: [(GPUImageChromaKeyBlendFilter *)self.filter setThresholdSensitivity:[(UISlider *)sender value]]; break;
        case GPUIMAGE_CHROMAKEYNONBLEND: [(GPUImageChromaKeyFilter *)self.filter setThresholdSensitivity:[(UISlider *)sender value]]; break;
        case GPUIMAGE_KUWAHARA: [(GPUImageKuwaharaFilter *)self.filter setRadius:round([(UISlider *)sender value])]; break;
        case GPUIMAGE_SWIRL: [(GPUImageSwirlFilter *)self.filter setAngle:[(UISlider *)sender value]]; break;
        case GPUIMAGE_EMBOSS: [(GPUImageEmbossFilter *)self.filter setIntensity:[(UISlider *)sender value]]; break;
        case GPUIMAGE_CANNYEDGEDETECTION: [(GPUImageCannyEdgeDetectionFilter *)self.filter setBlurTexelSpacingMultiplier:[(UISlider*)sender value]]; break;
            //        case GPUIMAGE_CANNYEDGEDETECTION: [(GPUImageCannyEdgeDetectionFilter *)self.filter setLowerThreshold:[(UISlider*)sender value]]; break;
        case GPUIMAGE_HARRISCORNERDETECTION: [(GPUImageHarrisCornerDetectionFilter *)self.filter setThreshold:[(UISlider*)sender value]]; break;
        case GPUIMAGE_NOBLECORNERDETECTION: [(GPUImageNobleCornerDetectionFilter *)self.filter setThreshold:[(UISlider*)sender value]]; break;
        case GPUIMAGE_SHITOMASIFEATUREDETECTION: [(GPUImageShiTomasiFeatureDetectionFilter *)self.filter setThreshold:[(UISlider*)sender value]]; break;
        case GPUIMAGE_HOUGHTRANSFORMLINEDETECTOR: [(GPUImageHoughTransformLineDetector *)self.filter setLineDetectionThreshold:[(UISlider*)sender value]]; break;
            //        case GPUIMAGE_HARRISCORNERDETECTION: [(GPUImageHarrisCornerDetectionFilter *)self.filter setSensitivity:[(UISlider*)sender value]]; break;
        case GPUIMAGE_THRESHOLDEDGEDETECTION: [(GPUImageThresholdEdgeDetectionFilter *)self.filter setThreshold:[(UISlider *)sender value]]; break;
        case GPUIMAGE_SMOOTHTOON: [(GPUImageSmoothToonFilter *)self.filter setBlurRadiusInPixels:[(UISlider*)sender value]]; break;
        case GPUIMAGE_THRESHOLDSKETCH: [(GPUImageThresholdSketchFilter *)self.filter setThreshold:[(UISlider *)sender value]]; break;
            //        case GPUIMAGE_BULGE: [(GPUImageBulgeDistortionFilter *)self.filter setRadius:[(UISlider *)sender value]]; break;
        case GPUIMAGE_BULGE: [(GPUImageBulgeDistortionFilter *)self.filter setScale:[(UISlider *)sender value]]; break;
        case GPUIMAGE_SPHEREREFRACTION: [(GPUImageSphereRefractionFilter *)self.filter setRadius:[(UISlider *)sender value]]; break;
        case GPUIMAGE_GLASSSPHERE: [(GPUImageGlassSphereFilter *)self.filter setRadius:[(UISlider *)sender value]]; break;
        case GPUIMAGE_TONECURVE: [(GPUImageToneCurveFilter *)self.filter setBlueControlPoints:[NSArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(0.0, 0.0)], [NSValue valueWithCGPoint:CGPointMake(0.5, [(UISlider *)sender value])], [NSValue valueWithCGPoint:CGPointMake(1.0, 0.75)], nil]]; break;
        case GPUIMAGE_HIGHLIGHTSHADOW: [(GPUImageHighlightShadowFilter *)self.filter setHighlights:[(UISlider *)sender value]]; break;
        case GPUIMAGE_PINCH: [(GPUImagePinchDistortionFilter *)self.filter setScale:[(UISlider *)sender value]]; break;
        case GPUIMAGE_PERLINNOISE:  [(GPUImagePerlinNoiseFilter *)self.filter setScale:[(UISlider *)sender value]]; break;
        case GPUIMAGE_MOSAIC:  [(GPUImageMosaicFilter *)self.filter setDisplayTileSize:CGSizeMake([(UISlider *)sender value], [(UISlider *)sender value])]; break;
        case GPUIMAGE_VIGNETTE: [(GPUImageVignetteFilter *)self.filter setVignetteEnd:[(UISlider *)sender value]]; break;
        case GPUIMAGE_BOXBLUR: [(GPUImageBoxBlurFilter *)self.filter setBlurRadiusInPixels:[(UISlider*)sender value]]; break;
        case GPUIMAGE_GAUSSIAN: [(GPUImageGaussianBlurFilter *)self.filter setBlurRadiusInPixels:[(UISlider*)sender value]]; break;
            //        case GPUIMAGE_GAUSSIAN: [(GPUImageGaussianBlurFilter *)self.filter setBlurPasses:round([(UISlider*)sender value])]; break;
            //        case GPUIMAGE_BILATERAL: [(GPUImageBilateralFilter *)self.filter setBlurSize:[(UISlider*)sender value]]; break;
        case GPUIMAGE_BILATERAL: [(GPUImageBilateralFilter *)self.filter setDistanceNormalizationFactor:[(UISlider*)sender value]]; break;
        case GPUIMAGE_MOTIONBLUR: [(GPUImageMotionBlurFilter *)self.filter setBlurAngle:[(UISlider*)sender value]]; break;
        case GPUIMAGE_ZOOMBLUR: [(GPUImageZoomBlurFilter *)self.filter setBlurSize:[(UISlider*)sender value]]; break;
        case GPUIMAGE_OPACITY:  [(GPUImageOpacityFilter *)self.filter setOpacity:[(UISlider *)sender value]]; break;
        case GPUIMAGE_GAUSSIAN_SELECTIVE: [(GPUImageGaussianSelectiveBlurFilter *)self.filter setExcludeCircleRadius:[(UISlider*)sender value]]; break;
        case GPUIMAGE_GAUSSIAN_POSITION: [(GPUImageGaussianBlurPositionFilter *)self.filter setBlurRadius:[(UISlider *)sender value]]; break;
        case GPUIMAGE_FILTERGROUP: [(GPUImagePixellateFilter *)[(GPUImageFilterGroup *)self.filter filterAtIndex:1] setFractionalWidthOfAPixel:[(UISlider *)sender value]]; break;
        case GPUIMAGE_CROP: [(GPUImageCropFilter *)self.filter setCropRegion:CGRectMake(0.0, 0.0, 1.0, [(UISlider*)sender value])]; break;
        case GPUIMAGE_TRANSFORM: [(GPUImageTransformFilter *)self.filter setAffineTransform:CGAffineTransformMakeRotation([(UISlider*)sender value])]; break;
        case GPUIMAGE_TRANSFORM3D:
        {
            CATransform3D perspectiveTransform = CATransform3DIdentity;
            perspectiveTransform.m34 = 0.4;
            perspectiveTransform.m33 = 0.4;
            perspectiveTransform = CATransform3DScale(perspectiveTransform, 0.75, 0.75, 0.75);
            perspectiveTransform = CATransform3DRotate(perspectiveTransform, self.slider1.value, 0.0, 1.0, 0.0);
            perspectiveTransform = CATransform3DRotate(perspectiveTransform, self.slider2.value, 1.0, 0.0, 0.0);
            [(GPUImageTransformFilter *)self.filter setTransform3D:perspectiveTransform];
        }; break;
        case GPUIMAGE_TILTSHIFT:
        {
            CGFloat midpoint = [(UISlider *)sender value];
            [(GPUImageTiltShiftFilter *)self.filter setTopFocusLevel:midpoint - 0.1];
            [(GPUImageTiltShiftFilter *)self.filter setBottomFocusLevel:midpoint + 0.1];
        }; break;
        case GPUIMAGE_LOCALBINARYPATTERN:
        {
            CGFloat multiplier = [(UISlider *)sender value];
            [(GPUImageLocalBinaryPatternFilter *)self.filter setTexelWidth:(multiplier / self.view.bounds.size.width)];
            [(GPUImageLocalBinaryPatternFilter *)self.filter setTexelHeight:(multiplier / self.view.bounds.size.height)];
        }; break;
        default: break;
    }
}





#pragma mark GPUImageVideoCameraDelegate
- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    if (!faceThinking) {
        CFAllocatorRef allocator = CFAllocatorGetDefault();
        CMSampleBufferRef sbufCopyOut;
        CMSampleBufferCreateCopy(allocator,sampleBuffer,&sbufCopyOut);
        [self performSelectorInBackground:@selector(grepFacesForSampleBuffer:) withObject:CFBridgingRelease(sbufCopyOut)];
    }
}

- (void)grepFacesForSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    faceThinking = TRUE;
    NSLog(@"Faces thinking");
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
	CIImage *convertedImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(__bridge NSDictionary *)attachments];
    
	if (attachments)
		CFRelease(attachments);
	NSDictionary *imageOptions = nil;
	UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
	int exifOrientation;
	
    /* kCGImagePropertyOrientation values
     The intended display orientation of the image. If present, this key is a CFNumber value with the same value as defined
     by the TIFF and EXIF specifications -- see enumeration of integer constants.
     The value specified where the origin (0,0) of the image is located. If not present, a value of 1 is assumed.
     
     used when calling featuresInImage: options: The value for this key is an integer NSNumber from 1..8 as found in kCGImagePropertyOrientation.
     If present, the detection will be done based on that orientation but the coordinates in the returned features will still be based on those of the image. */
    
	enum {
		PHOTOS_EXIF_0ROW_TOP_0COL_LEFT			= 1, //   1  =  0th row is at the top, and 0th column is on the left (THE DEFAULT).
		PHOTOS_EXIF_0ROW_TOP_0COL_RIGHT			= 2, //   2  =  0th row is at the top, and 0th column is on the right.
		PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT      = 3, //   3  =  0th row is at the bottom, and 0th column is on the right.
		PHOTOS_EXIF_0ROW_BOTTOM_0COL_LEFT       = 4, //   4  =  0th row is at the bottom, and 0th column is on the left.
		PHOTOS_EXIF_0ROW_LEFT_0COL_TOP          = 5, //   5  =  0th row is on the left, and 0th column is the top.
		PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP         = 6, //   6  =  0th row is on the right, and 0th column is the top.
		PHOTOS_EXIF_0ROW_RIGHT_0COL_BOTTOM      = 7, //   7  =  0th row is on the right, and 0th column is the bottom.
		PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM       = 8  //   8  =  0th row is on the left, and 0th column is the bottom.
	};
	BOOL isUsingFrontFacingCamera = FALSE;
    AVCaptureDevicePosition currentCameraPosition = [self.videoCamera cameraPosition];
    
    if (currentCameraPosition != AVCaptureDevicePositionBack)
    {
        isUsingFrontFacingCamera = TRUE;
    }
    
	switch (curDeviceOrientation) {
		case UIDeviceOrientationPortraitUpsideDown:  // Device oriented vertically, home button on the top
			exifOrientation = PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM;
			break;
		case UIDeviceOrientationLandscapeLeft:       // Device oriented horizontally, home button on the right
			if (isUsingFrontFacingCamera)
				exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
			else
				exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
			break;
		case UIDeviceOrientationLandscapeRight:      // Device oriented horizontally, home button on the left
			if (isUsingFrontFacingCamera)
				exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
			else
				exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
			break;
		case UIDeviceOrientationPortrait:            // Device oriented vertically, home button on the bottom
		default:
			exifOrientation = PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP;
			break;
	}
    
	imageOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:exifOrientation] forKey:CIDetectorImageOrientation];
    
    NSLog(@"Face Detector %@", [self.faceDetector description]);
    NSLog(@"converted Image %@", [convertedImage description]);
    NSArray *features = [self.faceDetector featuresInImage:convertedImage options:imageOptions];
    
    
    // get the clean aperture
    // the clean aperture is a rectangle that defines the portion of the encoded pixel dimensions
    // that represents image data valid for display.
    CMFormatDescriptionRef fdesc = CMSampleBufferGetFormatDescription(sampleBuffer);
    CGRect clap = CMVideoFormatDescriptionGetCleanAperture(fdesc, false /*originIsTopLeft == false*/);
    
    
    [self GPUVCWillOutputFeatures:features forClap:clap andOrientation:curDeviceOrientation];
    faceThinking = FALSE;
    
}

- (void)GPUVCWillOutputFeatures:(NSArray*)featureArray forClap:(CGRect)clap
                 andOrientation:(UIDeviceOrientation)curDeviceOrientation
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Did receive array");
        
        CGRect previewBox = self.view.frame;
        
        if (featureArray == nil && self.faceView) {
            [self.faceView removeFromSuperview];
            self.faceView = nil;
        }
        
        
        for ( CIFaceFeature *faceFeature in featureArray) {
            
            // find the correct position for the square layer within the previewLayer
            // the feature box originates in the bottom left of the video frame.
            // (Bottom right if mirroring is turned on)
            NSLog(@"%@", NSStringFromCGRect([faceFeature bounds]));
            
            //Update face bounds for iOS Coordinate System
            CGRect faceRect = [faceFeature bounds];
            
            // flip preview width and height
            CGFloat temp = faceRect.size.width;
            faceRect.size.width = faceRect.size.height;
            faceRect.size.height = temp;
            temp = faceRect.origin.x;
            faceRect.origin.x = faceRect.origin.y;
            faceRect.origin.y = temp;
            // scale coordinates so they fit in the preview box, which may be scaled
            CGFloat widthScaleBy = previewBox.size.width / clap.size.height;
            CGFloat heightScaleBy = previewBox.size.height / clap.size.width;
            faceRect.size.width *= widthScaleBy;
            faceRect.size.height *= heightScaleBy;
            faceRect.origin.x *= widthScaleBy;
            faceRect.origin.y *= heightScaleBy;
            
            faceRect = CGRectOffset(faceRect, previewBox.origin.x, previewBox.origin.y);
            
            if (self.faceView) {
                [self.faceView removeFromSuperview];
                self.faceView =  nil;
            }
            
            // create a UIView using the bounds of the face
            self.faceView = [[UIView alloc] initWithFrame:faceRect];
            
            // add a border around the newly created UIView
            self.faceView.layer.borderWidth = 1;
            self.faceView.layer.borderColor = [[UIColor redColor] CGColor];
            
            // add the new view to create a box around the face
            [self.view addSubview:self.faceView];
            
        }
    });
    
}

-(IBAction)facesSwitched:(UISwitch*)sender{
    if (![sender isOn]) {
        [self.videoCamera setDelegate:nil];
        if (self.faceView) {
            [self.faceView removeFromSuperview];
            self.faceView = nil;
        }
    }else{
        [self.videoCamera setDelegate:self];
        
    }
}


@end
