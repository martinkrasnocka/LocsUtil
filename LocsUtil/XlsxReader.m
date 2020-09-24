//
//  XlsxReader.m
//  LocsUtil
//
//  Created by Martin Krasnocka on 17/10/2017.
//  Copyright © 2017 Martin Krasnocka. All rights reserved.
//

#import "XlsxReader.h"
#import "ZipArchive.h"
#import "CXMLDocument.h"
#import "CXMLElement.h"

@implementation XlsxReader
{
    NSString * _tempPath;
    NSNumberFormatter * _integerFormatter;
    
    NSArray * _xlsx_sharedStrings;        // Content of sharedStrings.xml
    NSArray * _xlsx_ROWS;                // Content of sheetXX.xml
    NSArray * _xlsx_ROWS_Identifiers;    // Row identifiers
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _integerFormatter = [[NSNumberFormatter alloc] init];
        _integerFormatter.numberStyle = kCFNumberFormatterNoStyle;
    }
    return self;
}

- (NSArray *) loadXlsxFromFileAtPath:(NSString *)filePath
{
    ZipArchive * archive = [[ZipArchive alloc] init];
    if ([archive UnzipOpenFile:filePath] == NO) {
        NSLog(@"Unable to open file %@", filePath);
        return nil;
    }
    NSFileManager * manager = [NSFileManager defaultManager];
    NSString * tempName = [filePath lastPathComponent];
    _tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent: [NSString stringWithFormat: @"/LocsUtil-%.0f/%@/", [NSDate timeIntervalSinceReferenceDate] * 1000.0, tempName]];
    NSError * error = nil;
    if ([manager createDirectoryAtPath:_tempPath withIntermediateDirectories:YES attributes:nil error:&error] == NO) {
        NSLog(@"Unable to create temporary directory %@. Debug error %@", _tempPath, [error localizedDescription]);
        return nil;
    }
    if ([archive UnzipFileTo:_tempPath overWrite:YES] == NO) {
        NSLog(@"Unzip XLSX file failed.");
        [self clearTempFiles];
        return nil;
    }
    
    NSArray * result = [self processXLSX];
    [self clearTempFiles];
    if (result) {
        NSLog(@"--- XLSX loading OK ---");
    }
    return result;
}

- (void) clearTempFiles
{
    if (_tempPath) {
        [[NSFileManager defaultManager] removeItemAtPath:_tempPath error:NULL];
    }
}

- (NSString*) xlsxFile:(NSString*)relativePath
{
    return [NSString stringWithFormat:@"%@/%@", _tempPath, relativePath];
}

- (NSString*) xlsxFileContent:(NSString*)relativePath
{
    NSString * path = [self xlsxFile:relativePath];
    NSError * error = nil;
    NSString * str = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if (!str || error) {
        NSLog(@"Could not open XLSX internal file %@. Debug error %@", path, [error localizedDescription]);
        return nil;
    }
    return str;
}

- (NSArray*) processXLSX
{
    @autoreleasepool
    {
        if (![self loadSharedStrings]) {
            return nil;
        }
        if (![self loadSheetRows:@"sheet1"]) {
            return nil;
        }
//        if (![self loadSheetRows:@"sheet2"]) {
//            return nil;
//        }
        return _xlsx_ROWS;
    }
}

