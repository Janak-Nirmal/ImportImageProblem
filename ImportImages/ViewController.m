//
//  ViewController.m
//  ImportImages
//
//  Created by Jennis on 11/03/14.
//  Copyright (c) 2014 Jennis. All rights reserved.
//

#import "ViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface ViewController ()

@property (strong, nonatomic) IBOutlet UIView *importStatusView;
@property (strong, nonatomic) IBOutlet UILabel *lblImportCountStatus;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnImportTapped:(id)sender {
    ZCImagePickerController *imagePickerController = [[ZCImagePickerController alloc] init];
    imagePickerController.imagePickerDelegate = self;
    imagePickerController.mediaType = ZCMediaAllPhotos;
    [self presentViewController:imagePickerController animated:YES completion:NULL];
}

- (void)zcImagePickerControllerDidCancel:(ZCImagePickerController *)imagePickerController {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)zcImagePickerController:(ZCImagePickerController *)imagePickerController didFinishPickingMediaWithInfo:(NSArray *)info {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;

    _importStatusView.center = self.view.center;
    [self.view addSubview:_importStatusView];
    [self dismissViewControllerAnimated:YES completion:^{
        NSNumber *total = [NSNumber numberWithInteger:info.count];
        [info enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSDictionary *imageInfo = (NSDictionary*)obj;
            NSString *fileName = [imageInfo objectForKey:@"UIImagePickerControllerFileName"];
            NSURL *imageURL = [imageInfo objectForKey:UIImagePickerControllerReferenceURL];
            ALAssetsLibrary *assetLibrary=[[ALAssetsLibrary alloc] init];
            [assetLibrary assetForURL:imageURL resultBlock:^(ALAsset *asset) {
                NSLog(@"start");
                ALAssetRepresentation *rep = [asset defaultRepresentation];
                Byte *buffer = (Byte*)malloc(rep.size);
                NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:rep.size error:nil];
                NSData *data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
                
                
                NSString *filePath = [basePath stringByAppendingPathComponent:fileName];
                [data writeToFile:filePath atomically:YES];
                
                //This also has no effect
                //dispatch_async(dispatch_get_main_queue(), ^{
                //_lblImportCountStatus.text = [NSString stringWithFormat:@"%d of %d",idx+1,[total integerValue]];
                //NSLog(@"Label value->%@",_lblImportCountStatus.text); //This prints values but after everything is finished it prints all line at once i.e. at the end of the enumeration of all items
                //});
                
                //Update UI
                NSNumber *current = [NSNumber numberWithInteger:idx+1];
                NSDictionary *status = [NSDictionary dictionaryWithObjectsAndKeys:current,@"current", total,@"totalCount", nil];
                [self performSelectorOnMainThread:@selector(updateImportCount:) withObject:status waitUntilDone:YES];
                
                if(idx==info.count-1){
                    [_importStatusView removeFromSuperview];
                }
                
                NSLog(@"Finish");
            } failureBlock:^(NSError *error) {
                NSLog(@"Error: %@",[error localizedDescription]);
            }];
        }];
    }];
}

-(void)updateImportCount:(NSDictionary*)info{ //(NSNumber*)current forTotalItems:(NSNumber*)totalCount{
    NSNumber *current = [info objectForKey:@"current"];
    NSNumber *totalCount = [info objectForKey:@"totalCount"];
    NSLog(@"_lblImportCountStatus-->%@  before text->%@",_lblImportCountStatus,_lblImportCountStatus.text);
    _lblImportCountStatus.text = [NSString stringWithFormat:@"%d of %d",[current integerValue],[totalCount integerValue]];
    [_lblImportCountStatus setNeedsDisplay];
    [_importStatusView layoutIfNeeded];
    NSLog(@"_lblImportCountStatus-->%@  after text->%@",_lblImportCountStatus,_lblImportCountStatus.text);
}

@end
