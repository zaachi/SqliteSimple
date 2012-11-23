//
//  SqliteSimple.m
//  SQLITESIMPLE
//
//  Created by jiri Zachar on 11/22/12.
//  Copyright (c) 2012 Jiri Zachar. All rights reserved.
//

#import "SqliteSimple.h"
#import <objc/runtime.h>

@interface SqliteSimple ()

@end

@implementation SqliteSimple

- (NSString *)databasePath{
    return [NSString stringWithFormat:@"%@", _databasePath];
}
- (sqlite3 *)databaseHandle{
    return _database;
}


- (id)initWithPath :(NSString*)stringPath {
    self = [super init];

    if (self) {
        _databasePath   = [stringPath copy];
        _database       = 0x00;
        _errorLogs      = TRUE;
        _maxAttempt     = 10;
        _wrongDb        = TRUE; 
    }

    return self;
}

- (void)finalize {
    [self close];
    [super finalize];
}

- (void)dealloc {
    [self close];
    [_databasePath release];
    [_columns release];
    [super dealloc];
}


- (id)initWithWritablePath : (NSString*)stringPath {
    [SqliteSimpleDatabasePath createEditableCopyOfDatabaseIfNeeded:stringPath];
    
    stringPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]stringByAppendingPathComponent:stringPath];

    return [self initWithPath:stringPath];
}


-(BOOL)open{
    if ( _database ) {
        TRUE;
    }

    NSString *path;
    if ([_databasePath fileSystemRepresentation] ) {
        path = _databasePath;
    }else{
        //If the filename is ":memory:", then a private, temporary in-memory database is created for the connection.
        path = @":memory:";
    }

    int error = sqlite3_open([path UTF8String], &_database );
    if ( error != SQLITE_OK ) {
        if (_errorLogs) {
            NSLog(@"code: %d, message: %@", [self lastErrorCode], [self lastError]);
        }
        return FALSE;
    }

    _wrongDb = FALSE;
    return TRUE;
}

-(BOOL)close{
    if (!_database) {
        return TRUE;
    }

    BOOL tryAgain = YES;
    int attempts = 0;
    int result;

    do {
        result = sqlite3_close( _database );

        if( result == SQLITE_BUSY ) {
            usleep(100);

            if( attempts++ > _maxAttempt ){
                return FALSE;
            }
        }
        else{
            if (result != SQLITE_OK ) {
                if (_errorLogs) {
                    NSLog(@"code: %d, message: %@", [self lastErrorCode], [self lastError]);
                }
            }
            tryAgain = FALSE;
        }
    }
    while(tryAgain);
    
    _database = Nil;
    return TRUE;
}

- (NSString *)lastError {
    return
        [NSString stringWithUTF8String:sqlite3_errmsg( _database ) ];
}

- (int)lastErrorCode {
    return
        sqlite3_errcode( _database );
}

- (NSString *)sqliteVersion{
    return
        [NSString stringWithFormat:@"Vesion: %s", sqlite3_libversion() ];
}

-(BOOL)updateq : (NSString *)query, ...{
    if (![self existsDatabase]) {
        abort();
    }
    
    va_list(args);
    va_start(args, query);
    
    BOOL ret = [self executeQuery: query: args];
    if (ret == TRUE) {
        ret = [self afterUpdate];
    }
    
    va_end(args);
    return ret;
}

-(BOOL)deleteq : (NSString *)query, ...{
    if (![self existsDatabase]) {
        abort();
    }
    
    va_list(args);
    va_start(args, query);
    
    BOOL ret = [self executeQuery: query: args];
    if (ret == TRUE) {
        ret = [self afterUpdate];
    }
    
    va_end(args);
    return ret;
}

-(BOOL)insertq : (NSString *)query, ...{
    if (![self existsDatabase]) {
        abort();
    }
    
    va_list(args);
    va_start(args, query);
    
    BOOL ret = [self executeQuery: query: args];
    if (ret == TRUE) {
        ret = [self afterUpdate];
    }
    
    va_end(args);
    return ret;
}


-(BOOL)afterUpdate{
    
    int result;
    int attempts = 0;
    BOOL tryAgain = TRUE;

    do {
        result = sqlite3_step(_statement);

        if (result == SQLITE_DONE) {
            return TRUE;
        }

        if( result == SQLITE_BUSY || result == SQLITE_LOCKED) {
            usleep(100);

            if(_errorLogs ){
                NSLog(@"Database bussy");
            }

            if( attempts++ > _maxAttempt ){
                if (_errorLogs) {
                    NSLog(@"can't make this query. Database is bussy");
                }
                sqlite3_finalize(_statement);
                return FALSE;
            }else{
                tryAgain = TRUE;
            }
        }else{
            tryAgain = FALSE;
        }
    }
    while(tryAgain);

    return TRUE;
}