- (BOOL) loadSharedStrings
{
    NSString * sharedStrings = [self xlsxFileContent:@"xl/sharedStrings.xml"];
    if (!sharedStrings) {
        return NO;
    }
    
    // Parse shared strings
    NSError * error = nil;
    CXMLDocument * doc = [[CXMLDocument alloc] initWithXMLString:sharedStrings options:0 error:&error];
    if (!doc) {
        NSLog(@"Unable to parse xl/sharedStrings.xml");
        return NO;
    }
    CXMLElement * root = doc.rootElement;
    __block BOOL failed = NO;
    
    NSMutableArray * shared = [NSMutableArray arrayWithCapacity:root.children.count];
    NSLog(@"Loading shared strings from xl/sharedStrings.xml...");
    [root.children enumerateObjectsUsingBlock:^(CXMLNode * node, NSUInteger idx, BOOL *stop) {
        if ([node.name isEqualToString:@"si"] && (node.kind == CXMLElementKind)) {
            NSArray * textNodes = [(CXMLElement*)node elementsForName:@"t"];
            CXMLNode * textNode = textNodes.count > 0 ? textNodes[0] : nil;
            if (!textNode) {
                NSLog(@"- %3d. Node doesn't contain text node <t>", (int)idx);
                [shared addObject:[NSNull null]];
            } else {
                if (textNode.kind == CXMLElementKind) {
                    NSString * value = [node stringValue];
                    //OSXLog(@"- %3d. '%@'", idx, value);
                    [shared addObject:value];
                } else {
                    NSLog(@"Parsing xl/sharedStrings.xml failed at index %d. Node is not an element.", (int)idx);
                    *stop = failed = YES;
                }
            }
        } else {
            NSLog(@"Parsing xl/sharedStrings.xml failed at index %d with unexpected item <%@>", (int)idx, node.name);
            *stop = failed = YES;
        }
    }];
    if (!failed) {
        NSLog(@"Shared strings were successfully loaded.");
        _xlsx_sharedStrings = [shared copy];
        return YES;
    }
    return NO;
}

