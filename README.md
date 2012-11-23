SqliteSimple
============

SqliteSimple is very simple wrapper in __Objective-C__ over __Sqlite3 database__ (http://www.sqlite.org/) for __Cocoa framework__.

Initialization
--------------

*  Initializes the database by location in filesystem

    ``SqliteSimple *db = [[SqliteSimple alloc] initWithPath:@"database.db"];``

* initializes the database by location and make writable copy

    ``SqliteSimple *db = [[SqliteSimple alloc] initWithWritablePath:@"database.db"];``

* initializes the database from memory

    ``SqliteSimple *db = [[SqliteSimple alloc] initWithWritablePath:@""];``

Open and close database
------------------------

If the active connection it is possible to connect

	SqliteSimple *db = [[SqliteSimple alloc] initWithPath:@"database.db"];
	if([db open]){
	    [db close];
	}


Example 1: count
----------------

	SqliteSimple *db = [[SqliteSimple alloc] initWithPath:@"database.db"];
	if([db open]){
	    if ([db selectq:@"SELECT COUNT(*) FROM adverts"]) {
	        if ([db next]) {
	            NSLog(@"count: %d", [db intByIndex:0]);
	        }
	    }
	    [db close];
	}
	
	
Example 2: count with bind param
--------------------------------
		SqliteSimple *db = [[SqliteSimple alloc] initWithPath:@"database.db"];
	    if ([db selectq:@"SELECT COUNT(*) FROM adverts WHERE id > ?", [NSNumber numberWithInt:5 ] ] ) {
	       if ([db next]) {
	           NSLog(@"count: %d", [db intByIndex:0]);
	       }
	    }
	    [db close];
	}


Example 3: query with result - get columns and values
-------------------------------------------------------
	SqliteSimple *db = [[SqliteSimple alloc] initWithPath:@"database.db"];
	    if( [db selectq:@"SELECT * FROM adverts"]){
	        while ([db next] ) {
	            //[db columnsCount] returns count of columns in result
	            for (int i = 0; i < [db columnsCount]; i++) {
	                NSLog(@"Column name: %@ \t Column value: %@",
	                    [db columnNameByIndex:i], [db textByIndex:i]);
	            }
	        }
	    }
	    [db close];
	}
	
    
Example 4: access to columns with column names
----------------------------------------------
	SqliteSimple *db = [[SqliteSimple alloc] initWithPath:@"database.db"];
	    if( [db selectq:@"SELECT * FROM adverts WHERE id = ?", [NSNumber numberWithInt:5] ]){
	        while ([db next] ) {
	            NSString *name = [db textByColumnName:@"name"];
	            NSString *surname = [db textByColumnName:@"surname"];
	        }
	    }
    	[db close];
	}
    

    
Example 5: update statement
-----------------------------
	SqliteSimple *db = [[SqliteSimple alloc] initWithPath:@"database.db"];
	    if ([db updateq:@"UPDATE adverts SET name = ? WHERE id = ?", @"Mrn", [NSNumber numberWithInt:5] ] ) {
	        NSLog(@"update completed");
	    }
	    [db close];
	}

     
    
Example 6: delete statement
----------------------------
	SqliteSimple *db = [[SqliteSimple alloc] initWithPath:@"database.db"];
	    if ([db deleteq:@"DELETE FROM adverts WHERE id = ? LIMIT ?", [NSNumber numberWithInt:5 ], [NSNumber numberWithInt:1] ] ) {
	        NSLog(@"delete completed");
	    }
	    [db close];
	}


Example 7: insert statement
---------------------------
	SqliteSimple *db = [[SqliteSimple alloc] initWithPath:@"database.db"];
	    NSArray *keys = [dict allKeys];
	    int i = 0;
	    for (NSString *key in keys) {
	
	        if ([db insertq:@"INSERT INTO adverts (id, name, surname) VALUES(?, ?)",
	                [NSNumber numberWithInt:i++], [dict objectForKey:@"name"], [dict objectForKey:@"surname"]
	             ] ) {
	
	            NSLog(@"insert completed");
	        }
	    }
	    [db close];
	}

    

Methods to execute the query
----------------------------
* select

``-(BOOL)             selectq : (NSString *)query, ...;``

* update

``-(BOOL)             updateq : (NSString *)query, ...;``

* delete

``-(BOOL)             deleteq : (NSString *)query, ...;``

* insert

``-(BOOL)             insertq : (NSString *)query, ...;``
     
    

Methods for returning data
--------------------------
	- (int)             intByIndex :(int)i;
	- (int)             intByColumnName :(NSString *)name;
	- (NSData *)        blobByIndex :(int)i;
	- (NSData *)        blobByColumnName :(NSString *)name;
	- (double)          doubleByIndex :(int)i;
	- (double)          doubleByColumnName :(NSString *)name;
	- (long long int)   int64ByIndex :(int)i;
	- (long long int)   int64ByColumnName :(NSString *)name;
	- (NSString *)      textByIndex :(int)i;
	- (NSString *)      textByColumnName :(NSString *)name;
	- (BOOL)            boolByIndex :(int)i;
	- (BOOL)            boolByColumnName :(NSString *)name;


	