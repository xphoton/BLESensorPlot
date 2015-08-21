//
//  PlotValueViewController.m
//  DarkBlue
//
//  Created by Xiaoping Hong on 8/19/15.
//  Copyright (c) 2015 chenee. All rights reserved.
//

#import "PlotValueViewController.h"
#import "BTServer.h"
#import "ProgressHUD.h"
#import "NSData+HexDump.h"

#define USE_DOUBLEFASTPATH true
#define USE_ONEVALUEPATH   true

@interface PlotValueViewController () <BTServerDelegate, CPTPlotDataSource>

@property (strong,nonatomic) BTServer *defaultBTServer;
@property (nonatomic, readwrite, strong) CPTXYGraph *graph;
@property (nonatomic, readwrite, strong) NSData *xxx;
@property (nonatomic, readwrite, strong) NSData *yyy1;

@end

@implementation PlotValueViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.defaultBTServer = [BTServer defaultBTServer];
    self.defaultBTServer.delegate = (id)self;
    readState = false;
    data = [[NSMutableArray alloc] init];
    rawData = [[NSMutableArray alloc] init];
    timeData = [[NSMutableArray alloc] init];
    
    CGRect frame;
    frame.origin.x = 17;
    frame.origin.y = 130;
    frame.size.width = 286;
    frame.size.height = 216; // not too tall

    // Create graph from a custom theme
    
    CPTGraphHostingView *hostingView = [[CPTGraphHostingView alloc] initWithFrame:frame];
    [self.view addSubview:hostingView];
    CPTXYGraph *newGraph = [[CPTXYGraph alloc] initWithFrame:hostingView.frame];
    CPTTheme *theme      = [CPTTheme themeNamed:kCPTPlainWhiteTheme];
    [newGraph applyTheme:theme];
    self.graph = newGraph;
    
    newGraph.paddingLeft   = 60.0;
    newGraph.paddingTop    = 10.0;
    newGraph.paddingRight  = 10.0;
    newGraph.paddingBottom = 20.0;

    hostingView.hostedGraph = newGraph;
    
    newGraph.plotAreaFrame.masksToBorder = NO;
    
    // Setup plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)newGraph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = NO;
    plotSpace.xRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0.0) length:CPTDecimalFromDouble(2)];
    plotSpace.yRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(6600) length:CPTDecimalFromDouble(100)];
    
    //set axis
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    
    CPTXYAxis *x = axisSet.xAxis;
    x.majorIntervalLength = CPTDecimalFromFloat(2);
    x.minorTicksPerInterval = 1;
    x.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0];
    //x.borderWidth = 0;
    //x.labelExclusionRanges = [NSArray arrayWithObjects:
    //                          [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-100)
    //                                                      length:CPTDecimalFromFloat(300)], nil];
    
    CPTXYAxis *y = axisSet.yAxis;
    y.majorIntervalLength = CPTDecimalFromFloat(20);
    y.minorTicksPerInterval = 1;
    //y.labelExclusionRanges = [NSArray arrayWithObjects:
    //                          [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-1000)
    //                                                      length:CPTDecimalFromFloat(8000)], nil];

    //set scatter plot
    CPTScatterPlot *dataSourceLinePlot = [[CPTScatterPlot alloc] init];
    dataSourceLinePlot.identifier = @"Quantity";
    CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
    lineStyle.lineWidth = 0.2f;
    lineStyle.lineColor = [CPTColor blackColor];
    dataSourceLinePlot.dataLineStyle = lineStyle;
    dataSourceLinePlot.dataSource = self;
    [self.graph addPlot:dataSourceLinePlot];
    
    // Put an area gradient under the plot above
    CPTColor *areaColor = [CPTColor colorWithComponentRed:0.3
                                                  green:1.0
                                                   blue:0.3
                                                  alpha:0.3];
    CPTGradient *areaGradient = [CPTGradient gradientWithBeginningColor:areaColor
                                                          endingColor:[CPTColor clearColor]];
    areaGradient.angle = -90.0f;
    CPTFill *areaGradientFill = [CPTFill fillWithGradient:areaGradient];
    dataSourceLinePlot.areaFill = areaGradientFill;
    dataSourceLinePlot.areaBaseValue = CPTDecimalFromString(@"1.75");

}


-(void)reloadPlots
{
    NSArray *plots = [self.graph allPlots];
    
    for ( CPTPlot *plot in plots ) {
        [plot reloadData];
    }
}

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    return data.count;
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot
                     field:(NSUInteger)fieldEnum
               recordIndex:(NSUInteger)index
{
    switch (fieldEnum)
    {
        case CPTScatterPlotFieldX:
        {
            return [NSDecimalNumber numberWithInt:index];
        }
        case CPTScatterPlotFieldY:
        {
            int v = [[[data objectAtIndex:index] valueForKey:@"intValue"] intValue];
            return [NSNumber numberWithInt:v];
        }
    }
    return nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)goBack:(id)sender {
    [self stopDataAcquisition];
    [self.navigationController popViewControllerAnimated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
-(void)didDisconnect
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [ProgressHUD showSuccess:@"disconnect from peripheral"];
        [self.navigationController popToRootViewControllerAnimated:YES];
    });
    
}
-(void)readAction
{
    if (readState == true) {
        NSLog(@"read busy ...");
        return;
    }
    readState = true;
    [self.defaultBTServer readValue:nil];
}

