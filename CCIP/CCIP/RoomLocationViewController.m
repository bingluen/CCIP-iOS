//
//  RoomLocationViewController.m
//  CCIP
//
//  Created by FrankWu on 2016/7/3.
//  Copyright © 2016年 FrankWu. All rights reserved.
//

#import "AppDelegate.h"
#import "RoomLocationViewController.h"
#import "RoomProgramsTableViewController.h"
#import "GatewayWebService/GatewayWebService.h"
#import "NSInvocation+addition.h"
#import "UIColor+addition.h"

@interface RoomLocationViewController () <ViewPagerDataSource, ViewPagerDelegate>

@end

@implementation RoomLocationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dataSource = self;
    self.delegate = self;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    GatewayWebService *roome_ws = [[GatewayWebService alloc] initWithURL:ROOM_DATA_URL];
    [roome_ws sendRequest:^(NSArray *json, NSString *jsonStr, NSURLResponse *response) {
        if (json != nil) {
            NSLog(@"%@", json);
            self.rooms = json;
        }
    }];
    
    GatewayWebService *program_ws = [[GatewayWebService alloc] initWithURL:PROGRAM_DATA_URL];
    [program_ws sendRequest:^(NSArray *json, NSString *jsonStr, NSURLResponse *response) {
        if (json != nil) {
            NSLog(@"%@", json);
            self.roomPrograms = json;
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - ViewPagerDataSource
- (NSUInteger)numberOfTabsForViewPager:(ViewPagerController *)viewPager {
    return [self.rooms count] + 1;
}

#pragma mark - ViewPagerDataSource
- (UIView *)viewPager:(ViewPagerController *)viewPager viewForTabAtIndex:(NSUInteger)index {
    UILabel *label = [UILabel new];
    label.backgroundColor = [UIColor clearColor];
    
    if (index == 0) {
        label.text = NSLocalizedString(@"All", nil);
    } else {
        NSString *language = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
        if ([language isEqualToString:@"zh-Hant"]) {
            label.text = [[self.rooms objectAtIndex:index-1] objectForKey:@"name"];
        } else {
            label.text = [[self.rooms objectAtIndex:index-1] objectForKey:@"room"];
        }
    }

    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor];
    [label sizeToFit];
    
    return label;
}

#pragma mark - ViewPagerDataSource
- (UIViewController *)viewPager:(ViewPagerController *)viewPager contentViewControllerForTabAtIndex:(NSUInteger)index {
    
    RoomProgramsTableViewController *roomProgramsTableView = [RoomProgramsTableViewController new];
    NSString *room = [NSString new];
    NSArray *programs = [NSArray new];
    
    if (index == 0) {
        room = @"all";
        programs = self.roomPrograms;
    } else {
        room = [[self.rooms objectAtIndex:index-1] objectForKey:@"room"];
        
        NSMutableArray *programsArray  = [NSMutableArray new];
        for (NSDictionary *dict in self.roomPrograms) {
            if ([[dict objectForKey:@"room"] isEqualToString:room]) {
                [programsArray addObject:dict];
            }
        }
        
        programs = programsArray;
    }
    
    [NSInvocation InvokeObject:roomProgramsTableView
            withSelectorString:@"setRoom:"
                 withArguments:@[ room ]];
    
    [NSInvocation InvokeObject:roomProgramsTableView
            withSelectorString:@"setPrograms:"
                 withArguments:@[ programs ]];
    
    return roomProgramsTableView;
}

#pragma mark - ViewPagerDelegate
- (void)viewPager:(ViewPagerController *)viewPager didChangeTabToIndex:(NSUInteger)index {
    // Do something useful
}

#pragma mark - ViewPagerDelegate
- (CGFloat)viewPager:(ViewPagerController *)viewPager valueForOption:(ViewPagerOption)option withDefault:(CGFloat)value {
    switch (option) {
        case ViewPagerOptionStartFromSecondTab:
            return 1.0;
        case ViewPagerOptionCenterCurrentTab:
            return 1.0;
        case ViewPagerOptionTabLocation:
            return 0.0;
        //case ViewPagerOptionTabHeight:
        //    return 49.0;
        //case ViewPagerOptionTabOffset:
        //    return 36.0;
        case ViewPagerOptionTabWidth:
            return UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) ? 240.0f : ([[UIScreen mainScreen] bounds].size.width/3);
        //case ViewPagerOptionFixFormerTabsPositions:
        //    return 1.0;
        //case ViewPagerOptionFixLatterTabsPositions:
        //    return 1.0;
        default:
            return value;
    }
}

- (UIColor *)viewPager:(ViewPagerController *)viewPager colorForComponent:(ViewPagerComponent)component withDefault:(UIColor *)color {
    switch (component) {
        case ViewPagerIndicator: {
            //return [[UIColor redColor] colorWithAlphaComponent:0.64]; //default
            //return [UIColor colorFromHtmlColor:@"#576"]; //Colore from Web Side
            return [[AppDelegate appDelegate].appArt secondaryColor];
        }
        /*
        case ViewPagerTabsView: {
            return [UIColor whiteColor];
        }
        case ViewPagerContent: {
            return [UIColor whiteColor];
        }
        */
        default: {
            return color;
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    SEND_GAI(@"RoomLocationView");
}

@end
