//
//  SponsorTableViewController.m
//  CCIP
//
//  Created by Sars on 8/6/16.
//  Copyright © 2016 CPRTeam. All rights reserved.
//

#import "SponsorTableView.h"
#import "SponsorTableViewCell.h"
#import "AppDelegate.h"
#import "GatewayWebService/GatewayWebService.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <SafariServices/SafariServices.h>

@interface SponsorTableView ()

@end

@implementation SponsorTableView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self registerNib:[UINib nibWithNibName:@"SponsorTableViewCell" bundle:nil] forCellReuseIdentifier:@"SponsorCell"];
    
    self.delegate = self;
    self.dataSource = self;
    
    GatewayWebService *sponsor_level_ws = [[GatewayWebService alloc] initWithURL:SPONSOR_LEVEL_URL];
    [sponsor_level_ws sendRequest:^(NSArray *json, NSString *jsonStr, NSURLResponse *response) {
        if (json != nil) {
            self.sponsorLevelJsonArray = json;
            NSMutableArray *sponsorListArray = [[NSMutableArray alloc] init];
            
            for (NSInteger i=0; i<[self.sponsorLevelJsonArray count]; ++i) {
                [sponsorListArray addObject:[[NSMutableArray alloc] init]];
            }
            
            GatewayWebService *sponsor_list_ws = [[GatewayWebService alloc] initWithURL:SPONSOR_LIST_URL];
            [sponsor_list_ws sendRequest:^(NSArray *json, NSString *jsonStr, NSURLResponse *response) {
                if (json != nil) {
                    for (NSDictionary *sponsor in json) {
                        NSString *levelStr = [sponsor objectForKey:@"level"];
                        NSNumber *number = [NSNumber numberWithLongLong: levelStr.longLongValue];
                        NSUInteger level = number.unsignedIntegerValue - 1;
                        [[sponsorListArray objectAtIndex:level] addObject:sponsor];
                    }
                    
                    for (NSDictionary *sponsorLevel in self.sponsorLevelJsonArray) {
                        NSInteger index = [self.sponsorLevelJsonArray indexOfObject:sponsorLevel];
                        NSMutableArray *oldSponsorListArray = [sponsorListArray objectAtIndex:index];
                        NSDictionary *temp;
                        for (int i = 0; i < [oldSponsorListArray count]; i++)
                        {
                            for (int j = 0; j < [oldSponsorListArray count] - 1 - i; j++) {
                                NSInteger thisPlace = [[[oldSponsorListArray objectAtIndex:j] valueForKey:@"place"] integerValue];
                                NSInteger nextPlace = [[[oldSponsorListArray objectAtIndex:j + 1] valueForKey:@"place"] integerValue];
                                if (thisPlace > nextPlace)
                                {
                                    temp = [oldSponsorListArray objectAtIndex:j];
                                    [oldSponsorListArray replaceObjectAtIndex:j withObject:[oldSponsorListArray objectAtIndex:j+1]];
                                    [oldSponsorListArray replaceObjectAtIndex:j + 1 withObject:temp];
                                }
                            }
                            [sponsorListArray replaceObjectAtIndex:index withObject:oldSponsorListArray];
                        }
                    }
                    
                    self.sponsorArray = sponsorListArray;
                    
                    [self beginUpdates];
                    
                    [self insertSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self.sponsorLevelJsonArray count])]
                        withRowAnimation:UITableViewRowAnimationFade];
                    
                    NSMutableArray *indexPaths = [NSMutableArray new];
                    for (int sectionNum = 0; sectionNum < [self.sponsorLevelJsonArray count]; sectionNum++) {
                        for (int rowNum = 0; rowNum < [[self.sponsorArray objectAtIndex:sectionNum] count]; rowNum++) {
                            [indexPaths addObject:[NSIndexPath indexPathForRow:rowNum
                                                                     inSection:sectionNum]];
                        }
                    }
                    [self insertRowsAtIndexPaths:indexPaths
                                withRowAnimation:UITableViewRowAnimationFade];
                    
                    [self endUpdates];
                    //[self reloadData];
                }
            }];
        }
    }];
    
    SEND_GAI(@"SponsorTableView");
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.sponsorLevelJsonArray count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self.sponsorArray objectAtIndex:section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDictionary *level = [self.sponsorLevelJsonArray objectAtIndex:section];
    NSString* language = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
    if ([language containsString:@"zh"]) {
        return [level objectForKey:@"namezh"];
    } else {
        return [level objectForKey:@"nameen"];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString* language = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
    SponsorTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SponsorCell" forIndexPath:indexPath];
    
    if ([language containsString:@"zh"]) {
        cell.sponsorTitle.text = [[[self.sponsorArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"namezh"];
    } else {
        cell.sponsorTitle.text = [[[self.sponsorArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"nameen"];
    }
    
    NSString *logo = [NSString stringWithFormat:@"%@%@", COSCUP_WEB_URL, [[[self.sponsorArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"logourl"]];
    [cell.sponsorImg sd_setImageWithURL:[NSURL URLWithString:logo] placeholderImage:nil options:SDWebImageRetryFailed];
    
    return cell;
}

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

#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *url = [[[self.sponsorArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"logolink"];
    if (![url hasPrefix:@"http://"] && ![url hasPrefix:@"https://"]) {
        url = [@"http://" stringByAppendingString:url];
    }
    
    if ([SFSafariViewController class] != nil) {
        // Open in SFSafariViewController
        SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:url]];        
        [[UIApplication getMostTopPresentedViewController] presentViewController:safariViewController
                                                                        animated:YES
                                                                      completion:nil];
    } else {
        // Open in Mobile Safari
        if (![[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]]) {
            NSLog(@"%@%@",@"Failed to open url:", [[NSURL URLWithString:url] description]);
        }
    }
    
    SEND_GAI_EVENT(@"SponsorTableView", url);
    // Navigation logic may go here, for example:
    // Create the next view controller.
    //<#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:<#@"Nib name"#> bundle:nil];
    
    // Pass the selected object to the new view controller.
    
    // Push the view controller.
    //[self.navigationController pushViewController:detailViewController animated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
