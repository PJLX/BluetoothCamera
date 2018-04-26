//
//  TBPeripheralListVC.m
//  TakePhotoByBluetooth
//
//  Created by 李响 on 2017/6/23.
//  Copyright © 2017年 LiXiang. All rights reserved.
//

#import "TBPeripheralListVC.h"

#import "TBPeripheralListVCCell.h"

#import <CoreBluetooth/CoreBluetooth.h>

@interface TBPeripheralListVC ()
<
UITableViewDelegate,
UITableViewDataSource
>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSArray *PeripheralArr;

@end

@implementation TBPeripheralListVC

+ (instancetype)loadWithPeripheralList:(NSArray *)peripheralList{
    TBPeripheralListVC *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"TBPeripheralListVC"];
    vc.PeripheralArr = [NSArray arrayWithArray:peripheralList];
    return vc;
}

- (void)reloadData:(NSArray *)peripheralList{
    self.PeripheralArr = peripheralList;
    [self.tableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"请选择设备";
    
    [self.tableView reloadData];
}

- (IBAction)cancelAction:(UIButton *)sender {
    if (self.cancel) {
        self.cancel();
    }
}


#pragma mark - UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.PeripheralArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    TBPeripheralListVCCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TBPeripheralListVCCell" forIndexPath:indexPath];
    CBPeripheral *peripheral = self.PeripheralArr[indexPath.row];
    cell.nameLabel.text = peripheral.name;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (self.didSelectDevice) {
        CBPeripheral *peripheral = self.PeripheralArr[indexPath.row];
        self.didSelectDevice(peripheral.name);
    }
}



@end
