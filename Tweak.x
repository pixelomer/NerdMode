#import <Foundation/Foundation.h>

@class NMNerdModeStatusView;

// Actually, it's Calculator.CalculatorController, but the compiler
// doesn't need to know
@interface CalculatorController : UIViewController
@property (nonatomic, strong) UIView *nerdModeLayer;
@property (nonatomic, assign) BOOL isNerdModeOn;
@property (nonatomic, strong) NMNerdModeStatusView *nerdModeStatusView;
@property (nonatomic, strong) NSTimer *nerdModeHideTimer;
- (BOOL)updateNerdModeIfNeeded;
- (void)nerdModeHideAnimation;
- (NSAttributedString *)makeNerdModeString;
@end

@interface NMNerdModeStatusView : UIView
@property (nonatomic, strong) UILabel *label;
- (void)didMoveToSuperview;
@end

@implementation NMNerdModeStatusView

static const CGFloat statusViewHeight = 27.5;
static const CGFloat statusViewWidth = 150.0;
static UIColor *statusViewBackgroundColor;

+ (void)load {
	if (self == [NMNerdModeStatusView class]) {
		statusViewBackgroundColor = [UIColor
			colorWithRed:0.2
			green:0.2
			blue:0.2
			alpha:1.0
		];
	}
}

- (instancetype)init {
	if ((self = [super init])) {
		self.translatesAutoresizingMaskIntoConstraints = NO;
		self.backgroundColor = [UIColor clearColor];
		self.opaque = NO;
		_label = [UILabel new];
		_label.textColor = [UIColor whiteColor];
		_label.textAlignment = NSTextAlignmentCenter;
		_label.translatesAutoresizingMaskIntoConstraints = NO;
		[self addSubview:_label];
#define equal(anchorname, x) [_label. anchorname constraintEqualToAnchor:self. anchorname x].active = YES
		equal(centerXAnchor, );
		equal(centerYAnchor, );
		equal(topAnchor, constant:5.0);
		equal(bottomAnchor, constant:-5.0);
#undef equal
		[_label.widthAnchor constraintEqualToConstant:(statusViewWidth - statusViewHeight)].active = YES;
		[self setNeedsDisplay];
	}
	return self;
}

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	[statusViewBackgroundColor setFill];

	// Left circle
	{
		UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(
			self.center.x - (statusViewWidth / 2.0),
			0.0,
			statusViewHeight,
			statusViewHeight
		)];
		[path fill];
	}

	// Right circle
	{
		UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(
			self.center.x + (statusViewWidth / 2.0) - statusViewHeight,
			0.0,
			statusViewHeight,
			statusViewHeight
		)];
		[path fill];
	}

	// Rectangle
	{
		UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(
			self.center.x - (statusViewWidth / 2.0) + (statusViewHeight / 2.0),
			0.0,
			statusViewWidth - statusViewHeight,
			statusViewHeight
		)];
		[path fill];
	}
}

- (void)didMoveToSuperview {
	[super didMoveToSuperview];
#define equal(anchorname, c) [self. anchorname constraintEqualToAnchor:self.superview.safeAreaLayoutGuide. anchorname constant:c].active = YES
	equal(topAnchor, 5.0);
	equal(leftAnchor, 0.0);
	equal(rightAnchor, 0.0);
#undef equal
	[self.heightAnchor constraintEqualToConstant:statusViewHeight].active = YES;
}

@end

%hook CalculatorController
%property (nonatomic, strong) UIView *nerdModeLayer;
%property (nonatomic, assign) BOOL isNerdModeOn;
%property (nonatomic, strong) NMNerdModeStatusView *nerdModeStatusView;
%property (nonatomic, strong) NSTimer *nerdModeHideTimer;

%new
- (NSAttributedString *)makeNerdModeString {
	CalculatorController *vc = self;
	NSMutableAttributedString *str = [[NSMutableAttributedString alloc]
		initWithString:@"Nerd Mode: "
		attributes:@{
			NSFontAttributeName : [UIFont
				systemFontOfSize:vc.nerdModeStatusView.label.font.pointSize
			]
		}
	];
	[str appendAttributedString:[[NSAttributedString alloc]
		initWithString:(vc.isNerdModeOn ? @"On" : @"Off")
		attributes:@{
			NSForegroundColorAttributeName : (
				vc.isNerdModeOn ?
				[UIColor greenColor] :
				[UIColor redColor]
			),
			NSFontAttributeName : [UIFont
				boldSystemFontOfSize:vc.nerdModeStatusView.label.font.pointSize
			]
		}
	]];
	return [str copy];
}

// Returns YES if the property changes, NO otherwise
%new
- (BOOL)updateNerdModeIfNeeded {
	CalculatorController *vc = self;
	switch ([[UIApplication sharedApplication] statusBarOrientation]) {
		case UIInterfaceOrientationPortrait:
		case UIInterfaceOrientationPortraitUpsideDown:
			// Nerd mode off
			if (!vc.isNerdModeOn) return NO;
			vc.isNerdModeOn = NO;
			return YES;
		default:
			// Nerd mode on
			if (vc.isNerdModeOn) return NO;
			vc.isNerdModeOn = YES;
			return YES;
	}
}

%new
- (void)nerdModeHideAnimation {
	CalculatorController *vc = self;
	vc.nerdModeStatusView.alpha = 0.0;
}

%new
- (void)nerdModeHideTimerTick:(NSTimer *)timer {
	CalculatorController *vc = self;
	[UIView animateWithDuration:0.5 animations:^{ [vc nerdModeHideAnimation]; }];
}

- (void)viewWillTransitionToSize:(CGSize)size
	withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator 
{
	CalculatorController *vc = self;
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		[vc.nerdModeHideTimer invalidate];
		[vc.nerdModeStatusView setNeedsDisplay];
		if ([vc updateNerdModeIfNeeded]) {
			vc.nerdModeStatusView.label.attributedText = [vc makeNerdModeString];
			vc.nerdModeStatusView.alpha = 1.0;
		}
	} completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		[vc.nerdModeHideTimer invalidate];
		vc.nerdModeHideTimer = [NSTimer
			scheduledTimerWithTimeInterval:1.0
			target:self
			selector:@selector(nerdModeHideTimerTick:)
			userInfo:nil
			repeats:NO
		];
	}];

	%orig;
}

- (void)viewDidLoad {
	CalculatorController *vc = self;
	%orig;
	vc.nerdModeLayer = [UIView new];
	vc.nerdModeLayer.translatesAutoresizingMaskIntoConstraints = NO;
	[vc.view addSubview:vc.nerdModeLayer];
#define equal(anchorname) [vc.nerdModeLayer. anchorname constraintEqualToAnchor:vc.view. anchorname].active = YES
	equal(topAnchor);
	equal(bottomAnchor);
	equal(leftAnchor);
	equal(rightAnchor);
#undef equal
	vc.nerdModeLayer.backgroundColor = [UIColor clearColor];
	vc.nerdModeLayer.layer.zPosition = CGFLOAT_MAX;
	vc.nerdModeLayer.userInteractionEnabled = NO;
	vc.nerdModeStatusView = [NMNerdModeStatusView new];
	vc.nerdModeStatusView.alpha = 0.0;
	[vc.nerdModeLayer addSubview:vc.nerdModeStatusView];
}

- (void)viewDidAppear:(BOOL)animated {
	CalculatorController *vc = self;
	%orig;
	[vc updateNerdModeIfNeeded];
}

%end

%ctor {
	%init(CalculatorController=objc_getClass("Calculator.CalculatorController"));
}