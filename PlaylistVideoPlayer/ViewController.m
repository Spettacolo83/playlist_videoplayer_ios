//
//  ViewController.m
//  PlaylistVideoPlayer
//
//  Created by Stefano Russello on 20/01/18.
//  Copyright © 2018 Stefano Russello. All rights reserved.
//

#import "ViewController.h"

// Playlist JSON webservice
#define SERVER_API_URL @"http://www.followmemobile.com/rest/api/videoplayer?transform=1"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Setting status bar color and appearance
    [self.view setBackgroundColor:[UIColor colorWithRed:19./255. green:87./255. blue:155./255. alpha:1.0]];
 
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
}

- (BOOL)prefersStatusBarHidden {
    return [self.navigationController prefersStatusBarHidden];
}

- (void)viewDidAppear:(BOOL)animated {
    
    // Starting loading dialog
    [MBProgressHUD showHUDAddedTo:self.view animated:YES].label.text = @"Loading playlist...";
    
    // Downloading JSON Async mdoe
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self downloadPlaylist];
    });
}

- (void)downloadPlaylist
{
    // Creating webservice request
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:SERVER_API_URL]];
    
    NSString *authStr = @"followmemobile:elibomemwollof";
    NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
    NSString *authValue = [NSString stringWithFormat: @"Basic %@",[authData base64EncodedStringWithOptions:0]];
    [request setValue:authValue forHTTPHeaderField:@"Authorization"];
    
    // Calling webservice
    NSURLSessionDataTask* task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error != nil) {
            // If error occured
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                MBProgressHUD *errorHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                errorHud.mode = MBProgressHUDModeText;
                errorHud.label.text = @"ERROR";
                errorHud.detailsLabel.text = error.localizedDescription;
                [errorHud showAnimated:YES];
                [errorHud hideAnimated:YES afterDelay:4.0];
            });
        } else {
            // Creating array from JSON response
            aPlaylist = [[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil] objectForKey:@"videoplayer"];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                // Refreshing table view and hide loading dialog
                [self.tableView reloadData];
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            });
        }
    }];
    
    [task resume];
}

- (void)openVideo:(long)nPosition
{
    // Called when a video has been tapped from list
    playlistItems = [[NSMutableArray alloc] init];
    // Creating playlist of AVPlayerItem
    for (int i = 0; i < [aPlaylist count]; i++) {
        NSString *urlVideo = [[aPlaylist objectAtIndex:i] objectForKey:@"url"];
        AVPlayerItem *nItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:urlVideo]];
        
        // Subscribe to the AVPlayerItem's DidPlayToEndTime notification.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:nItem];
        
        [playlistItems addObject: nItem];
    }
    
    // Creating AVPlayer and AVPlayerViewController
    videoPlayer = [AVPlayer playerWithPlayerItem:[playlistItems objectAtIndex:nPosition]];
    
    videoController = [[AVPlayerViewController alloc] init];
    videoController.player = videoPlayer;
    [videoController setShowsPlaybackControls:YES];
    [videoController.view setUserInteractionEnabled:YES];
    
    // Showing Player on screen
    [self presentViewController:videoController animated:YES completion:^{
        
        // Creating Next and Prev button
        [self createCustomControl];
        [self tapHandle:NO];
        // Autoplay
        [videoPlayer play];
    }];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (videoController) {
        if (videoController.player) {
            [self tapHandle:NO];
        }
    }
}

- (void)tapHandle:(BOOL)restartShow
{
    // Used for showing Next and Prev button when tapping on screen
    if (tmrTap) {
        [tmrTap invalidate];
        tmrTap = nil;
    }
    
    if (btnPrev.hidden || restartShow) {
        if (!restartShow) [self displayCustomControl:YES];
        tmrTap = [NSTimer scheduledTimerWithTimeInterval:3.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
            [self displayCustomControl:NO];
            [tmrTap invalidate];
            tmrTap = nil;
        }];
    } else {
        [self displayCustomControl:NO];
    }
    
}

- (void)displayCustomControl:(BOOL)show
{
    // Custom buttons alpha animation
    if (show) {
        btnPrev.alpha = 0;
        btnNext.alpha = 0;
        btnPrev.hidden = NO;
        btnNext.hidden = NO;
    }
    
    [UIView animateWithDuration:0.5 animations:^{
        btnPrev.alpha = show ? 1.0 : 0.0;
        btnNext.alpha = show ? 1.0 : 0.0;
    } completion:^(BOOL finished) {
        if (!show) {
            btnPrev.hidden = YES;
            btnNext.hidden = YES;
        }
    }];
}

