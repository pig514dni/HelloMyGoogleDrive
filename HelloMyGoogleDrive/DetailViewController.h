//
//  DetailViewController.h
//  HelloMyGoogleDrive
//
//  Created by 張峻綸 on 2016/8/9.
//  Copyright © 2016年 張峻綸. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <GTLDrive.h>


@interface DetailViewController : UIViewController

@property (strong,nonatomic) GTLServiceDrive *drive;

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end