-(BOOL)selectq : (NSString *)query, ...{
    if (![self existsDatabase]) {
        abort();
    }

    va_list(args);
    va_start(args, query);

    BOOL ret = [self executeQuery: query: args];

    va_end(args);

    return ret;
}

- (BOOL)executeQuery :(NSString *)query : (va_list)vargs{
    if( ![self existsDatabase] ){
        abort();
    }

    sqlite3_stmt *statement = 0x00;
    
    int result;
    int attempts = 0;
    BOOL tryAgain = TRUE;

    do {
        result = sqlite3_prepare_v2( _database, [query UTF8String], -1, &statement, nil );
        if( result == SQLITE_BUSY || result == SQLITE_LOCKED) {
            usleep(100);

            if(_errorLogs ){
                NSLog(@"Database bussy");
            }
            
            if( attempts++ > _maxAttempt ){
                if (_errorLogs) {
                    NSLog(@"can't make this query. Database is bussy");
                }
                sqlite3_finalize(_statement);
                return FALSE;
            }else{
                tryAgain = TRUE;
            }
        }else{
            tryAgain = FALSE;
        }
    }
    while(tryAgain);

    if (!statement) {
        return NO;
    }

    int bindParamsCount = sqlite3_bind_parameter_count(statement);

    id argObject;
    int argsCount = 0;

    for ( int i = 1; i <= bindParamsCount; i++ ) {
        argObject = va_arg(vargs, id);
        [self bindParam:argObject :i :statement];
        argsCount++;
    }

    if (argsCount != bindParamsCount && _errorLogs) {
        NSLog(@"Mismatch in parameter count");
    }

    _statement = statement;
    _columnsMap = FALSE;
    return YES;
}

- (int)count{
    int count = 0;
    while([self next]) {
        count++;
    }

    sqlite3_reset(_statement);
    return count;
}

- (int)columnsCount{
    if (!_columnsMap) {
        [self createMapOfColumns];
    }
    return [_columns count];
}

- (BOOL)next{
    int result;
    BOOL tryAgain = TRUE;
    int attempts = 0;

    do{
        result = sqlite3_step(_statement);

        if( result == SQLITE_DONE ){
            return FALSE;
        }
        else if( result == SQLITE_BUSY || result == SQLITE_LOCKED) {
            usleep(100);
            
            if(_errorLogs ){
                NSLog(@"Database bussy");
            }

            if( attempts++ > _maxAttempt ){
                if (_errorLogs) {
                    NSLog(@"can't make this query. Database is bussy");
                }
                return NO;
            }
        }
        else if( result == SQLITE_ROW ){
            tryAgain = FALSE;
        }else{
            if (_errorLogs ) {
                NSLog(@"Unknow error");
            }
        }
    }
    while (tryAgain);

    return SQLITE_ROW == result;
}

- (int)intByIndex :(int)i{
    if (!_statement) {
        if( _errorLogs ){
            NSLog(@"Statement not exists");
        }
        return 0;
    }
    
    return sqlite3_column_int(_statement, i);
}

- (NSData *)blobByIndex :(int)i{
    if (!_statement) {
        if( _errorLogs ){
            NSLog(@"Statement not exists");
        }
        return 0;
    }
    
    NSUInteger blobLength = sqlite3_column_bytes(_statement, i);
    NSData *resData = [NSData dataWithBytes:sqlite3_column_blob(_statement, i) length:blobLength];
    return resData;
}

- (double)doubleByIndex :(int)i{
    if (!_statement) {
        if( _errorLogs ){
            NSLog(@"Statement not exists");
        }
        return 0;
    }
    
    return sqlite3_column_double(_statement, i);
}

- (long long int)int64ByIndex :(int)i{
    if (!_statement) {
        if( _errorLogs ){
            NSLog(@"Statement not exists");
        }
        return 0;
    }
    
    return sqlite3_column_int64(_statement, i);
}

- (NSString *)textByIndex :(int)i{
    if (!_statement) {
        if( _errorLogs ){
            NSLog(@"Statement not exists");
        }
        return 0;
    }
    const char *str = (char *)sqlite3_column_text(_statement, i);
    if (!str) {
        return nil;
    }
    return
        [NSString stringWithUTF8String: str];
}

- (BOOL)boolByIndex :(int)i{
    if (!_statement) {
        if( _errorLogs ){
            NSLog(@"Statement not exists");
        }
        return 0;
    }
    
    return (sqlite3_column_int(_statement, i) != 0);
}

- (NSString *)columnNameByIndex:(int)i {
    return
        [NSString stringWithUTF8String: sqlite3_column_name(_statement, i)];
}

