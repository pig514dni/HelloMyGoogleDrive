//
//  MasterViewController.m
//  HelloMyGoogleDrive
//
//  Created by 張峻綸 on 2016/8/9.
//  Copyright © 2016年 張峻綸. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"

#import <GTLDrive.h>
#import <GTMOAuth2ViewControllerTouch.h>

#define KEYCHAIN_ITEM_NAME @"AllenGoogleDrive"

#define CLIENT_ID @"填入Google Drive ID"



@interface MasterViewController ()
{
    GTLServiceDrive *drive;
}
@property NSMutableArray *objects;

@end

@implementation MasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    // Prepare objects
    _objects = [NSMutableArray new];
    
    // Prepare GTLServiceDrive
    drive = [GTLServiceDrive new];
    drive.authorizer = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:KEYCHAIN_ITEM_NAME clientID:CLIENT_ID clientSecret:nil];
    if ([drive.authorizer canAuthorize] == false) {
        // Need Login
        //initWithScope:kGTLAuthScopeDriveFile為只會拿到這個APP上傳的檔案
        GTMOAuth2ViewControllerTouch * controller = [[GTMOAuth2ViewControllerTouch alloc] initWithScope:kGTLAuthScopeDriveFile clientID:CLIENT_ID clientSecret:nil keychainItemName:KEYCHAIN_ITEM_NAME completionHandler:^(GTMOAuth2ViewControllerTouch *viewController, GTMOAuth2Authentication *auth, NSError *error) {
            if (error) {
                NSLog(@"Auth Fail: %@",error);
                drive.authorizer = nil;
            }else{
                NSLog(@"Auth OK.");
                drive.authorizer = auth;
                [self downloadFileList];
            }
        }];
        [self.navigationController pushViewController:controller animated:true];
    }else {
        // AKready Login
        [self downloadFileList];
    }
}

-(void) downloadFileList {
    //Google不會使用分頁的情況給值
    drive.shouldFetchNextPages = true;
    
    GTLQueryDrive *query = [GTLQueryDrive queryForFilesList];
    //拿到從root根目錄的所有文件
    query.q = [NSString stringWithFormat:@"'%@' IN parents",@"root"];
    
    [drive executeQuery:query completionHandler:^(GTLServiceTicket *ticket, GTLDriveFileList *items, NSError *error) {
        if (error) {
            NSLog(@"Download File List Fail: %@",error);
        }else{
            [_objects removeAllObjects];
            for (GTLDriveFile *tmp in items.files) {
                NSLog(@"File: %@",tmp.description);
                [_objects addObject:tmp];
            }
            [self.tableView reloadData];
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertNewObject:(id)sender {
    
    // Prepare Upload Data
    NSURL * fileURL = [[NSBundle mainBundle]URLForResource:@"3.jpg" withExtension:nil];
    NSData *data = [NSData dataWithContentsOfURL:fileURL];
    // Prepare GTLDriveFile
    GTLDriveFile *file = [GTLDriveFile new];
    // 檔案名稱 GoogleDrive的檔案名稱可以重複
    file.name = [NSString stringWithFormat:@"KentClass_%@",[NSDate date]];
    // 檔案分類類別名稱
    file.descriptionProperty = @"KentClassFile";
    // GoogleDrive 因沒有檔案類型,需用mimeType給Drive知道是什麼類型
    file.mimeType = @"image/jpg";
    
    // Prepare Parameters
    GTLUploadParameters *parameters = [GTLUploadParameters uploadParametersWithData:data MIMEType:file.mimeType];
    GTLQueryDrive *query = [GTLQueryDrive queryForFilesCreateWithObject:file uploadParameters:parameters];
    // Preform Upload Job
    [drive executeQuery:query completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
        
        if (error) {
            NSLog(@"Upload Fail: %@",error);
        }else{
            NSLog(@"Upload OK.");
            [self downloadFileList];
        }
    }];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        GTLDriveFile *object = self.objects[indexPath.row];
        DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
        //把拿到的文件陣列傳給DetailViewController
        [controller setDetailItem:object];
        //把認證過的帳號傳給DetailViewController
        controller.drive = drive;
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    GTLDriveFile *file = self.objects[indexPath.row];
    cell.textLabel.text = file.name;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        GTLDriveFile *file = _objects[indexPath.row];
        GTLQueryDrive *query = [GTLQueryDrive queryForFilesDeleteWithFileId:file.identifier];
        
        [drive executeQuery:query completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
            if (error) {
                NSLog(@"Delect Fail: %@",error);;
            }else{
                NSLog(@"Delect OK.");
                [self downloadFileList];
            }
        }];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

@end
