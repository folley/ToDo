// AFRESTClient.m
//
// Copyright (c) 2012 Mattt Thompson (http://mattt.me)
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "AFRESTClient.h"
#include <time.h>
#include <xlocale.h>

#define AF_ISO8601_MAX_LENGTH 25

// Adopted from SSToolkit NSDate+SSToolkitAdditions
// Created by Sam Soffes
// Copyright (c) 2008-2012 Sam Soffes
// https://github.com/soffes/sstoolkit/
NSDate * AFDateFromISO8601String(NSString *ISO8601String) {
    if (!ISO8601String) {
        return nil;
    }
    
    const char *str = [ISO8601String cStringUsingEncoding:NSUTF8StringEncoding];
    char newStr[AF_ISO8601_MAX_LENGTH];
    bzero(newStr, AF_ISO8601_MAX_LENGTH);
    
    size_t len = strlen(str);
    if (len == 0) {
        return nil;
    }
    
    // UTC dates ending with Z
    if (len == 20 && str[len - 1] == 'Z') {
        memcpy(newStr, str, len - 1);
        strncpy(newStr + len - 1, "+0000\0", 6);
    }
    
    // Timezone includes a semicolon (not supported by strptime)
    else if (len == 25 && str[22] == ':') {
        memcpy(newStr, str, 22);
        memcpy(newStr + 22, str + 23, 2);
    }
    
    // Fallback: date was already well-formatted OR any other case (bad-formatted)
    else {
        memcpy(newStr, str, len > AF_ISO8601_MAX_LENGTH - 1 ? AF_ISO8601_MAX_LENGTH - 1 : len);
    }
    
    // Add null terminator
    newStr[sizeof(newStr) - 1] = 0;
    
    struct tm tm = {
        .tm_sec = 0,
        .tm_min = 0,
        .tm_hour = 0,
        .tm_mday = 0,
        .tm_mon = 0,
        .tm_year = 0,
        .tm_wday = 0,
        .tm_yday = 0,
        .tm_isdst = -1,
    };
    
    strptime_l(newStr, "%Y-%m-%d %H:%M:%S %z", &tm, NULL);
    
    return [NSDate dateWithTimeIntervalSince1970:mktime(&tm)];
}

static NSString * AFPluralizedString(NSString *string) {
    if ([string hasSuffix:@"ss"] || [string hasSuffix:@"se"] || [string hasSuffix:@"sh"] || [string hasSuffix:@"ch"]) {
        return [[string stringByAppendingString:@"es"] lowercaseString];
    } else {
        return [[string stringByAppendingString:@"s"] lowercaseString];
    }
}

@implementation AFRESTClient

- (NSString *)pathForEntity:(NSEntityDescription *)entity {
    return AFPluralizedString(entity.name);
}

- (NSString *)pathForObject:(NSManagedObject *)object {
    NSString *resourceIdentifier = AFResourceIdentifierFromReferenceObject([(NSIncrementalStore *)object.objectID.persistentStore referenceObjectForObjectID:object.objectID]);
    return [[self pathForEntity:object.entity] stringByAppendingPathComponent:[resourceIdentifier lastPathComponent]];
}

- (NSString *)pathForRelationship:(NSRelationshipDescription *)relationship 
                        forObject:(NSManagedObject *)object
{
    return [[self pathForObject:object] stringByAppendingPathComponent:relationship.name];
}

#pragma mark - AFIncrementalStoreHTTPClient

#pragma mark Read Methods

- (id)representationOrArrayOfRepresentationsFromResponseObject:(id)responseObject {
    if ([responseObject isKindOfClass:[NSArray class]]) {
        return responseObject;
    } else if ([responseObject isKindOfClass:[NSDictionary class]]) {
        // Distinguish between keyed array or individual representation
        if ([[responseObject allKeys] count] == 1) {
            id value = [responseObject valueForKey:[[responseObject allKeys] lastObject]];
            if ([value isKindOfClass:[NSArray class]]) {
                return value;
            }
        }
        
        return responseObject;
    }
    
    return responseObject;
}

- (NSDictionary *)representationsForRelationshipsFromRepresentation:(NSDictionary *)representation
                                                           ofEntity:(NSEntityDescription *)entity
                                                       fromResponse:(NSHTTPURLResponse *)response
{
    NSMutableDictionary *mutableRelationshipRepresentations = [NSMutableDictionary dictionaryWithCapacity:[entity.relationshipsByName count]];
    [entity.relationshipsByName enumerateKeysAndObjectsUsingBlock:^(id name, id relationship, BOOL *stop) {
        id value = [representation valueForKey:name];
        if (value) {
            if ([relationship isToMany]) {
                NSArray *arrayOfRelationshipRepresentations = nil;
                if ([value isKindOfClass:[NSArray class]]) {
                    arrayOfRelationshipRepresentations = value;
                } else {
                    arrayOfRelationshipRepresentations = [NSArray arrayWithObject:value];
                }
                                
                [mutableRelationshipRepresentations setValue:arrayOfRelationshipRepresentations forKey:name];
            } else {
                [mutableRelationshipRepresentations setValue:value forKey:name];
            }
        }
    }];
    
    return mutableRelationshipRepresentations;
}

