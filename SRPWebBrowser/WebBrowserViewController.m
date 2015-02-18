//
//  ViewController.m
//  SRPWebBrowser
//
//  Created by Suhit on 06/02/15.
//  Copyright (c) 2015 com.suhit. All rights reserved.
//

#import "WebBrowserViewController.h"

@interface WebBrowserViewController ()<UIWebViewDelegate, UITextFieldDelegate>

@property(weak, nonatomic) IBOutlet UIWebView *webView;
@property(weak, nonatomic) IBOutlet UITextField *searchTextField;
@property(weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property(weak, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property(weak, nonatomic) IBOutlet UIBarButtonItem *forwardButton;
@property(weak, nonatomic) IBOutlet UIBarButtonItem *refreshButton;
@property(weak, nonatomic) IBOutlet UIBarButtonItem *stopButton;

@property(strong, nonatomic) NSString *urlString;
@property(assign, nonatomic) BOOL pageLoadFinished;
@property(strong, nonatomic) NSTimer *timer;
@property(strong, nonatomic) UIProgressView *progressBar;
@end

@implementation WebBrowserViewController

//White StatusBar 
- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - View Controller LifeCycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.searchTextField.delegate = self;
    self.webView.delegate = self;
    
    [self resetButtons];
    self.progressBar = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 2)];
    self.progressBar.alpha = 1.0f;
    self.progressBar.progressTintColor = [UIColor redColor];
    self.progressBar.trackTintColor = [UIColor clearColor];
    self.progressBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.progressBar];
}

#pragma mark -  WebBrowser private methods

//Update the status of the toolbar buttons
- (void)resetButtons {
    self.cancelButton.enabled = NO;
    self.backButton.enabled = self.webView.canGoBack;
    self.forwardButton.enabled = self.webView.canGoForward;
    if(self.webView.loading) {
        
        self.refreshButton.enabled = NO;
        self.stopButton.enabled = YES;
        
    } else if ([self.searchTextField.text isEqualToString:@""]){
        
        self.refreshButton.enabled = NO;
        self.stopButton.enabled = NO;
        
    } else {
        self.refreshButton.enabled = YES;
        self.stopButton.enabled = NO;
    }
}

//Load the Web Page
- (void)loadWebPage:(NSString *)string {
    if ([string rangeOfString:@"http://" options:NSCaseInsensitiveSearch].location != NSNotFound ) {
        self.urlString = string;
    } else {
        self.urlString = [@"http://" stringByAppendingPathComponent:string];
    }
    NSURL *url = [NSURL URLWithString:self.urlString];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:30.0f];
    [self.webView loadRequest:request];
}

- (IBAction)cancelSearch:(UIBarButtonItem *)sender {
    [self.searchTextField resignFirstResponder];
    [self resetButtons];
}

- (IBAction)back:(UIBarButtonItem *)sender {
    if(self.webView.canGoBack) {
        [self.webView goBack];
    }
}

- (IBAction)forward:(UIBarButtonItem *)sender {
    if (self.webView.canGoForward) {
        [self.webView goForward];
    }
}

- (IBAction)refreshPage:(UIBarButtonItem *)sender {
    if (!self.webView.loading) {
        [self.webView reload];
    }
}

- (IBAction)stopLoading:(UIBarButtonItem *)sender {
    if(self.webView.loading) {
        [self.webView stopLoading];
        self.progressBar.progress = 0;
        [self.timer invalidate];
        self.pageLoadFinished = NO;
    }
}

//timer
- (void)timerCallBack {
    if (self.pageLoadFinished) {
        if (self.progressBar.progress >= 1) {
            self.progressBar.hidden = true;
            [self.timer invalidate];
        } else {
            self.progressBar.progress += 0.1;
        }
    } else {
        self.progressBar.progress += 0.005;
        if (self.progressBar.progress >= 0.95) {
            self.progressBar.progress = 0.95;
        }
    }
}

- (void)resetProgressbar {
    self.progressBar.progress = 0;
    self.pageLoadFinished = false;
}


#pragma mark - UIWebView Delegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *url = request.URL;
    self.searchTextField.text = url.absoluteString;
    return true;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self resetProgressbar];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.0167 target:self selector:@selector(timerCallBack) userInfo:nil repeats:YES];
    [self resetButtons];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.pageLoadFinished = YES;
    [self resetButtons];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"error: %@",error.localizedDescription);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self resetProgressbar];
    [self.timer invalidate];
    [self resetButtons];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

#pragma mark - UITextField Delegate
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.cancelButton.enabled = YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    return YES;
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    [self.searchTextField resignFirstResponder];
    
    if(![self.searchTextField.text isEqualToString:@""] && [self.searchTextField.text length] > 0) {
        [self loadWebPage:self.searchTextField.text];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Empty URL" message:@"Please enter the correct URL in search box" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
    
    [self resetButtons];
    return NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end


