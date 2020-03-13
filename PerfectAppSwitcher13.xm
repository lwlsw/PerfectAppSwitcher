#import "PerfectAppSwitcher13.h"

// ------------------------------ CUSTOM GRID SWITCHER - iPAD STYLE ------------------------------

%group gridSwitcherGroup

	%hook SBAppSwitcherSettings

	- (void)setGridSwitcherPageScale: (double)arg
	{
		%orig(0.38);
	}

	- (void)setGridSwitcherHorizontalInterpageSpacingPortrait: (double)arg
	{
		%orig(30);
	}

	- (void)setGridSwitcherVerticalNaturalSpacingPortrait: (double)arg
	{
		%orig(65);
	}

	- (void)setGridSwitcherHorizontalInterpageSpacingLandscape: (double)arg
	{
		%orig(10);
	}

	- (void)setGridSwitcherVerticalNaturalSpacingLandscape: (double)arg
	{
		%orig(40);
	}

	- (void)setSwitcherStyle: (long long)arg
	{
		%orig(2);
	}

	%end

%end

// ------------------------------ Disable Killing Of Playing App ------------------------------

%group disablePlayingMediaKillingGroup

	%hook SBFluidSwitcherItemContainer

	- (void)layoutSubviews
	{
		%orig;

		SBMediaController *media = [%c(SBMediaController) sharedInstance];

		if(media && media.isPlaying)
		{
			SBFluidSwitcherItemContainerHeaderItem *allAppCards = [self headerItems];

			NSString *nowPlayingApp = [[media nowPlayingApplication] displayName];

			for(SBFluidSwitcherItemContainerHeaderItem *appCard in allAppCards)
			{
				if([[appCard titleText] isEqualToString: nowPlayingApp]) [self setKillable: NO];
			}
		}
	}

	%end

%end

// ------------------------------ KILL ALL RUNNING APPS ------------------------------

%group enableKillAllGroup

	%hook SBFluidSwitcherItemContainer

	-(void)scrollViewWillEndDragging:(id)arg1 withVelocity:(CGPoint)arg2 targetContentOffset:(CGPoint*)arg3
	{
		if(arg2.y < -5.0)
		{
			SBMainSwitcherViewController *mainSwitcher = [%c(SBMainSwitcherViewController) sharedInstance];
			NSArray *items = mainSwitcher.recentAppLayouts;

			NSString *nowPlayingID = [[[%c(SBMediaController) sharedInstance] nowPlayingApplication] bundleIdentifier];

			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), 
			^{
				for(SBAppLayout *item in items)
				{
					NSString *bundleID = [[item.rolesToLayoutItemsMap objectForKey: @1] bundleIdentifier];
					if(!disablePlayingMediaKilling || disablePlayingMediaKilling && ![bundleID isEqualToString: nowPlayingID]) 
						[mainSwitcher _deleteAppLayout: item forReason: 1];
				}
			});
		}
		%orig;
	}

	%end

%end

%ctor
{
	@autoreleasepool
	{
		pref = [[HBPreferences alloc] initWithIdentifier: @"com.johnzaro.perfectappswitcher13prefs"];

		[pref registerBool: &gridSwitcher default: NO forKey: @"gridSwitcher"];
		[pref registerBool: &disablePlayingMediaKilling default: NO forKey: @"disablePlayingMediaKilling"];
		[pref registerBool: &enableKillAll default: NO forKey: @"enableKillAll"];

		if(gridSwitcher) %init(gridSwitcherGroup);
		if(disablePlayingMediaKilling) %init(disablePlayingMediaKillingGroup);
		if(enableKillAll) %init(enableKillAllGroup);
	}
}