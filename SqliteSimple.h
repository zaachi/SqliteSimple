//
//  SqliteSimple.h
//  SQLITESIMPLE
//
//  Created by jiri Zachar on 11/22/12.
//  Copyright (c) 2012 Jiri Zachar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sqlite3.h"
#include <string.h>
#include <unistd.h>

//import all other classes
#import "SqliteSimplePath.h"

@interface SqliteSimple : NSObject{
    sqlite3             * _database;
    NSString            * _databasePath;
    BOOL                  _errorLogs;
    BOOL                  _wrongDb;
    int                   _maxAttempt;
    sqlite3_stmt        * _statement;
    BOOL                  _columnsMap;
    NSMutableDictionary * _columns;
}

//initialization with database file path
- (id)              initWithPath : (NSString*)stringPath;
//initialization with database path and create writable copy
- (id)              initWithWritablePath : (NSString*)stringPath;


//open database
- (BOOL)            open;
//close database
- (BOOL)            close;
//get actual database path
- (NSString *)      databasePath;
//get actual database handle
- (sqlite3 *)       databaseHandle;

//sql queries
//select
-(BOOL)             selectq : (NSString *)query, ...;
//update
-(BOOL)             updateq : (NSString *)query, ...;
//delete
-(BOOL)             deleteq : (NSString *)query, ...;
//insert
-(BOOL)             insertq : (NSString *)query, ...;

//next row from result from select
- (BOOL)next;
//return count of query
- (int)count;
//return count of columns in result
- (int)columnsCount;

//return integer from columnt id
- (int)             intByIndex :(int)i;
//return integer from column name
- (int)             intByColumnName :(NSString *)name;

//return nsdata from columnt id
- (NSData *)        blobByIndex :(int)i;
//return nsdata by column name
- (NSData *)        blobByColumnName :(NSString *)name;

//return double from columnt id
- (double)          doubleByIndex :(int)i;
//return double value by column name
- (double)          doubleByColumnName :(NSString *)name;

//return long int from columnt id
- (long long int)   int64ByIndex :(int)i;
//return long int by column name
- (long long int)   int64ByColumnName :(NSString *)name;

//return nsstring from columnt id
- (NSString *)      textByIndex :(int)i;
//return nsstring by column name
- (NSString *)      textByColumnName :(NSString *)name;

//return bool from column id
- (BOOL)            boolByIndex :(int)i;
//return bool value by column name
- (BOOL)            boolByColumnName :(NSString *)name;


//get column name at index
- (NSString *)      columnNameByIndex:(int)i;
//get column index at name
- (int)             columnIndexByName:(NSString *)name;


//get table name (automatic return from first index)
//- (NSString *)getTableName;
//get table name for column at index
//- (NSString *)getTableNameForColumnAtIndex: (int)i;


//debug - get last errro message
- (NSString*)       lastError;
//get last error code
- (int)             lastErrorCode;
//get version of actual sqlite lib
- (NSString *)      sqliteVersion;


@end
