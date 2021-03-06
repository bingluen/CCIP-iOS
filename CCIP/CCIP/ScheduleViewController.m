//
//  ScheduleViewController.m
//  CCIP
//
//  Created by FrankWu on 2016/7/17.
//  Copyright © 2016年 CPRTeam. All rights reserved.
//

#import <CoreText/CoreText.h>
#import "UISegmentedControl+addition.h"
#import "NSInvocation+addition.h"
#import "AppDelegate.h"
#import "ScheduleViewController.h"
#import "ProgramDetailViewController.h"
#import "BLKFlexibleHeightBar.h"
#import "BLKDelegateSplitter.h"
#import "SquareCashStyleBehaviorDefiner.h"
#import "ScheduleViewCell.h"
#import <AFNetworking/AFNetworking.h>
#import "WebServiceEndPoint.h"
#import "headers.h"

#define TOOLBAR_MIN_HEIGHT  (22.0f)
#define TOOLBAR_HEIGHT      (44.0f)

#define MAX_TABLE_VIEW      (CGRectMake(0, TOOLBAR_HEIGHT, self.view.bounds.size.width, self.view.bounds.size.height - TOOLBAR_HEIGHT))
#define MIN_TABLE_VIEW      (CGRectMake(0, TOOLBAR_MIN_HEIGHT, self.view.bounds.size.width, self.view.bounds.size.height - TOOLBAR_MIN_HEIGHT))

@interface ScheduleViewController ()

@property (strong, nonatomic) FBShimmeringView *shimmeringLogoView;

@property (strong, nonatomic) IBOutlet BLKFlexibleHeightBar *myBar;
@property (strong, nonatomic) BLKDelegateSplitter *delegateSplitter;
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) IBOutlet UIToolbar *labelToolbar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *toolbarItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *labelToolbarItem;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) UILabel *segmentedLabel;
@property (strong, nonatomic) UISegmentedControl *segmentedControl;
@property (strong, nonatomic) UIRefreshControl *refreshControl;

@property NSUInteger refreshingCountDown;
@property (nonatomic) CGFloat previousProgress;

@property (strong, nonatomic) NSArray *rooms;
@property (strong, nonatomic) NSArray *programs;
@property (strong, nonatomic) NSArray *program_types;

@property (strong, nonatomic) NSArray *segmentsTextArray;

@property (strong, nonatomic) NSMutableDictionary *program_date;
@property (strong, nonatomic) NSMutableDictionary *program_date_section;

@end

@implementation ScheduleViewController

