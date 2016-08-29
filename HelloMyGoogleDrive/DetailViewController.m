//
//  DetailViewController.m
//  HelloMyGoogleDrive
//
//  Created by 張峻綸 on 2016/8/9.
//  Copyright © 2016年 張峻綸. All rights reserved.
//

#import "DetailViewController.h"

@interface DetailViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;

@end

@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem {
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
            
        // Update the view.
        [self configureView];
    }
}

- (void)configureView {
    // Update the user interface for the detail item.
    //當self.detailItem有被傳值過來&&self.photoImageView有被創照出來才做事
    if (self.detailItem && self.photoImageView) {
        
        GTLDriveFile *file = _detailItem;
        self.title = file.name;
        
        NSString * urlString = [NSString stringWithFormat:@"https://www.googleapis.com/drive/v2/files/%@?alt=media",file.identifier];
        
        GTMSessionFetcher * fetcher = [_drive.fetcherService fetcherWithURLString:urlString];
        [fetcher beginFetchWithCompletionHandler:^(NSData * _Nullable data, NSError * _Nullable error) {
            if (error) {
                NSLog(@"Download Fail: %@",error);
            }else {
                _photoImageView.image = [UIImage imageWithData:data];
            }
        }];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
