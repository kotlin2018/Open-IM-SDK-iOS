//
//  OIMConversationInfo.h
//  OpenIMSDK
//
//  Created by x on 2022/2/11.
//

#import <Foundation/Foundation.h>

#import "OIMMessageInfo.h"

NS_ASSUME_NONNULL_BEGIN

/// 会话信息
///
@interface OIMConversationBaseInfo : NSObject

@property (nonatomic, nullable, copy) NSString *conversationID;

@end

/// 会话信息
///
@interface OIMConversationInfo : OIMConversationBaseInfo

@property (nonatomic, assign) OIMConversationType conversationType;

@property (nonatomic, nullable, copy) NSString *userID;

@property (nonatomic, nullable, copy) NSString *groupID;

@property (nonatomic, nullable, copy) NSString *showName;

@property (nonatomic, nullable, copy) NSString *faceURL;

@property (nonatomic, assign) OIMReceiveMessageOpt recvMsgOpt;

@property (nonatomic, assign) NSInteger unreadCount;

/*
 *  at信息持久展示，暂未使用
 */
@property (nonatomic, assign) NSInteger groupAtType;

@property (nonatomic, assign) NSInteger latestMsgSendTime;

@property (nonatomic, nullable, copy) NSString *draftText;

@property (nonatomic, assign) NSInteger draftTextTime;

@property (nonatomic, assign) BOOL isPinned;

@property (nonatomic, assign) BOOL isPrivateChat;

@property (nonatomic, nullable, copy) NSString *attachedInfo;

@property (nonatomic, nullable, strong) OIMMessageInfo *latestMsg;

@property (nonatomic, nullable, copy) NSString *ex;

@end

/// 免打扰会话信息
///
@interface OIMConversationNotDisturbInfo : OIMConversationBaseInfo

/*
 * 免打扰状态
 */
@property (nonatomic, assign) OIMReceiveMessageOpt result;

@end

NS_ASSUME_NONNULL_END