-(void)didReadvalue
{
    dispatch_async(dispatch_get_main_queue(), ^{
        readState = false;
        NSData *d = self.defaultBTServer.selectCharacteristic.value;
        //        NSString *s = [NSString stringWithUTF8String:[d bytes]];
        NSString *hexInt = [d hexval];
        
        NSScanner *scanner=[NSScanner scannerWithString:hexInt];
        unsigned int deciInt;
        [scanner scanHexInt:&deciInt];
        [rawData addObject:[NSNumber numberWithInt:deciInt]];
        NSLog(@"read (%@):\n%@\n%u\n%lu",d,hexInt,deciInt, (unsigned long)rawData.count);
        sensorValue.text = [NSString stringWithFormat:@"reading sensor %lu: %u", rawData.count+1, deciInt] ;
        if (rawData.count >= 3) {
        [self performSelector:@selector(stopSensor) withObject:nil afterDelay:0];
        }
    });
}


- (IBAction)startButton:(id)sender {
    if ([self.startButton.titleLabel.text  isEqual: @"Start"]) {
        [self.startButton setTitle:@"Stop" forState:UIControlStateNormal];
        [self startDataAcquisition];
    }
    else if ([self.startButton.titleLabel.text  isEqual: @"Stop"]) {
        [self.startButton setTitle:@"Start" forState:UIControlStateNormal];
        [self stopDataAcquisition];
    }
}

- (void) startDataAcquisition {
    [self startSensor];
    mytimer = [NSTimer scheduledTimerWithTimeInterval:[self.samplingInterval.text floatValue]
                                     target:self
                                   selector:@selector(startSensor)
                                   userInfo:nil
                                    repeats:YES];
}

- (void) stopDataAcquisition {
    [mytimer invalidate];
    [self saveData];
    [data removeAllObjects];
    [timeData removeAllObjects];
}

- (void) saveData {
    NSMutableString *csv = [NSMutableString stringWithString:@"Time,Reading"];
    
    NSUInteger count = [data count];
    // provided all arrays are of the same length
    for (NSUInteger i=0; i<count; i++ ) {
        [csv appendFormat:@"\n %@,\"%d\"",
         [timeData objectAtIndex:i],
         [[data objectAtIndex:i] intValue]
         ];
        // instead of integerValue may be used intValue or other, it depends how array was created
    }
    
    currentTime = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YY-MM-dd-hh-mm-ss"];
    NSString *resultString = [dateFormatter stringFromDate: currentTime];
    NSString *filePath = [self findFolderDir:@"dataFolder"];
    NSString *fileName = [NSString stringWithFormat:@"%@/%@-Data.csv",filePath,resultString];

    NSLog(@"%@",fileName);
    NSError *error;
    BOOL res = [csv writeToFile:fileName atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    if (!res) {
        NSLog(@"Error %@ while writing to file %@", [error localizedDescription], fileName );
    }

    
}

- (NSString*) findFolderDir: (NSString *) folderName {
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *dataDir = [documentsDirectory stringByAppendingPathComponent:folderName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dataDir])
        [[NSFileManager defaultManager] createDirectoryAtPath:dataDir withIntermediateDirectories:NO attributes:nil error:nil];
    return dataDir;
}

- (void) startSensor {
    //[self readAction];
    [self.defaultBTServer setNotificationYes:self.defaultBTServer.selectCharacteristic];
    [rawData removeAllObjects];
    sensorValue.text = @"reading sensor";
    
}

- (void) stopSensor {
    [self.defaultBTServer setNotificationNo:self.defaultBTServer.selectCharacteristic];
    NSLog(@"avg = %@", [rawData valueForKeyPath:@"@avg.intValue"]);
    sensorValue.text = [NSString stringWithFormat:@"%@", [rawData valueForKeyPath:@"@avg.intValue"]];
    [data addObject:[rawData valueForKeyPath:@"@avg.intValue"]];
    
    currentTime = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YY-MM-dd-hh-mm-ss"];
    NSString *resultString = [dateFormatter stringFromDate: currentTime];
    [timeData addObject:resultString];
    
    int count = [data count];
    int maxValue = [[data valueForKeyPath:@"@max.intValue"] intValue];
    int minValue = [[data valueForKeyPath:@"@min.intValue"] intValue];

    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.graph.defaultPlotSpace;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0)
                                                   length:CPTDecimalFromFloat(count+2)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(minValue -10)
                                                   length:CPTDecimalFromFloat(maxValue - minValue + 20)];
    
    //set axis
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.graph.axisSet;
    

    
    CPTXYAxis *y = axisSet.yAxis;
    y.majorIntervalLength = CPTDecimalFromFloat((maxValue - minValue + 20)/4);
    y.minorTicksPerInterval = 1;
    y.labelingPolicy = CPTAxisLabelingPolicyAutomatic;

    NSLog(@"%f",(float)count / 4);
    CPTXYAxis *x = axisSet.xAxis;
    x.majorIntervalLength = CPTDecimalFromFloat(1);
    x.minorTicksPerInterval = 0;
    //x.labelFormatter = [[CPTTimeFormatter alloc] initWithDateFormatter:(NSDateFormatter *)]
    x.labelingPolicy = CPTAxisLabelingPolicyAutomatic;

    [self reloadPlots];
}

@end
