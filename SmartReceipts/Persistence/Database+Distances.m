//
//  Database+Distances.m
//  SmartReceipts
//
//  Created by Jaanus Siim on 01/05/15.
//  Copyright (c) 2015 Will Baumann. All rights reserved.
//

#import "Database+Distances.h"
#import "DatabaseTableNames.h"
#import "Distance.h"
#import "Database+Functions.h"
#import "DatabaseQueryBuilder.h"
#import "WBTrip.h"
#import "WBPrice.h"
#import "WBCurrency.h"
#import "FetchedModelAdapter.h"
#import "Database+Trips.h"
#import "NSDate+Calculations.h"

@implementation Database (Distances)

- (BOOL)createDistanceTable {
    NSArray *createDistanceTable =
            @[@"CREATE TABLE ", DistanceTable.TABLE_NAME, @" (", //
                    DistanceTable.COLUMN_ID, @" INTEGER PRIMARY KEY AUTOINCREMENT,", //
                    DistanceTable.COLUMN_PARENT, @" TEXT REFERENCES ", TripsTable.COLUMN_NAME, @" ON DELETE CASCADE,", //
                    DistanceTable.COLUMN_DISTANCE, @" DECIMAL(10, 2) DEFAULT 0.00,", //
                    DistanceTable.COLUMN_LOCATION, @" TEXT,", //
                    DistanceTable.COLUMN_DATE, @" DATE,", //
                    DistanceTable.COLUMN_TIMEZONE, @" TEXT,", //
                    DistanceTable.COLUMN_COMMENT, @" TEXT,", //
                    DistanceTable.COLUMN_RATE_CURRENCY, @" TEXT NOT NULL, ", //
                    DistanceTable.COLUMN_RATE, @" DECIMAL(10, 2) DEFAULT 0.00 );"];
    return [self executeUpdateWithStatementComponents:createDistanceTable];
}

- (BOOL)saveDistance:(Distance *)distance {
    DatabaseQueryBuilder *insert = [DatabaseQueryBuilder insertStatementForTable:DistanceTable.TABLE_NAME];
    [insert addParam:DistanceTable.COLUMN_PARENT value:distance.trip.name];
    [insert addParam:DistanceTable.COLUMN_DISTANCE value:distance.distance];
    [insert addParam:DistanceTable.COLUMN_LOCATION value:distance.location];
    [insert addParam:DistanceTable.COLUMN_DATE value:distance.date.milliseconds];
    [insert addParam:DistanceTable.COLUMN_TIMEZONE value:distance.timeZone.name];
    [insert addParam:DistanceTable.COLUMN_COMMENT value:distance.comment];
    [insert addParam:DistanceTable.COLUMN_RATE_CURRENCY value:distance.rate.currency.code];
    [insert addParam:DistanceTable.COLUMN_RATE value:distance.rate.amount];
    BOOL result = [self executeQuery:insert];
    if (result) {
        [self updatePriceOfTrip:distance.trip];
        [[NSNotificationCenter defaultCenter] postNotificationName:DatabaseDidInsertModelNotification object:distance];
    }
    return result;
}

- (FetchedModelAdapter *)fetchedAdapterForDistancesInTrip:(WBTrip *)trip {
    FetchedModelAdapter *adapter = [[FetchedModelAdapter alloc] initWithDatabase:self];
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = :parent ORDER BY %@ DESC", DistanceTable.TABLE_NAME, DistanceTable.COLUMN_PARENT, DistanceTable.COLUMN_DATE];
    [adapter setQuery:query parameters:@{@"parent" : trip.name}];
    [adapter setModelClass:[Distance class]];
    [adapter fetch];
    return adapter;
}

- (BOOL)deleteDistance:(Distance *)distance {
    DatabaseQueryBuilder *delete = [DatabaseQueryBuilder deleteStatementForTable:DistanceTable.TABLE_NAME];
    [delete addParam:DistanceTable.COLUMN_ID value:@(distance.objectId)];
    BOOL result = [self executeQuery:delete];
    if (result) {
        [[NSNotificationCenter defaultCenter] postNotificationName:DatabaseDidDeleteModelNotification object:distance];
    }
    return result;
}

- (BOOL)updateDistance:(Distance *)distance {
    DatabaseQueryBuilder *update = [DatabaseQueryBuilder updateStatementForTable:DistanceTable.TABLE_NAME];
    [update addParam:DistanceTable.COLUMN_DISTANCE value:distance.distance];
    [update addParam:DistanceTable.COLUMN_LOCATION value:distance.location];
    [update addParam:DistanceTable.COLUMN_DATE value:distance.date.milliseconds];
    [update addParam:DistanceTable.COLUMN_TIMEZONE value:distance.timeZone.name];
    [update addParam:DistanceTable.COLUMN_COMMENT value:distance.comment];
    [update addParam:DistanceTable.COLUMN_RATE_CURRENCY value:distance.rate.currency.code];
    [update addParam:DistanceTable.COLUMN_RATE value:distance.rate.amount];
    [update where:DistanceTable.COLUMN_ID value:@(distance.objectId)];
    BOOL result = [self executeQuery:update];
    if (result) {
        [[NSNotificationCenter defaultCenter] postNotificationName:DatabaseDidUpdateModelNotification object:distance];
    }
    return result;
}

- (NSDecimalNumber *)sumOfDistancesForTrip:(WBTrip *)trip {
    DatabaseQueryBuilder *sumStatement = [DatabaseQueryBuilder sumStatementForTable:DistanceTable.TABLE_NAME];
    [sumStatement setSumColumn:@"distance * rate"];
    [sumStatement where:DistanceTable.COLUMN_PARENT value:trip.name];
    return [self executeDecimalQuery:sumStatement];
}

@end