- (NSString *)resourceIdentifierForRepresentation:(NSDictionary *)representation
                                         ofEntity:(NSEntityDescription *)entity
                                     fromResponse:(NSHTTPURLResponse *)response
{
    static NSArray *_candidateKeys = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _candidateKeys = [[NSArray alloc] initWithObjects:@"id", @"identifier", @"url", @"URL", nil];
    });
    
    NSString *key = [[representation allKeys] firstObjectCommonWithArray:_candidateKeys];
    if (key) {
        id value = [representation valueForKey:key];
        if (value) {
            return [value description];
        }
    }
    
    return nil;
}

- (NSDictionary *)attributesForRepresentation:(NSDictionary *)representation
                                     ofEntity:(NSEntityDescription *)entity
                                 fromResponse:(NSHTTPURLResponse *)response
{
    if ([representation isEqual:[NSNull null]]) {
        return nil;
    }
    
    NSMutableDictionary *mutableAttributes = [representation mutableCopy];
    @autoreleasepool {
        NSMutableSet *mutableKeys = [NSMutableSet setWithArray:[representation allKeys]];
        [mutableKeys minusSet:[NSSet setWithArray:[[entity propertiesByName] allKeys]]];
        [mutableAttributes removeObjectsForKeys:[mutableKeys allObjects]];
    }
    
    NSSet *keysWithNestedValues = [mutableAttributes keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
        return [obj isKindOfClass:[NSArray class]] || [obj isKindOfClass:[NSDictionary class]];
    }];
    [mutableAttributes removeObjectsForKeys:[keysWithNestedValues allObjects]];
    
    [[entity attributesByName] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([(NSAttributeDescription *)obj attributeType] == NSDateAttributeType) {
            id value = [mutableAttributes valueForKey:key];
            if (value && ![value isEqual:[NSNull null]]) {
                [mutableAttributes setValue:AFDateFromISO8601String(value) forKey:key];
            }
        }
    }];
    
    return mutableAttributes;
}

- (NSMutableURLRequest *)requestForFetchRequest:(NSFetchRequest *)fetchRequest
                                    withContext:(NSManagedObjectContext *)context
{
    NSMutableURLRequest *mutableRequest =  [self requestWithMethod:@"GET" path:[self pathForEntity:fetchRequest.entity] parameters:nil];
    mutableRequest.cachePolicy = NSURLRequestReturnCacheDataElseLoad;
    
    return mutableRequest;
}

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                       pathForObjectWithID:(NSManagedObjectID *)objectID
                               withContext:(NSManagedObjectContext *)context
{
    NSManagedObject *object = [context objectWithID:objectID];
    return [self requestWithMethod:method path:[self pathForObject:object] parameters:nil];
}

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                       pathForRelationship:(NSRelationshipDescription *)relationship
                           forObjectWithID:(NSManagedObjectID *)objectID
                               withContext:(NSManagedObjectContext *)context
{
    NSManagedObject *object = [context objectWithID:objectID];
    return [self requestWithMethod:method path:[self pathForRelationship:relationship forObject:object] parameters:nil];
}

- (BOOL)shouldFetchRemoteValuesForRelationship:(NSRelationshipDescription *)relationship
                               forObjectWithID:(NSManagedObjectID *)objectID
                        inManagedObjectContext:(NSManagedObjectContext *)context
{
    return [relationship isToMany] || ![relationship inverseRelationship];
}

#pragma mark Write Methods

- (NSDictionary *)representationOfAttributes:(NSDictionary *)attributes
                             ofManagedObject:(NSManagedObject *)managedObject
{
    return attributes;
}

- (NSMutableURLRequest *)requestForInsertedObject:(NSManagedObject *)insertedObject {
    NSLog(@"request for INSTERTED object polecial");
    
    return [self requestWithMethod:@"POST" path:[self pathForEntity:insertedObject.entity] parameters:[self representationOfAttributes:[insertedObject dictionaryWithValuesForKeys:[insertedObject.entity.attributesByName allKeys]] ofManagedObject:insertedObject]];
}

- (NSMutableURLRequest *)requestForUpdatedObject:(NSManagedObject *)updatedObject {
    NSLog(@"request for UPDATED object polecial");
    
    NSMutableSet *mutableChangedAttributeKeys = [NSMutableSet setWithArray:[[updatedObject changedValues] allKeys]];
    [mutableChangedAttributeKeys intersectSet:[NSSet setWithArray:[updatedObject.entity.attributesByName allKeys]]];
    
    return [self requestWithMethod:@"PUT" path:[self pathForObject:updatedObject] parameters:[self representationOfAttributes:[[updatedObject changedValues] dictionaryWithValuesForKeys:[mutableChangedAttributeKeys allObjects]] ofManagedObject:updatedObject]];
}

- (NSMutableURLRequest *)requestForDeletedObject:(NSManagedObject *)deletedObject {
    NSLog(@"request for DELETED object polecial");
    return [self requestWithMethod:@"DELETE" path:[self pathForObject:deletedObject] parameters:nil];
}

#pragma mark - AFHTTPClient

- (void)enqueueHTTPRequestOperation:(AFHTTPRequestOperation *)operation {
    [self cancelAllHTTPOperationsWithMethod:operation.request.HTTPMethod path:operation.request.URL.path];
    [super enqueueHTTPRequestOperation:operation];
}

@end