- (NSArray<id<UIPreviewActionItem>> *)previewActionItems {
    return [self previewActions];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self registerForceTouch];
    // set logo on nav title
    UIView *logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"coscup-logo"]];
    self.shimmeringLogoView = [[FBShimmeringView alloc] initWithFrame:logoView.bounds];
    self.shimmeringLogoView.contentView = logoView;
    self.navigationItem.titleView = self.shimmeringLogoView;
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    // ... setting up the SegmentedControl here ...
    _segmentedControl = [UISegmentedControl new];
    [_segmentedControl setFrame:CGRectMake(0, 0, 200, 30)];
    [_segmentedControl addTarget:self
                          action:@selector(segmentedControlValueDidChange:)
                forControlEvents:UIControlEventValueChanged];
    [_segmentedControl setTintColor:[UIColor colorWithRed:61.0f/255.0f
                                                    green:152.0f/255.0f
                                                     blue:60.0f/255.0f
                                                    alpha:1.0f]];
    
    // ... setting up label here ...
    _segmentedLabel = [UILabel new];
    [_segmentedLabel setFrame:CGRectMake(0, 0, 300, TOOLBAR_MIN_HEIGHT)];
    [_segmentedLabel setTextAlignment:NSTextAlignmentCenter];
    [_segmentedLabel setFont:[UIFont systemFontOfSize:12.0f weight:2.0f]];
    
    // ... setting up the Toolbar's Items here ...
    [self.toolbarItem setCustomView:_segmentedControl];
    [self.labelToolbarItem setCustomView:_segmentedLabel];
    UIColor *barTintColor = [[UIToolbar new] barTintColor];
    [self.toolbar setBarTintColor:barTintColor];
    [self.labelToolbar setBarTintColor:barTintColor];
    
    _myBar.behaviorDefiner = [SquareCashStyleBehaviorDefiner new];
    [_myBar.layer setShadowOffset:CGSizeMake(0, 1.0f/UIScreen.mainScreen.scale)];
    [_myBar.layer setShadowRadius:0];
    [_myBar.layer setShadowColor:[UIColor blackColor].CGColor];
    [_myBar.layer setShadowOpacity:0.25f];
    
    _myBar.maximumBarHeight = TOOLBAR_HEIGHT;
    _myBar.minimumBarHeight = TOOLBAR_MIN_HEIGHT;
    [self.view bringSubviewToFront:_myBar];

    self.delegateSplitter = [[BLKDelegateSplitter alloc] initWithFirstDelegate:_myBar.behaviorDefiner secondDelegate:self];
    
    [self settingFlexibleLayoutAttributes:self.view.frame.size.width];
    
    // ... setting up the TableView here ...
    // [_tableView setFrame:TABLE_VIEW];
    [self setTableViewInset:self.tableView isInit:YES];
    [_tableView setDelegate:(id<UITableViewDelegate>)self.delegateSplitter];
    
    // ... setting up the RefreshControl here ...
    UITableViewController *tableViewController = [UITableViewController new];
    tableViewController.tableView = self.tableView;
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self
                            action:@selector(refreshData)
                  forControlEvents:UIControlEventValueChanged];
    tableViewController.refreshControl = self.refreshControl;
    
    [self refreshData];
    
    SEND_GAI(@"ScheduleViewController");
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appplicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)goToSchedule {
    __nullable id scheduleIndexTextObj = [[NSUserDefaults standardUserDefaults] objectForKey:@"ScheduleIndexText"];
    if (scheduleIndexTextObj) {
        NSString *scheduleIndexText = (NSString*)scheduleIndexTextObj;
        [self setSegmentedAndTableWithText:scheduleIndexText];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"ScheduleIndexText"];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)appplicationDidBecomeActive:(NSNotification *)notification {
    [self goToSchedule];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [AppDelegate setDevLogo:self.shimmeringLogoView];

    [self setTableViewInset:self.tableView isInit:YES];
    
    [self goToSchedule];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
//    if (self.rooms == nil || self.programs == nil || self.program_types == nil) {
//        [self refreshData];
//    }
    [self setTableViewInset:self.tableView isInit:YES];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    // best call super just in case
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    // will execute before rotation
    [coordinator animateAlongsideTransition:^(id  _Nonnull context) {
        // will execute during rotation
        [self settingFlexibleLayoutAttributes:size.width];
        [self.myBar layoutSubviews];
        [self setTableViewInset:self.tableView isInit:YES];
    } completion:^(id  _Nonnull context) {
        // will execute after rotation
        [self settingFlexibleLayoutAttributes:size.width];
        [self.myBar layoutSubviews];
        [self setTableViewInset:self.tableView isInit:YES];
    }];
}

- (void)settingFlexibleLayoutAttributes:(float)width {
    CGPoint zeroPoint = CGPointMake(0, 0);
    CGRect maxRect = { zeroPoint, CGSizeMake(width, TOOLBAR_HEIGHT) };
    CGRect minRect = { zeroPoint, CGSizeMake(width, TOOLBAR_MIN_HEIGHT) };
    
    //// toolbar attributes
    BLKFlexibleHeightBarSubviewLayoutAttributes *toolbarInitialLayoutAttributes = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    toolbarInitialLayoutAttributes.size = maxRect.size;
    toolbarInitialLayoutAttributes.center = CGPointMake(CGRectGetMidX(maxRect), CGRectGetMidY(maxRect));
    // This is what we want the bar to look like at its maximum height (progress == 0.0)
    [_toolbar removeLayoutAttributesForProgress:0.0];
    [_toolbar addLayoutAttributes:toolbarInitialLayoutAttributes forProgress:0.0];
    
    // Create a final set of layout attributes based on the same values as the initial layout attributes
    BLKFlexibleHeightBarSubviewLayoutAttributes *toolbarFinalLayoutAttributes = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:toolbarInitialLayoutAttributes];
    toolbarFinalLayoutAttributes.alpha = 0.0;
    toolbarFinalLayoutAttributes.size = minRect.size;
    toolbarFinalLayoutAttributes.center = CGPointMake(CGRectGetMidX(minRect), CGRectGetMidY(minRect));
    // This is what we want the bar to look like at its minimum height (progress == 1.0)
    [_toolbar removeLayoutAttributesForProgress:1.0];
    [_toolbar addLayoutAttributes:toolbarFinalLayoutAttributes forProgress:1.0];
    
    //// label toolbar attributes
    BLKFlexibleHeightBarSubviewLayoutAttributes *lableToolbarInitialLayoutAttributes = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    lableToolbarInitialLayoutAttributes.size = maxRect.size;
    lableToolbarInitialLayoutAttributes.center = CGPointMake(CGRectGetMidX(maxRect), CGRectGetMidY(maxRect));
    lableToolbarInitialLayoutAttributes.alpha = 0.0;
    // This is what we want the bar to look like at its maximum height (progress == 0.0)
    [_labelToolbar removeLayoutAttributesForProgress:0.0];
    [_labelToolbar addLayoutAttributes:lableToolbarInitialLayoutAttributes forProgress:0.0];
    
    // Create a final set of layout attributes based on the same values as the initial layout attributes
    BLKFlexibleHeightBarSubviewLayoutAttributes *labelToolbarFinalLayoutAttributes = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:lableToolbarInitialLayoutAttributes];
    labelToolbarFinalLayoutAttributes.size = minRect.size;
    labelToolbarFinalLayoutAttributes.center = CGPointMake(CGRectGetMidX(minRect), CGRectGetMidY(minRect));
    labelToolbarFinalLayoutAttributes.alpha = 1.0;
    // This is what we want the bar to look like at its minimum height (progress == 1.0)
    [_labelToolbar removeLayoutAttributesForProgress:1.0];
    [_labelToolbar addLayoutAttributes:labelToolbarFinalLayoutAttributes forProgress:1.0];
}

