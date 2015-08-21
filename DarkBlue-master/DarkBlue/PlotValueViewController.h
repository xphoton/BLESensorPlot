//
//  PlotValueViewController.h
//  DarkBlue
//
//  Created by Xiaoping Hong on 8/19/15.
//  Copyright (c) 2015 chenee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CorePlot-CocoaTouch.h>
#define NUM_POINTS 500

@interface PlotValueViewController : UIViewController{
    BOOL readState;
    __weak IBOutlet UILabel *sensorValue;
    NSMutableArray *data;
    NSMutableArray *rawData;
    NSMutableArray *timeData;
    NSTimer *mytimer;
    NSDate *currentTime;
}
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UITextField *samplingInterval;

@end
