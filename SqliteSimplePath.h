//
//  SqliteSimplePath.h
//  SQLITESIMPLE
//
//  Created by jiri Zachar on 11/22/12.
//  Copyright (c) 2012 Jiri Zachar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SqliteSimpleDatabasePath : NSObject

+ (void)createEditableCopyOfDatabaseIfNeeded : (NSString *)databasePath;

@end
