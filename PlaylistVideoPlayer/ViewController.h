//
//  ViewController.h
//  PlaylistVideoPlayer
//
//  Created by Stefano Russello on 20/01/18.
//  Copyright © 2018 Stefano Russello. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AFNetworking/AFNetworking.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
    AVPlayer *videoPlayer;
    AVPlayerViewController *videoController;
    NSArray *aPlaylist;
    NSMutableArray<AVPlayerItem*> *playlistItems;
    long currentVideo;
    
    UIButton *btnPrev;
    UIButton *btnNext;
    NSTimer *tmrTap;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