- (void)setTableViewInset:(UIScrollView *)scrollView isInit:(BOOL)init{
    if (scrollView.contentSize.height > scrollView.frame.size.height || init) {
        CGFloat progress = (scrollView.contentOffset.y + scrollView.contentInset.top) / (self.myBar.maximumBarHeight - self.myBar.minimumBarHeight);
        if (progress <= 0) {
            progress = 0;
        } else if (progress > 1) {
            progress = 1;
        }
        
        UIEdgeInsets tableViewInset = [scrollView contentInset];
        UIEdgeInsets tableViewScrollInset = [scrollView scrollIndicatorInsets];
        
        CGFloat refreshControlHeight = 0.0;
        if (self.refreshControl.refreshing) {
            refreshControlHeight = self.refreshControl.frame.size.height;
        }
        
        if (init) {
            tableViewInset.bottom = self.bottomGuideHeight;
            tableViewInset.top = self.topGuideHeight + self.myBar.frame.size.height + refreshControlHeight;
            
            tableViewScrollInset.bottom = self.bottomGuideHeight;
            tableViewScrollInset.top = self.topGuideHeight + self.myBar.frame.size.height;
        } else if(_previousProgress != progress) {
            tableViewInset.bottom = self.bottomGuideHeight;
            tableViewInset.top = self.topGuideHeight + refreshControlHeight + TOOLBAR_HEIGHT + (TOOLBAR_MIN_HEIGHT - TOOLBAR_HEIGHT) * progress;
            
            tableViewScrollInset.bottom = self.bottomGuideHeight;
            tableViewScrollInset.top = self.topGuideHeight + TOOLBAR_HEIGHT + (TOOLBAR_MIN_HEIGHT - TOOLBAR_HEIGHT) * progress;
            
            _previousProgress = progress;
        }
        
        [scrollView setContentInset:tableViewInset];
        [scrollView setScrollIndicatorInsets:tableViewScrollInset];
    }
}

- (void)refreshData {
    [self.refreshControl beginRefreshing];
    self.refreshingCountDown = 3;
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager GET:CC_ANNOUNCEMENT parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        if (responseObject != nil) {
            self.rooms = responseObject;
        }
        [self endRefreshingWithCountDown];
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        [self endRefreshingWithCountDown];
    }];
    
    [manager GET:PROGRAM_DATA_URL parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        if (responseObject != nil) {
            self.programs = responseObject;
            [self setScheduleDate];
        }
        [self endRefreshingWithCountDown];
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        [self endRefreshingWithCountDown];
    }];
    
    [manager GET:PROGRAM_TYPE_DATA_URL parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        if (responseObject != nil) {
            self.program_types = responseObject;
            [self setScheduleDate];
        }
        [self endRefreshingWithCountDown];
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        [self endRefreshingWithCountDown];
    }];
}

- (void)endRefreshingWithCountDown {
    self.refreshingCountDown -= 1;
    if (self.refreshingCountDown == 0) {
        [UIView animateWithDuration:0
                         animations:^{
                             [self.refreshControl endRefreshing];
                             [self.tableView reloadData];
                         } completion:^(BOOL finished) {
                             if (finished) {
                                 [self performSelector:@selector(loaded)
                                            withObject:nil
                                            afterDelay:0.25f];
                             }
                         }];
    }
}