- (BOOL) loadSheetRows:(NSString *)worksheetName
{
    NSString * sheetPath = [NSString stringWithFormat:@"xl/worksheets/%@.xml", worksheetName];
    NSString * sheetContent = [self xlsxFileContent:sheetPath];
    if (!sheetContent) {
        return NO;
    }
    NSError * error = nil;
    CXMLDocument * doc = [[CXMLDocument alloc] initWithXMLString:sheetContent options:0 error:&error];
    if (!doc) {
        NSLog(@"Unable to parse %@", sheetPath);
        return NO;
    }
    
    NSLog(@"Loading worksheet from %@ ...", sheetPath);
    
    NSArray * nodeElements = [doc.rootElement elementsForName:@"sheetData"];
    CXMLNode * node = nodeElements.count > 0 ? nodeElements[0] : nil;
    if (!node) {
        NSLog(@"The sheetData element not found.");
        return NO;
    }
    
    //
    // At first state, rowsRawArray contains [ { "column" : "value", ... } ] array
    //
    NSMutableArray * rowsRawArray = [NSMutableArray arrayWithCapacity:node.childCount];
    NSMutableArray * rowsIdsArray = [NSMutableArray arrayWithCapacity:node.childCount];
    
    __block BOOL failure = NO;
    //
    [node.children enumerateObjectsUsingBlock:^(CXMLNode * rowNode, NSUInteger ridx, BOOL *stop) {
        //
        // Row processing
        //
        __block BOOL success = YES;
        //
        if (rowNode.kind == CXMLElementKind && [rowNode.name isEqualToString:@"row"]) {
            CXMLElement * rowElement = (CXMLElement*)rowNode;
            NSString * rowIndexString = [rowElement attributeForName:@"r"].stringValue;
            if (rowIndexString) {
                NSNumber * rowIndexNumber = [_integerFormatter numberFromString:rowIndexString];
                if (rowIndexNumber) {
                    // Build row dictionary
                    NSMutableDictionary * columns = [NSMutableDictionary dictionaryWithCapacity:rowElement.childCount];
                    //
                    [[rowElement elementsForName:@"c"] enumerateObjectsUsingBlock:^(CXMLElement * column, NSUInteger cidx, BOOL *stop) {
                        //
                        // Column processing
                        //
                        NSString * cellIdentifier = [column attributeForName:@"r"].stringValue;
                        NSString * columnIdentifier = nil;;
                        if (cellIdentifier && cellIdentifier.length > 0) {
                            columnIdentifier = [cellIdentifier substringToIndex:1];
                        } else {
                            NSLog(@"Column [%d, %d] Doesn't have valid identifier.", (int)ridx, (int)cidx);
                            success = NO;
                        }
                        
                        NSString * columnValueType = [column attributeForName:@"t"].stringValue;
                        if (!columnValueType) {
//                            NSLog(@"- Column [%d, %d] (%@) Doesn't have type identifier.", (int)ridx, (int)cidx, cellIdentifier);
                        }
                        
                        NSArray * columnValueElements = [column elementsForName:@"v"];
                        NSString * columnValue = nil;
                        CXMLElement * columnValueElm = columnValueElements.count > 0 ? columnValueElements[0] : nil;
                        if (columnValueElm) {
                            if (columnValueType) {
                                columnValue = columnValueElm.stringValue;
                                if (columnValue) {
                                    if ([columnValueType isEqualToString:@"s"]) {
                                        // shared string
                                        columnValue = [self sharedStringWithCellContent:columnValue];
                                        if (!columnValue) {
                                            NSLog(@"- Column [%d, %d] (%@) Unable to translate string value.", (int)ridx, (int)cidx, cellIdentifier);
                                        }
                                    } else {
                                        NSLog(@"- Column [%d, %d] (%@) Has uknown value type %@.", (int)ridx, (int)cidx, cellIdentifier, columnValueType);
                                    }
                                }
                            } else {
                                // Probably exact value
                                columnValue = columnValueElm.stringValue;
                            }
                        } else {
                            if (columnValueType) {
                                NSLog(@"- Column [%d, %d] (%@) Doesn't have value.", (int)ridx, (int)cidx, cellIdentifier);
                            }
                        }
                        
                        if (columnValue && columnIdentifier) {
                            [columns setObject:columnValue forKey:columnIdentifier];
                        }
                        
                        if (!success) {
                            *stop = YES;
                        }
                        //
                        // end of column block
                    }];
                    
                    if (success) {
                        [rowsRawArray addObject:[columns copy]];
                        [rowsIdsArray addObject:rowIndexNumber];
                    }
                    
                } else {
                    NSLog(@"Row at index %d has wrong index value '%@'.", (int)ridx, rowIndexString);
                    success = NO;
                }
            } else {
                NSLog(@"Row at index %d has wrong index value '%@'.", (int)ridx, rowIndexString);
                success = NO;
            }
        }
        
        if (!success) {
            *stop = failure = YES;
        }
        
        //
        // end of row block
    }];
    
    if (!failure) {
        NSLog(@"Worksheet was successfully loaded.");
        if (_xlsx_ROWS == nil) {
            _xlsx_ROWS = [rowsRawArray copy];
        } else {
            _xlsx_ROWS = [_xlsx_ROWS arrayByAddingObjectsFromArray:[rowsRawArray copy]];
        }
        if (_xlsx_ROWS_Identifiers == nil) {
            _xlsx_ROWS_Identifiers = [rowsIdsArray copy];
        } else {
            _xlsx_ROWS_Identifiers = [_xlsx_ROWS_Identifiers arrayByAddingObjectsFromArray:[rowsIdsArray copy]];
        }
        return YES;
    }
    
    return NO;
}

- (NSString*) sharedStringWithCellContent:(NSString*)cellContent
{
    NSNumber * n = [_integerFormatter numberFromString:cellContent];
    if (!n) {
        NSLog(@"Cell contains invalid index %@", cellContent);
        return nil;
    }
    return [self sharedStringWithIndex:n.unsignedIntegerValue];
}

- (NSString*) sharedStringWithIndex:(NSUInteger)index
{
    if (index >= _xlsx_sharedStrings.count) {
        NSLog(@"Index %d to shared strings table is out of range.", (int)index);
        return nil;
    }
    return [_xlsx_sharedStrings objectAtIndex:index];
}

@end
