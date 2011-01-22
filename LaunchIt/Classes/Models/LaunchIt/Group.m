#import "Group.h"
#import "Application.h"
#import "CoreData+ActiveRecordFetching.h"
#import "SGHotKey.h"
#import "SGHotKeyCenter.h"
#import "RSApplicationFileAnalyzer.h"
#import <ShortcutRecorder/ShortcutRecorder.h>
#import "CoreData+ActiveRecordFetching.h"
#import "AppDelegate.h"
#import "LIWindowController.h"


@interface Group (private)
- (void)launch:(SGHotKey *)aHotKey;
@end


@implementation Group

+ (NSArray *)allSortedByName
{
  return [self findAllSortedBy:@"name" ascending:YES];
}


+ (void)bindAllHotkeys
{
  for (Group *group in [Group findAll]) {
    [group unbindHotkey];
    [group bindHotkey];
  }
}


// ------------------------------------------------------------------------------
// migrateExistingApplications
// ------------------------------------------------------------------------------
+ (void)migrateExistingApplications
{
  __block BOOL any = NO;

  [[Application findAllWithPredicate:[NSPredicate predicateWithFormat:@"group = nil"]] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL * stop) {
     Application *app = obj;
     Group *group = [Group createEntity];
     [group addApplicationsObject:app];
     group.shortcutCodeValue = app.shortcutCodeValue;
     group.shortcutFlagsValue = app.shortcutFlagsValue;
     group.name = app.name;
     any = YES;
   }
  ];

  if (any)
    [[NSManagedObjectContext defaultContext] save];
}


// ------------------------------------------------------------------------------
// smallImage
// ------------------------------------------------------------------------------
- (NSImage *)smallImage
{
  return [NSImage imageNamed:@"NSApplicationIcon"];
}


// ------------------------------------------------------------------------------
// largeImage
// ------------------------------------------------------------------------------
- (NSImage *)largeImage
{
  return [NSImage imageNamed:@"NSApplicationIcon"];
}


// sent via the collection view? :/ better way?
- (IBAction)edit:(id)sender
{
  [[AppDelegate sharedAppDelegate].windowController editGroup:self];
}


- (NSString *)shortcutCodeStringForMenus
{
  SRRecorderControl *shortcutRecorder = [[SRRecorderControl alloc] init];
  SGKeyCombo        *combo            = [SGKeyCombo keyComboWithKeyCode:[self shortcutCodeValue] modifiers:[shortcutRecorder cocoaToCarbonFlags:[self shortcutFlagsValue]]];

  [shortcutRecorder release];

  NSString *code = [combo keyCodeString];

  unichar ch[4];

  if ([code isEqualToString:@"F1"]) {
    ch[0] = NSF1FunctionKey;
  } else if ([code isEqualToString:@"F2"]) {
    ch[0] = NSF2FunctionKey;
  } else if ([code isEqualToString:@"F3"]) {
    ch[0] = NSF3FunctionKey;
  } else if ([code isEqualToString:@"F4"]) {
    ch[0] = NSF4FunctionKey;
  } else if ([code isEqualToString:@"F5"]) {
    ch[0] = NSF5FunctionKey;
  } else if ([code isEqualToString:@"F6"]) {
    ch[0] = NSF6FunctionKey;
  } else if ([code isEqualToString:@"F7"]) {
    ch[0] = NSF7FunctionKey;
  } else if ([code isEqualToString:@"F8"]) {
    ch[0] = NSF8FunctionKey;
  } else if ([code isEqualToString:@"F9"]) {
    ch[0] = NSF9FunctionKey;
  } else if ([code isEqualToString:@"F10"]) {
    ch[0] = NSF10FunctionKey;
  } else if ([code isEqualToString:@"F11"]) {
    ch[0] = NSF11FunctionKey;
  } else if ([code isEqualToString:@"F12"]) {
    ch[0] = NSF12FunctionKey;
  } else if ([code isEqualToString:@"F13"]) {
    ch[0] = NSF13FunctionKey;
  } else if ([code isEqualToString:@"F14"]) {
    ch[0] = NSF14FunctionKey;
  } else if ([code isEqualToString:@"F15"]) {
    ch[0] = NSF15FunctionKey;
  } else if ([code isEqualToString:@"F16"]) {
    ch[0] = NSF16FunctionKey;
  } else if ([code isEqualToString:@"F17"]) {
    ch[0] = NSF17FunctionKey;
  } else if ([code isEqualToString:@"F18"]) {
    ch[0] = NSF18FunctionKey;
  } else if ([code isEqualToString:@"F19"]) {
    ch[0] = NSF19FunctionKey;
  } else {
    return code;
  }

  NSString *ret = [NSString stringWithCharacters:ch length:1];
  NSLog(@"%@", ret);
  return ret;
}


- (NSString *)shortcutCodeString
{
  return SRStringForCocoaModifierFlagsAndKeyCode([self shortcutFlagsValue], [self shortcutCodeValue]);
}


- (NSUInteger)modifierMask
{
  SRRecorderControl *shortcutRecorder = [[SRRecorderControl alloc] init];
  SGKeyCombo        *combo            = [SGKeyCombo keyComboWithKeyCode:[self shortcutCodeValue] modifiers:[shortcutRecorder cocoaToCarbonFlags:[self shortcutFlagsValue]]];

  [shortcutRecorder release];
  return [combo modifierMask];
}


- (SGHotKey *)hotkey
{
  if (_hotkey) {
    return _hotkey;
  }

  SRRecorderControl *shortcutRecorder = [[SRRecorderControl alloc] init];
  _hotkey = [[SGHotKey alloc] initWithIdentifier:self.objectID keyCombo:[SGKeyCombo keyComboWithKeyCode:[self shortcutCodeValue] modifiers:[shortcutRecorder cocoaToCarbonFlags:[self shortcutFlagsValue]]]];

  [shortcutRecorder release];

  [_hotkey setTarget:self];
  [_hotkey setAction:@selector(launch:)];

  return _hotkey;
}


- (void)bindHotkey
{
  [[SGHotKeyCenter sharedCenter] registerHotKey:[self hotkey]];
}


- (void)bindHotkeyTo:(id)delegate action:(SEL)selector
{
  SGHotKey *hotkey = [self hotkey];

  [hotkey setTarget:delegate];
  [hotkey setAction:selector];
  [[SGHotKeyCenter sharedCenter] registerHotKey:hotkey];
}


- (void)unbindHotkey
{
  [[SGHotKeyCenter sharedCenter] unregisterHotKey:[self hotkey]];
  _hotkey = nil;
}


// -------------------------------------------------
- (void)launch
{
  [self launch:nil];
}


- (void)launch:(SGHotKey *)aHotKey
{
  [[self applications] enumerateObjectsUsingBlock:^(id obj, BOOL * stop) {
     Application *app = obj;
     [app launch];
   }
  ];
}
@end