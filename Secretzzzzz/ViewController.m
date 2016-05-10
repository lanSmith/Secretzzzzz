//
//  ViewController.m
//  Secretzzzzz
//
//  Created by Ian Smith on 4/21/16.
//  Copyright © 2016 Ian Smith. All rights reserved.
//

#import "ViewController.h"
#import <Firebase/Firebase.h>

@import AssetsLibrary;

@interface ViewController ()

@property (strong, nonatomic) NSMutableDictionary *views;
@property (strong, nonatomic) NSMutableDictionary *metrics;

@property (strong, nonatomic) NSMutableArray *touchesArray;
@property (strong, nonatomic) NSMutableArray *pointArray;

@property (strong, nonatomic) Firebase *fireBase;

@property (strong, nonatomic) UIImageView *mainImageView;
@property (strong, nonatomic) UIImageView *tempDrawingView;

@property CGPoint lastPoint;
@property CGFloat brush;
@property CGFloat opacity;
@property BOOL mouseSwiped;
@property BOOL revealed;

@property CGFloat lineRed;
@property CGFloat lineGreen;
@property CGFloat lineBlue;

@end

@implementation ViewController

// Life Cycle
- (void)viewWillAppear:(BOOL)animated {
    if (self.revealed) {
        [self boardReset];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    [self initFirebase];

    self.lineRed = 0.0/255.0;
    self.lineGreen = 0.0/255.0;
    self.lineBlue = 0.0/255.0;
    self.brush = 2.0;
    self.opacity = 1.0;

    self.revealed = NO;

    self.views = [[NSMutableDictionary alloc] init];
    self.metrics = [[NSMutableDictionary alloc] init];

    [self buildMainImageView];
    [self buildingTempDrawingView];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

 // FireBase
- (void)initFirebase {
    self.fireBase = [[Firebase alloc] initWithUrl:@"https://secret-drawing.firebaseIO.com/image/"];
}


 // Build Drawing Areas
- (void)buildMainImageView {
    self.mainImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview:self.mainImageView];

    [self.views setObject:@"self.mainImageView" forKey:@"mainImageView"];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[mainImageView]" options:NSLayoutFormatAlignAllCenterX metrics:self.metrics views:self.views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[mainImageView]" options:NSLayoutFormatAlignAllCenterY metrics:self.metrics views:self.views]];

    self.mainImageView.backgroundColor = [UIColor clearColor];
    self.mainImageView.alpha = 0;
}

- (void)buildingTempDrawingView {
    self.tempDrawingView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview:self.tempDrawingView];

    [self.views setObject:@"self.tempDrawingView" forKey:@"tempDrawingView"];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[tempDrawingView]" options:NSLayoutFormatAlignAllCenterX metrics:self.metrics views:self.views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[tempDrawingView]" options:NSLayoutFormatAlignAllCenterY metrics:self.metrics views:self.views]];

    self.tempDrawingView.backgroundColor = [UIColor clearColor];
    self.tempDrawingView.alpha = 0;
    [self.view bringSubviewToFront:self.tempDrawingView];
}

 // Touch Stuff
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"Touch Started");

    if (!self.revealed) {

    self.mouseSwiped = NO;
    UITouch *touch = [touches anyObject];
    self.lastPoint = [touch locationInView:self.view];
    }

    // track touches
    if(!self.touchesArray) {
        self.touchesArray = [[NSMutableArray alloc] init];
    }
}


- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"Touch Moved");

    if (!self.revealed) {
        self.mouseSwiped = YES;
        UITouch *touch = [touches anyObject];
        CGPoint currentPoint = [touch locationInView:self.view];

        
        UIGraphicsBeginImageContext(self.view.frame.size); // begin image context full screen size
        [self.tempDrawingView.image drawInRect:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)]; // tempIV.image is now a full screen canvas
        CGContextMoveToPoint(UIGraphicsGetCurrentContext(), self.lastPoint.x, self.lastPoint.y); // add point to image context using the last touch pos
        CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), currentPoint.x, currentPoint.y); // add straight line from current pos to previous point
        CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound); // round off the end of the line
        CGContextSetLineWidth(UIGraphicsGetCurrentContext(), self.brush ); // set line width
        CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), self.lineRed, self.lineGreen, self.lineBlue, self.opacity); // set color and opacity
        CGContextSetBlendMode(UIGraphicsGetCurrentContext(),kCGBlendModeNormal); // set blend mode(?)
        CGContextStrokePath(UIGraphicsGetCurrentContext()); // create line with above parameters
        self.tempDrawingView.image = UIGraphicsGetImageFromCurrentImageContext(); // set traced line to temp.image
        [self.tempDrawingView setAlpha:0.0]; // change here to show while drawing // hime temp.image
        UIGraphicsEndImageContext(); // end content

        self.lastPoint = currentPoint;
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"Touch Ended");

    if (!self.revealed) {
        if(!self.mouseSwiped) {
            UIGraphicsBeginImageContext(self.view.frame.size);
            [self.tempDrawingView.image drawInRect:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
            CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
            CGContextSetLineWidth(UIGraphicsGetCurrentContext(), self.brush);
            CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), self.lineRed, self.lineGreen, self.lineBlue, self.opacity);
            CGContextMoveToPoint(UIGraphicsGetCurrentContext(), self.lastPoint.x, self.lastPoint.y);
            CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), self.lastPoint.x, self.lastPoint.y);
            CGContextStrokePath(UIGraphicsGetCurrentContext());
            CGContextFlush(UIGraphicsGetCurrentContext());
            self.tempDrawingView.image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
 
        UIGraphicsBeginImageContext(self.mainImageView.frame.size); // start new g context w/ mainImage
        [self.mainImageView.image drawInRect:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) blendMode:kCGBlendModeNormal alpha:1.0]; // mainImage drawrect
        [self.tempDrawingView.image drawInRect:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) blendMode:kCGBlendModeNormal alpha:self.opacity]; // tempImage drawrect
        self.mainImageView.image = UIGraphicsGetImageFromCurrentImageContext(); // make main.Image be the content via getImageFrom, saving line to main.Image
        self.tempDrawingView.image = nil; // nil out the temp line
        UIGraphicsEndImageContext();
    }
}

 // Shake Stuff
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake) {
        [self showAlert];
    }
}

