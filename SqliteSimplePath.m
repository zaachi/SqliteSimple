//
//  SqliteSimplePath.m
//  SQLITESIMPLE
//
//  Created by jiri Zachar on 11/22/12.
//  Copyright (c) 2012 Jiri Zachar. All rights reserved.
//

#import "SqliteSimplePath.h"

@implementation SqliteSimpleDatabasePath

+ (void)createEditableCopyOfDatabaseIfNeeded : (NSString *)databasePath{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSError *error;
    
	NSString *writableDBPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]
								stringByAppendingPathComponent:databasePath];
    
    
	BOOL success = [fileManager fileExistsAtPath:writableDBPath];
	if (success){
		return;
	}
    
	//if i can't edit this file, i must copy it into app folder
	NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:databasePath];
    
	if (! [fileManager copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error] ) {
		NSLog(@"%@", error);
	}
}

@end
