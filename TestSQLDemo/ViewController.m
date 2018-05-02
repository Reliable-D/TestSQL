//
//  ViewController.m
//  TestSQLDemo
//
//  Created by 邓乐 on 2018/5/2.
//  Copyright © 2018年 fanli. All rights reserved.
//

#import "ViewController.h"
#import "FLFPasteboardHistoryDao.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *tf;
@property (weak, nonatomic) IBOutlet UITextField *expired;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [FLFPasteboardHistoryDao standardDao];
}

- (IBAction)clickBtn:(UIButton *)sender {
    [[FLFPasteboardHistoryDao standardDao] insertPasteboardToHistoryPasteboard:self.tf.text uid:nil];
}
- (IBAction)clickCleanUp:(UIButton *)sender {
    [[FLFPasteboardHistoryDao standardDao] cleanUpExpiredHistoryWithTimeControl:@(self.expired.text.integerValue)];
}
- (IBAction)clickCheck:(UIButton *)sender {
    [[FLFPasteboardHistoryDao standardDao] isHistoryPasteboard:self.tf.text withExpiredTimeControl:@(self.expired.text.integerValue) uid:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