- (void)boardReset {
    self.lineRed = 0.0/255.0;
    self.lineGreen = 0.0/255.0;
    self.lineBlue = 0.0/255.0;
    self.brush = 2.0;
    self.opacity = 1.0;

    self.view.backgroundColor = [UIColor whiteColor];

    self.mainImageView.image = nil;
    self.mainImageView.alpha = 0;

    self.tempDrawingView.image = nil;
    self.tempDrawingView.alpha = 0;

    self.revealed = NO;
}

- (void)showAlert {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Options" message:@"Shake it, sh-shake it" preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *resetBoard = [UIAlertAction actionWithTitle:NSLocalizedString(@"Reset", @"Reset action") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        NSLog(@"Board Reset");
        [self boardReset];
    }];

    UIAlertAction *revealAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Reveal", @"Reveal action") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSLog(@"Board Revealed");

        self.mainImageView.alpha = 1;
        self.tempDrawingView.alpha = 1;
        
        self.revealed = YES;
    }];

    UIAlertAction *pushAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Push", @"Push action") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSLog(@"Push Shared");

        UIGraphicsBeginImageContext(self.view.bounds.size);
        self.mainImageView.backgroundColor = self.view.backgroundColor;
        self.mainImageView.alpha = 1.0;
        [self.mainImageView.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        self.mainImageView.alpha = 0.0;

        NSString *imageString = [[NSString alloc] initWithString:[self encodeToBase64String:viewImage]];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.fireBase setValue:imageString]; // write to firebase
//            UIImageWriteToSavedPhotosAlbum(viewImage, self, nil, nil); // write to camera roll
        });


        UIView *flashView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        flashView.alpha = 1;
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.5];
        flashView.alpha = 0;
        [UIView commitAnimations];
//        UIAlertView *alert= [[UIAlertView alloc] initWithTitle:nil message:@"Photo saved to your camera roll" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
//        [alert show];
    }];

    UIAlertAction *pullAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Pull", @"Pull action") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSLog(@"Pull Tapped");

        [self.fireBase observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
            NSData *data = [[NSData alloc]initWithBase64EncodedString:snapshot.value options:NSDataBase64DecodingIgnoreUnknownCharacters];
            UIImage *retrivedImage = [UIImage imageWithData:data];
            self.mainImageView.contentMode = UIViewContentModeCenter;
            self.mainImageView.image = [self imageWithImage:retrivedImage scaledToSize:CGSizeMake((self.mainImageView.frame.size.width / 3), (self.mainImageView.frame.size.height / 3))];
        }];

//        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//
//        // Enumerate just the photos and videos group by using ALAssetsGroupSavedPhotos.
//        [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
//
//            // Within the group enumeration block, filter to enumerate just photos.
//            [group setAssetsFilter:[ALAssetsFilter allPhotos]];
//
//            // Chooses the photo at the last index
//            [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *alAsset, NSUInteger index, BOOL *innerStop) {
//
//                // The end of the enumeration is signaled by asset == nil.
//                if (alAsset) {
//                    ALAssetRepresentation *representation = [alAsset defaultRepresentation];
//                    UIImage *latestPhoto = [UIImage imageWithCGImage:[representation fullScreenImage]];
//
//                    // Stop the enumerations
//                    *stop = YES; *innerStop = YES;
//
//                    // Do something interesting with the AV asset.
//                    self.mainImageView.image = latestPhoto;
//                }
//            }];
//        } failureBlock: ^(NSError *error) {
//            // Typically you should handle an error more gracefully than this.
//            NSLog(@"No groups");
//        }];
    }];

    UIAlertAction *changeColorsAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Change Colors", @"Change Color action") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSLog(@"Colors Changed");

        CGFloat bkgrndRandRed = arc4random() % 255;
        CGFloat bkgrndRandBlue = arc4random() % 255;
        CGFloat bkgrndRandGreen = arc4random() % 255;

        self.view.backgroundColor = [UIColor colorWithRed:(bkgrndRandRed / 255.0) green:(bkgrndRandGreen / 255.0) blue:(bkgrndRandBlue / 255.0) alpha:1.0];

        self.lineRed = ((arc4random() % 255) / 255.0);
        self.lineBlue = ((arc4random() % 255) / 255.0);
        self.lineGreen = ((arc4random() % 255) / 255.0);
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel action") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSLog(@"Cancel action");
    }];

    [alertController addAction:resetBoard];
    [alertController addAction:revealAction];
    [alertController addAction:pushAction];
    [alertController addAction:pullAction];
    [alertController addAction:changeColorsAction];
    [alertController addAction:cancelAction];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (NSString *)encodeToBase64String:(UIImage *)image {
    return [UIImagePNGRepresentation(image) base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        if ([[UIScreen mainScreen] scale] == 2.0) {
            UIGraphicsBeginImageContextWithOptions(newSize, YES, 9.0);
        } else {
            UIGraphicsBeginImageContext(newSize);
        }
    } else {
        UIGraphicsBeginImageContext(newSize);
    }
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}
@end
