//
//  NSManagedObjectContext+ActiveRecord.m
//
//  Created by Saul Mora on 11/23/09.
//  Copyright 2010 Magical Panda Software, LLC All rights reserved.
//

#import "NSManagedObject+ActiveRecord.h"
#import "NSManagedObjectContext+ActiveRecord.h"
#import "NSPersistentStoreCoordinator+ActiveRecord.h"
#import <objc/runtime.h>

static NSManagedObjectContext *defaultManageObjectContext = nil;

@implementation NSManagedObjectContext (ActiveRecord)

+ (NSManagedObjectContext *)defaultContext
{
//    NSAssert([NSThread isMainThread], @"The defaultContext must only be accessed on the **Main Thread**");
	@synchronized (self)
	{
		if (defaultManageObjectContext)
		{
			return defaultManageObjectContext;
		}
	}
	return nil;
}

+ (void) setDefaultContext:(NSManagedObjectContext *)moc
{
	[defaultManageObjectContext release];
	defaultManageObjectContext = [moc retain];
}

+ (void) resetDefaultContext
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        [[NSManagedObjectContext defaultContext] reset];
    });
}

+ (NSManagedObjectContext *) contextForCurrentThread
{
	if ( [NSThread isMainThread] )
	{
		return [self defaultContext];
	}
	else
	{
		NSMutableDictionary *threadDict = [[NSThread currentThread] threadDictionary];
		NSManagedObjectContext *threadContext = [threadDict objectForKey:@"MO_Context"];
		if ( threadContext == nil )
		{
			threadContext = [self context];
			[threadDict setObject:threadContext forKey:@"MO_Context"];
			//[threadContext release];
		}
		return threadContext;
	}
}

- (void) observeContext:(NSManagedObjectContext *)otherContext
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(mergeChangesFromNotification:)
												 name:NSManagedObjectContextDidSaveNotification
											   object:otherContext];
}

- (void) observeContextOnMainThread:(NSManagedObjectContext *)otherContext
{
    //	NSLog(@"Start Observing on Main Thread");
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(mergeChangesOnMainThread:)
												 name:NSManagedObjectContextDidSaveNotification
											   object:otherContext];
}

- (void) stopObservingContext:(NSManagedObjectContext *)otherContext
{
    //	NSLog(@"Stop Observing Context");
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSManagedObjectContextDidSaveNotification
												  object:otherContext];
}

- (void) mergeChangesFromNotification:(NSNotification *)notification
{
	NSLog(@"Merging changes to context%@", [NSThread isMainThread] ? @" *** on Main Thread ***" : @"");
	[self mergeChangesFromContextDidSaveNotification:notification];
}

- (void) mergeChangesOnMainThread:(NSNotification *)notification
{
	if ([NSThread isMainThread])
	{
	  [self mergeChangesFromNotification:notification];
	}
	else
	{
	  [self performSelectorOnMainThread:@selector(mergeChangesFromNotification:) withObject:notification waitUntilDone:YES];
	}
}

- (BOOL) save
{
	NSError *error = nil;
	BOOL saved = NO;
	@try
	{
		NSLog(@"Saving %@Context%@", 
              self == [[self class] defaultContext] ? @" *** Default *** ": @"", 
              ([NSThread isMainThread] ? @" *** on Main Thread ***" : @""));
		saved = [self save:&error];
	}
	@catch (NSException *exception)
	{
		NSLog(@"Problem saving: %@", (id)[exception userInfo] ?: (id)[exception reason]);
	}

	[ActiveRecordHelpers handleErrors:error];

	return saved && error == nil;
}

- (void) saveWrapper
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self save];
	[pool drain];
}

- (BOOL) saveOnBackgroundThread
{
	[self performSelectorInBackground:@selector(saveWrapper) withObject:nil];

	return YES;
}

- (BOOL) saveOnMainThread
{
	@synchronized(self)
	{
		[self performSelectorOnMainThread:@selector(saveWrapper) withObject:nil waitUntilDone:YES];
	}

	return YES;
}

- (BOOL) notifiesMainContextOnSave
{
    NSNumber *notifies = objc_getAssociatedObject(self, @"notifiesMainContext");
    return notifies ? [notifies boolValue] : NO;
}

- (void) setNotifiesMainContextOnSave:(BOOL)enabled
{
    NSManagedObjectContext *mainContext = [[self class] defaultContext];
    if (self != mainContext) 
    {
        SEL selector = enabled ? @selector(observeContextOnMainThread:) : @selector(stopObservingContext:);
        objc_setAssociatedObject(self, @"notifiesMainContext", [NSNumber numberWithBool:enabled], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [mainContext performSelector:selector withObject:self];
    }
}

+ (NSManagedObjectContext *) contextWithStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator
{
	NSManagedObjectContext *context = nil;
    if (coordinator != nil)
	{
        context = [[NSManagedObjectContext alloc] init];
        [context setPersistentStoreCoordinator:coordinator];
    }
    return [context autorelease];
}

+ (NSManagedObjectContext *) contextThatNotifiesDefaultContextOnMainThreadWithCoordinator:(NSPersistentStoreCoordinator *)coordinator;
{
    NSManagedObjectContext *context = [self contextWithStoreCoordinator:coordinator];
//    [[self defaultContext] observeContext:context];
    context.notifiesMainContextOnSave = YES;
    return context;
}

+ (NSManagedObjectContext *) context
{
	return [self contextWithStoreCoordinator:[NSPersistentStoreCoordinator defaultStoreCoordinator]];
}

+ (NSManagedObjectContext *) contextThatNotifiesDefaultContextOnMainThread
{
    NSManagedObjectContext *context = [self context];
//    [[self defaultContext] observeContextOnMainThread:context];
    context.notifiesMainContextOnSave = YES;
    return context;
}

@end
