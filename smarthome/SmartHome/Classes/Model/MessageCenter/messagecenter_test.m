//
//  main.m
//  Sqlite3Test
//
//  Created by sa on 14/03/2018.
//  Copyright © 2018 ICatch Technology Inc. All rights reserved.
//
#define TEST_MSG 1
#import <Foundation/Foundation.h>
#import "MessageCenter.h"
#import "SHFileOperation.h"
//int main(int argc, const char * argv[]) {
//    @autoreleasepool {
//        // insert code here...
//        NSLog(@"Hello, World!");
//        NSString* name = @"/Users/sa/Desktop/sh-ios/test.db";
//        SHFileOperation* shFOP = [SHFileOperation new];
//        MessageCenter* msgCenter = [[MessageCenter alloc] initWithName:name andMSGDelegate:shFOP];
//        NSArray* arr = [msgCenter getMessageWithStartIndex:1 andCount:5];
//        int cnt = [msgCenter getMessageCount];
//        NSLog(@"message count : %d", cnt);
//        MessageInfo * info = [[MessageInfo alloc] initWithMsgID:1 andDevID:@"jianchen" andDatetime:@"2018-01-01 00:00:00" andMsgType:201];
//        NSLog(@"test add message test : %d", [msgCenter addMessageWithMessageInfo:info]);
//        arr = [msgCenter getMessageWithStartIndex:1 andCount:[msgCenter getMessageCount]];
//        //MessageInfo* deleteInfo = [arr objectAtIndex:[arr count]-1];
//        //[deleteInfo debug];
//        //NSLog(@"test delte info : %d", [msgCenter deleteMessageWithMessageInfo:deleteInfo]);
//        //............
//        
//        NSArray* fileArr = [msgCenter getFileListWithMessageInfo:info];
//        int  i = 0;
//        NSLog(@"-----------------------------华丽分割线----------------------------------");
//        for(i = 0; i < fileArr.count; i ++) {
//            MsgFileInfo* fileInfo = [fileArr objectAtIndex:i];
//            [fileInfo debug];
//        }
//        FILE* fp = fopen("/Users/sa/Desktop/sh-ios/test_bak.jpg","wb");
//        NSData* pic = [msgCenter getThumbnailWithMsgFileInfo:[fileArr objectAtIndex:0]];
//        if(pic.length > 0) {
//            int myRet = (int)fwrite([pic bytes], 1, [pic length], fp);
//            if(myRet < 0) {
//                NSLog(@"write file fail : %d", myRet);
//            }
//        }
//        fclose(fp);
//    }
//    return 0;
//}