- (int)columnIndexByName:(NSString *)name{
    NSString *index = [_columns objectForKey: [name lowercaseString] ];
    return [index intValue];
}

- (int)intByColumnName :(NSString *)name{
    if (!_columnsMap) {
        [self createMapOfColumns];
    }

    NSString *key = [_columns objectForKey: [name lowercaseString] ];
    return [self intByIndex:[key intValue] ];
}

- (NSString *)textByColumnName :(NSString *)name{
    if (!_columnsMap) {
        [self createMapOfColumns];
    }
    
    NSString *key = [_columns objectForKey: [name lowercaseString] ];
    return [self textByIndex:[key intValue] ];
}

- (NSData *)blobByColumnName :(NSString *)name{
    if (!_columnsMap) {
        [self createMapOfColumns];
    }
    
    NSString *key = [_columns objectForKey: [name lowercaseString] ];
    return [self blobByIndex:[key intValue] ];
}

- (double)doubleByColumnName :(NSString *)name{
    if (!_columnsMap) {
        [self createMapOfColumns];
    }
    
    NSString *key = [_columns objectForKey: [name lowercaseString] ];
    return [self doubleByIndex:[key intValue] ];
}

- (long long int)int64ByColumnName :(NSString *)name{
    if (!_columnsMap) {
        [self createMapOfColumns];
    }
    
    NSString *key = [_columns objectForKey: [name lowercaseString] ];
    return [self int64ByIndex:[key intValue] ];
}


- (BOOL)boolByColumnName :(NSString *)name{
    if (!_columnsMap) {
        [self createMapOfColumns];
    }
    
    NSString *key = [_columns objectForKey: [name lowercaseString] ];
    return [self boolByIndex:[key intValue] ];
}

- (BOOL)createMapOfColumns{
    if (!_statement) {
        return FALSE;
    }

    _columns = nil;
    _columns = [[NSMutableDictionary alloc] init];

    for ( int i = 0; i < sqlite3_column_count(_statement); i++ ){
        NSString *columnName = [[self columnNameByIndex:i] lowercaseString];
        [_columns setObject:[NSNumber numberWithInt:i] forKey:columnName];
    }

    _columnsMap = TRUE;
    return _columnsMap;
}

/*
- (NSString *)getTableName{
    return [NSString stringWithUTF8String:(char *) sqlite3_column_table_name(_statement, 0) ];
}

- (NSString *)getTableNameForColumnAtIndex: (int)i{
   return [NSString stringWithUTF8String:(char *) sqlite3_column_table_name(_statement, i)];
}
*/


//private:
- (BOOL)existsDatabase{
    if( !_database || _wrongDb == TRUE ){
        if (_errorLogs) {
            NSLog(@"database is not open");
        }
        return FALSE;
    }
    return TRUE;
}

-(void)bindParam : (id)argObject : (int) i : (sqlite3_stmt *)statement{
    //bind value by http://www.sqlite.org/c3ref/bind_blob.html
    int result = 0;
    
    if (!argObject) {
        sqlite3_bind_null(statement, i);
    }
    else{
        int binded = 0;
        if( [argObject isKindOfClass:[NSNumber class]] ){
            //list of all types of nsnumber
            if( strcmp( [argObject objCType], @encode(BOOL) ) == 0 ) {
                result = sqlite3_bind_int(statement, i, [argObject intValue]);
                binded = 1;
            }
            else if (strcmp([argObject objCType], @encode(float)) == 0 ) {
                result = sqlite3_bind_double(statement, i, [argObject floatValue]);
                binded = 1;
            }
            else if (strcmp([argObject objCType], @encode(double)) == 0 ) {
                result = sqlite3_bind_double(statement, i, [argObject doubleValue]);
                binded = 1;
            }
            else if (strcmp([argObject objCType], @encode(int)) == 0) {
                result = sqlite3_bind_int64(statement, i, [argObject longValue]);
                binded = 1;
            }
            else if (strcmp([argObject objCType], @encode(long)) == 0) {
                result = sqlite3_bind_int64(statement, i, [argObject longValue]);
                binded = 1;
            }
        }
        else if( [argObject isKindOfClass:[NSData class]] ){
            sqlite3_bind_blob(statement, i, [argObject bytes], (int)[argObject length], SQLITE_STATIC);
            binded = 1;
        }else if ( [argObject isKindOfClass:[NSDate class]] ){
            sqlite3_bind_double(statement, i, [argObject timeIntervalSince1970]);
            binded = 1;
        }
        
        if( binded == 0 ){
            result = sqlite3_bind_text(statement, i, [argObject UTF8String], -1, SQLITE_STATIC);
        }
    }
    if(result == SQLITE_RANGE && _errorLogs){
        NSLog(@"%@", [self lastError]);
    }
}


@end