- (void)loaded {
    [self setTableViewInset:self.tableView isInit:YES];
    [self.refreshControl endRefreshing];
}

- (void)setScheduleDate {
    static NSDateFormatter *formatter_full = nil;
    if (formatter_full == nil) {
        formatter_full = [NSDateFormatter new];
        [formatter_full setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
        [formatter_full setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    }
    
    static NSDateFormatter *formatter_date = nil;
    if (formatter_date == nil) {
        formatter_date = [NSDateFormatter new];
        [formatter_date setDateFormat:@"MM/dd"];
    }
    
    static NSDate *startTime;
    static NSString *time_date;
    
    NSMutableDictionary *datesDict = [NSMutableDictionary new];
    
    for (NSDictionary *program in self.programs) {
        startTime = [formatter_full dateFromString:[program objectForKey:@"starttime"]];
        time_date = [formatter_date stringFromDate:startTime];
        
        NSMutableArray *tempArray = [datesDict objectForKey:time_date];
        if (tempArray == nil) {
            tempArray = [NSMutableArray new];
        }
        [tempArray addObject:program];
        [datesDict setObject:tempArray forKey:time_date];
    }
    
    self.program_date = datesDict;
    self.segmentsTextArray = [[self.program_date allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    [self.segmentedControl resetAllSegments:self.segmentsTextArray];
    
    [self checkScheduleDate];
}

- (void)setSegmentedAndTableWithText:(NSString *)selectedSegmentText {
    if ([self.segmentsTextArray count] == 0) {
        NSObject *scheduleDataObj = [[NSUserDefaults standardUserDefaults] objectForKey:@"ScheduleData"];
        if (scheduleDataObj) {
            NSDictionary *scheduleDataDict = (NSDictionary*)scheduleDataObj;
            self.segmentsTextArray = [scheduleDataDict objectForKey:@"segmentsTextArray"];
            self.program_date = [scheduleDataDict objectForKey:@"program_date"];
            
            [self.segmentedControl resetAllSegments:self.segmentsTextArray];
        }
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"ScheduleData"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    NSInteger segmentsIndex = [self.segmentsTextArray indexOfObject:selectedSegmentText];
    [self setSegmentedAndTableWithIndex:segmentsIndex];
}

- (void)setSegmentedAndTableWithIndex:(NSInteger)selectedSegmentIndex {
    [self.segmentedControl setSelectedSegmentIndex:selectedSegmentIndex];
    NSString *selectedDate = [self.segmentsTextArray objectAtIndex:selectedSegmentIndex];
    [self.segmentedLabel setText:[NSString stringWithFormat:NSLocalizedString(@"ScheduleOfDate", nil), selectedDate]];
    
    static NSDateFormatter *formatter_full = nil;
    if (formatter_full == nil) {
        formatter_full = [NSDateFormatter new];
        [formatter_full setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
        [formatter_full setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    }
    
    static NSDateFormatter *formatter_HHmm = nil;
    if (formatter_HHmm == nil) {
        formatter_HHmm = [NSDateFormatter new];
        [formatter_HHmm setDateFormat:@"HH:mm"];
    }
    
    static NSDate *startTime;
    static NSDate *endTime;
    static NSString *startTime_str;
    static NSString *endTime_str;
    static NSString *timeKey;
    
    NSMutableDictionary *sectionDict = [NSMutableDictionary new];
    
    for (NSDictionary *program in [self.program_date objectForKey:selectedDate]) {
        startTime = [formatter_full dateFromString:[program objectForKey:@"starttime"]];
        endTime = [formatter_full dateFromString:[program objectForKey:@"endtime"]];
        startTime_str = [formatter_HHmm stringFromDate:startTime];
        endTime_str = [formatter_HHmm stringFromDate:endTime];
        timeKey = [NSString stringWithFormat:@"%@ ~ %@", startTime_str, endTime_str];
        
        NSMutableArray *tempArray = [sectionDict objectForKey:timeKey];
        if (tempArray == nil) {
            tempArray = [NSMutableArray new];
        }
        [tempArray addObject:program];
        [sectionDict setObject:tempArray forKey:timeKey];
    }
    
    self.program_date_section = sectionDict;
    
    [self.tableView reloadData];
}

- (void)checkScheduleDate {
    static NSDateFormatter *formatter_s = nil;
    if (formatter_s == nil) {
        formatter_s = [NSDateFormatter new];
        [formatter_s setDateFormat:@"MM/dd"];
    }
    
    if ([self.segmentedControl selectedSegmentIndex] == -1) {
        NSInteger segmentsIndex = 0;
        for (int index = 0; index < [self.segmentsTextArray count]; ++index) {
            if ([[formatter_s stringFromDate:[NSDate new]] isEqualToString:[self.segmentsTextArray objectAtIndex:index]]) {
                segmentsIndex = index;
            }
        }
        [self setSegmentedAndTableWithIndex:segmentsIndex];
    }
}

- (void)segmentedControlValueDidChange:(UISegmentedControl *)segment {
    [self setSegmentedAndTableWithIndex:segment.selectedSegmentIndex];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UIViewController *destination = segue.destinationViewController;
//    NSString *title = [sender text];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    if ([destination isMemberOfClass:[ProgramDetailViewController class]]) {
        ProgramDetailViewController *pdvc = (ProgramDetailViewController *)destination;
        NSArray *allKeys = [[self.program_date_section allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        NSDictionary *program = [[self.program_date_section objectForKey:[allKeys objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
        [pdvc setProgram:program];
        SEND_GAI_EVENT(@"ScheduleViewController", [program objectForKey:@"slot"]);
    }
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

// Somewhere in your implementation file:

#pragma mark - Table view data source

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self setTableViewInset:scrollView isInit:NO];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [nilCoalesceDefault(self.program_date_section, @{}) count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *allKeys = [[nilCoalesceDefault(self.program_date_section, @{}) allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSString *key = [allKeys count] > section ? [allKeys objectAtIndex:section] : nil;
    return key != nil ? [[nilCoalesceDefault(self.program_date_section, @{}) objectForKey:key] count] : 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSArray *allKeys = [[nilCoalesceDefault(self.program_date_section, @{}) allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSString *key = [allKeys count] > section ? [allKeys objectAtIndex:section] : nil;
    return nilCoalesce(key);
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *titleString = [self tableView:tableView titleForHeaderInSection:section];
    
    UIView *sectionView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.bounds.size.width, 28.0f)];
    [sectionView setBackgroundColor:[UIColor colorWithRed:61.0f/255.0f
                                                    green:152.0f/255.0f
                                                     blue:60.0f/255.0f
                                                    alpha:1.0f]];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectInset(sectionView.frame, 20.0f, 4.0f)];
    [titleLabel setFont:[UIFont systemFontOfSize:18.0f
                                          weight:UIFontWeightMedium]];
    [titleLabel setTextAlignment:NSTextAlignmentLeft];
    [titleLabel setTextColor:[UIColor whiteColor]];
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    
    // set font Monospaced
    NSArray *monospacedSetting = @[@{UIFontFeatureTypeIdentifierKey: @(kNumberSpacingType),
                                     UIFontFeatureSelectorIdentifierKey: @(kMonospacedNumbersSelector)}];
    UIFontDescriptor *newDescriptor = [[titleLabel.font fontDescriptor] fontDescriptorByAddingAttributes:@{UIFontDescriptorFeatureSettingsAttribute: monospacedSetting}];
    // Size 0 to use previously set font size
    titleLabel.font = [UIFont fontWithDescriptor:newDescriptor size:0];
    
    [titleLabel setText:titleString];
    [sectionView addSubview:titleLabel];
    
    return sectionView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Configure the cell...
    NSString *scheduleCellName = @"ScheduleCell";
    
    ScheduleViewCell *cell = (ScheduleViewCell *)[tableView dequeueReusableCellWithIdentifier:scheduleCellName];
    
    NSArray *allKeys = [[self.program_date_section allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSDictionary *program = [[self.program_date_section objectForKey:[allKeys objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
    
    [cell.ScheduleTitleLabel setText:[program objectForKey:@"subject"]];
    [cell.RoomLocationLabel setText:[program objectForKey:@"room"]];
    
    return cell;
}

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    [[self.tableView cellForRowAtIndexPath:indexPath] setSelected:NO
//                                                         animated:YES];
//    // TODO: display selected section detail informations
//    
//    NSArray *allKeys = [[self.program_date_section allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
//    NSDictionary *program = [[self.program_date_section objectForKey:[allKeys objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
//    
//    ProgramDetailViewController *detailViewController = [[ProgramDetailViewController alloc] initWithNibName:@"ProgramDetailViewController"
//                                                                                                      bundle:[NSBundle mainBundle]
//                                                                                                     Program:program];
//    [self.navigationController pushViewController:detailViewController animated:YES];
//    
//    SEND_GAI_EVENT(@"ScheduleViewController", [program objectForKey:@"slot"]);
//}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

@end
