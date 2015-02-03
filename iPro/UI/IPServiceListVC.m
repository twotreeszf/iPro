//
//  IPServiceListVC.m
//  iPro
//
//  Created by zhang fan on 15/2/3.
//  Copyright (c) 2015年 twotrees. All rights reserved.
//

#import "IPServiceListVC.h"
#import "IPCaptureDataDef.h"
#import "UIViewController+Visible.h"
#import "IPServiceListCell.h"
#import "NSNetService+ParseAddress.h"
#import "IPRemoteControlVC.h"

@interface IPServiceListVC () <NSNetServiceBrowserDelegate, NSNetServiceDelegate>
{
	NSMutableArray*			_tempList;
	NSMutableArray*			_serviceList;
	NSNetServiceBrowser*	_netServiceBrowser;
}

@end

@implementation IPServiceListVC

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	_tempList = [NSMutableArray new];
	_serviceList = [NSMutableArray new];
	
	_netServiceBrowser = [NSNetServiceBrowser new];
	[_netServiceBrowser setDelegate:self];
	[_netServiceBrowser searchForServicesOfType:kServiceType inDomain:@""];
}

- (void)viewDidAppear:(BOOL)animated
{
	[self.tableView reloadData];
}

- (void)dealloc
{
	[_netServiceBrowser stop];
}

#pragma mark - Table view
- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return _serviceList.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    IPServiceListCell* cell = (IPServiceListCell*)[tableView dequeueReusableCellWithIdentifier:@"ServiceCell" forIndexPath:indexPath];
	
	NSNetService* service = _serviceList[indexPath.row];
	cell.serviceName.text = service.hostName;

	ParseAddressItem* addr = [service firstIPV4Address];
	cell.serviceDetail.text = [NSString stringWithFormat:@"%@:%d", addr.address, addr.port];

    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"RemoteControl"])
	{
		IPRemoteControlVC* destVC = (IPRemoteControlVC*)segue.destinationViewController;
		
		int index = [self.tableView indexPathForCell:sender].row;
		ParseAddressItem* item = [((NSNetService*)_serviceList[index]) firstIPV4Address];
		destVC.serverURL = [NSString stringWithFormat:@"http://%@:%d/", item.address, item.port];
	}
}

#pragma mark - NetService Delegate
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
	[_tempList addObject:aNetService];
	[aNetService setDelegate:self];
	[aNetService resolveWithTimeout:3.0];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
	[_tempList removeObject:aNetService];
	[_serviceList removeObject:aNetService];
	
	if ([self visible])
		[self.tableView reloadData];
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
	[_tempList removeObject:sender];
	[_serviceList addObject:sender];
	
	if ([self visible])
		[self.tableView reloadData];
}

@end