- (void)createCustomControl
{
    // Creating custom buttons (Next and Prev)
    btnNext = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnNext addTarget:self action:@selector(onTapNext:)
      forControlEvents:UIControlEventTouchUpInside];
    [btnNext setTitle:@"▶︎" forState:UIControlStateNormal];
    btnNext.layer.cornerRadius = 20;
    btnNext.clipsToBounds = YES;
    btnNext.layer.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.4].CGColor;
    btnNext.frame = CGRectMake((self.view.frame.size.width-10),(self.view.frame.size.height-150),100.0,50.0);
    btnNext.hidden = YES;
    
    btnPrev = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnPrev addTarget:self action:@selector(onTapPrev:)
      forControlEvents:UIControlEventTouchUpInside];
    [btnPrev setTitle:@"◀︎" forState:UIControlStateNormal];
    btnPrev.layer.cornerRadius = 20;
    btnPrev.clipsToBounds = YES;
    btnPrev.layer.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.4].CGColor;
    btnPrev.frame = CGRectMake(10,(self.view.frame.size.height-150),100.0,50.0);
    btnPrev.hidden = YES;
    
    [videoController.view addSubview:btnNext];
    [videoController.view addSubview:btnPrev];
    
    btnPrev.translatesAutoresizingMaskIntoConstraints = NO;
    btnNext.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSLayoutConstraint *c1Prev = [NSLayoutConstraint constraintWithItem:videoController.view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:btnPrev attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-10];
    NSLayoutConstraint *c2Prev =[NSLayoutConstraint constraintWithItem:videoController.view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:btnPrev attribute:NSLayoutAttributeBottom multiplier:1.0 constant:130];
    NSLayoutConstraint *ewPrev = [NSLayoutConstraint constraintWithItem:btnPrev attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0 constant:70];
    NSLayoutConstraint *ehPrev = [NSLayoutConstraint constraintWithItem:btnPrev attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0 constant:50];
    
    NSLayoutConstraint *c1Next = [NSLayoutConstraint constraintWithItem:videoController.view attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:btnNext attribute:NSLayoutAttributeRight multiplier:1.0 constant:10];
    NSLayoutConstraint *c2Next =[NSLayoutConstraint constraintWithItem:videoController.view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:btnNext attribute:NSLayoutAttributeBottom multiplier:1.0 constant:130];
    NSLayoutConstraint *ewNext = [NSLayoutConstraint constraintWithItem:btnNext attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0 constant:70];
    NSLayoutConstraint *ehNext = [NSLayoutConstraint constraintWithItem:btnNext attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0 constant:50];
    
    [videoController.view addConstraints:@[c1Prev, c2Prev]];
    [btnPrev addConstraints:@[ewPrev, ehPrev]];
    [videoController.view addConstraints:@[c1Next, c2Next]];
    [btnNext addConstraints:@[ewNext, ehNext]];

}

-(void)onTapPrev:(UIBarButtonItem*)item {
    // Called when tapping on Prev button
    [self changeVideo:currentVideo-1];
    [self tapHandle:YES];
}

-(void)onTapNext:(UIBarButtonItem*)item {
    // Called when tapping on Next button
    [self changeVideo:currentVideo+1];
    [self tapHandle:YES];
}

-(void)itemDidFinishPlaying:(NSNotification *) notification {
    // Will be called when AVPlayer finishes playing playerItem
    [self changeVideo:currentVideo+1];
    [self tapHandle:NO];
}

- (void)changeVideo:(long)nVideo
{
    if (nVideo < aPlaylist.count && nVideo >= 0) {
        // When video changed
        currentVideo = nVideo;
        [videoController.player replaceCurrentItemWithPlayerItem:[playlistItems objectAtIndex:currentVideo]];
        [videoController.player seekToTime:kCMTimeZero];
        [videoController.player play];
    } else {
        // Close Video Player when playlist finished
        [videoController.player replaceCurrentItemWithPlayerItem:nil];
        videoController.player = nil;
        [videoController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    // Creating every single table view cell
    static NSString *cellId = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
        
        cell.textLabel.text = [[aPlaylist objectAtIndex:indexPath.row] objectForKey:@"title"];
        NSInteger sec = [[[aPlaylist objectAtIndex:indexPath.row] objectForKey:@"time"] integerValue] / 1000;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%02ld min %02ld sec", sec / 60, sec % 60];
        
        NSURL *urlThumb = [NSURL URLWithString:[[aPlaylist objectAtIndex:indexPath.row] objectForKey:@"thumbnail"]];
        
        // Loading thumbnail
        NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithURL:urlThumb completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (data) {
                UIImage *image = [UIImage imageWithData:data];
                if (image) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        cell.imageView.image = image;
                        [self.tableView reloadData];
                    });
                }
            }
        }];
        [task resume];
    }
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Called when a cell has been selected
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    currentVideo = (long)indexPath.row;
    [self openVideo: currentVideo];
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return size of playlist
    return [aPlaylist count];
}

@end
