
--1.0,创建 用户表 

CREATE TABLE Users (
    Id VARCHAR(10) NOT NULL PRIMARY KEY,
    Name VARCHAR(30) NOT NULL,
    IsMale TINYINT(1) NOT NULL DEFAULT 1,
    Birth DATE NULL,
    Password VARCHAR(30) NOT NULL,
    Introduction VARCHAR(100) NULL,
    HeadIndex INT NOT NULL DEFAULT 0,
    HeadCount INT NOT NULL DEFAULT 0,
    LastReadFriendMessageTime DATETIME NOT NULL DEFAULT '1000-01-01 00:00:00',
    LastReadGroupMessageTime DATETIME NOT NULL DEFAULT '1000-01-01 00:00:00',
    LastDeleteFriendMessageTime DATETIME NOT NULL DEFAULT '1000-01-01 00:00:00',
    LastDeleteGroupMessageTime DATETIME NOT NULL DEFAULT '1000-01-01 00:00:00',
    RegisteTime DATETIME NOT NULL,
    PhoneNumber VARCHAR(15) NULL,
    EmailNumber VARCHAR(254) NULL
);

---2.0， 用户在线表

CREATE TABLE UserOnline (
    Id INT AUTO_INCREMENT PRIMARY KEY,
    LoginTime DATETIME NOT NULL,
    LogoutTime DATETIME NOT NULL,
    UserId VARCHAR(10) NOT NULL,
    CONSTRAINT FK_UserOnline_User FOREIGN KEY (UserId) REFERENCES Users(Id)
);


---3.0, 用户分组表---
CREATE TABLE UserGroups (
    Id INT AUTO_INCREMENT PRIMARY KEY,
    UserId VARCHAR(10) NOT NULL,
    GroupName VARCHAR(10) NOT NULL,
    GroupType TINYINT NOT NULL,
    CONSTRAINT FK_UserGroup_User FOREIGN KEY (UserId) REFERENCES Users(Id)
);

-- 用户ID上的索引（加速按用户查询）
CREATE INDEX IX_UserGroup_UserId ON UserGroups(UserId);

-- 组合索引（加速按用户和类型的查询）
CREATE INDEX IX_UserGroup_User_Type ON UserGroups(UserId, GroupType);


CREATE TABLE ChatPrivates (
    Id INT AUTO_INCREMENT PRIMARY KEY,
    UserFromId VARCHAR(10) NOT NULL,
    UserTargetId VARCHAR(10) NOT NULL,
    Message TEXT NOT NULL,
    Time DATETIME NOT NULL,
    IsRetracted TINYINT(1) NOT NULL DEFAULT 0,
    RetractTime DATETIME NOT NULL DEFAULT '1000-01-01 00:00:00',
    CONSTRAINT FK_ChatPrivate_UserFrom FOREIGN KEY (UserFromId) REFERENCES Users(Id),
    CONSTRAINT FK_ChatPrivate_UserTarget FOREIGN KEY (UserTargetId) REFERENCES Users(Id)
);

-- 消息时间索引（常用排序字段）
CREATE INDEX IX_ChatPrivate_Time ON ChatPrivates(Time);

-- 用户关系索引（加速查询用户相关消息）
CREATE INDEX IX_ChatPrivate_UserPair ON ChatPrivates(UserFromId, UserTargetId);

-- 撤回状态索引
CREATE INDEX IX_ChatPrivate_Retracted ON ChatPrivates(IsRetracted);


CREATE TABLE ChatPrivateDetails (
    UserId VARCHAR(10) NOT NULL,
    ChatPrivateId INT NOT NULL,
    IsDeleted TINYINT(1) NOT NULL DEFAULT 0,
    Time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (UserId, ChatPrivateId),
    CONSTRAINT FK_ChatPrivateDetail_User FOREIGN KEY (UserId) REFERENCES Users(Id),
    CONSTRAINT FK_ChatPrivateDetail_ChatPrivate FOREIGN KEY (ChatPrivateId) REFERENCES ChatPrivates(Id)
);

-- 提升按用户查询的速度
CREATE INDEX IX_ChatPrivateDetail_User ON ChatPrivateDetails(UserId);

-- 提升按消息查询的速度
CREATE INDEX IX_ChatPrivateDetail_Message ON ChatPrivateDetails(ChatPrivateId);

-- 支持按时间排序的查询
CREATE INDEX IX_ChatPrivateDetail_Time ON ChatPrivateDetails(Time);


CREATE TABLE SacurityQuestions 
(
    Id INT AUTO_INCREMENT PRIMARY KEY,
    Question VARCHAR(50) NOT NULL,
    Answer VARCHAR(50) NOT NULL,
    UserId VARCHAR(10) NOT NULL,
    CONSTRAINT FK_SacurityQuestion_User FOREIGN KEY (UserId) REFERENCES Users(Id)
);

-- 加速用户查询
CREATE INDEX IX_SacurityQuestion_User ON SacurityQuestions(UserId);

-- 组合索引支持身份验证场景
CREATE INDEX IX_SacurityQuestion_Authentication ON SacurityQuestions(UserId, Question(30));



CREATE TABLE FriendRelations (
    Id INT AUTO_INCREMENT PRIMARY KEY,
    User1Id VARCHAR(10) NOT NULL,
    User2Id VARCHAR(10) NOT NULL,
    SmallUserId VARCHAR(10) AS (LEAST(User1Id, User2Id)) STORED,  -- MySQL 5.7+
    LargeUserId VARCHAR(10) AS (GREATEST(User1Id, User2Id)) STORED,  -- MySQL 5.7+
    `Grouping` VARCHAR(20) NOT NULL,
    GroupTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Remark VARCHAR(30) NULL,
    CantDisturb TINYINT(1) NOT NULL DEFAULT 0,
    IsTop TINYINT(1) NOT NULL DEFAULT 0,
    LastChatId INT NOT NULL DEFAULT 0,
    IsChatting TINYINT(1) NOT NULL DEFAULT 1
);


CREATE TABLE FriendRequests (
    Id INT AUTO_INCREMENT PRIMARY KEY,
    UserFromId VARCHAR(10) NOT NULL,
    UserTargetId VARCHAR(10) NOT NULL,
    `Group` VARCHAR(20) NOT NULL,  -- 使用反引号转义关键字
    Remark VARCHAR(50) NOT NULL,
    RequestTime DATETIME NOT NULL,
    Message TEXT NOT NULL,
    IsAccept TINYINT(1) NOT NULL DEFAULT 0,
    IsSolved TINYINT(1) NOT NULL DEFAULT 0,
    SolveTime DATETIME NULL,
    CONSTRAINT FK_FriendRequest_UserFrom FOREIGN KEY (UserFromId) REFERENCES `Users`(Id) ON DELETE CASCADE,
    CONSTRAINT FK_FriendRequest_UserTarget FOREIGN KEY (UserTargetId) REFERENCES `Users`(Id) ON DELETE CASCADE
);



CREATE TABLE FriendDeletes (
    Id INT AUTO_INCREMENT PRIMARY KEY,
    UserId1 VARCHAR(10) NOT NULL,
    UserId2 VARCHAR(10) NOT NULL,
    Time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_FriendDelete_User1 FOREIGN KEY (UserId1) REFERENCES `Users`(Id) ON DELETE CASCADE,
    CONSTRAINT FK_FriendDelete_User2 FOREIGN KEY (UserId2) REFERENCES `Users`(Id) ON DELETE CASCADE
);


CREATE TABLE `Groups` (
    Id VARCHAR(10) NOT NULL PRIMARY KEY,
    Name VARCHAR(30) NOT NULL,
    Description VARCHAR(100) NULL,
    CreateTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    HeadIndex INT NOT NULL DEFAULT 1,
    IsCustomHead TINYINT(1) NOT NULL DEFAULT 0,
    IsDisband TINYINT(1) NOT NULL DEFAULT 0,
    INDEX IX_Group_Name (Name)
) ENGINE=InnoDB;



CREATE TABLE ChatGroups (
    Id INT AUTO_INCREMENT PRIMARY KEY,
    UserFromId VARCHAR(10) NOT NULL,
    GroupId VARCHAR(10) NOT NULL,
    Message TEXT NOT NULL,
    Time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    IsRetracted TINYINT(1) NOT NULL DEFAULT 0,
    RetractTime DATETIME NOT NULL DEFAULT '1000-01-01 00:00:00',
    CONSTRAINT FK_ChatGroup_User FOREIGN KEY (UserFromId) REFERENCES `Users`(Id) ON DELETE CASCADE,
    CONSTRAINT FK_ChatGroup_Group FOREIGN KEY (GroupId) REFERENCES `Groups`(Id) ON DELETE CASCADE
);

-- 加速群组历史消息查询
CREATE INDEX IX_ChatGroup_Group ON ChatGroups(GroupId);



CREATE TABLE ChatGroupDetails (
    UserId VARCHAR(10) NOT NULL,
    ChatGroupId INT NOT NULL,
    IsDeleted TINYINT(1) NOT NULL DEFAULT 0,
    Time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (UserId, ChatGroupId),
    CONSTRAINT FK_ChatGroupDetail_User FOREIGN KEY (UserId) REFERENCES `Users`(Id) ON DELETE CASCADE,
    CONSTRAINT FK_ChatGroupDetail_ChatGroup FOREIGN KEY (ChatGroupId) REFERENCES ChatGroups(Id) ON DELETE CASCADE
);



CREATE TABLE GroupRelations (
    Id INT AUTO_INCREMENT PRIMARY KEY,
    GroupId VARCHAR(10) NOT NULL,
    UserId VARCHAR(10) NOT NULL,
    Status TINYINT NOT NULL DEFAULT 0,
    `Grouping` VARCHAR(20) NOT NULL,  -- 使用反引号转义关键字
    JoinTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    NickName VARCHAR(30) NULL,
    Remark VARCHAR(30) NULL,
    CantDisturb TINYINT(1) NOT NULL DEFAULT 0,
    IsTop TINYINT(1) NOT NULL DEFAULT 0,
    LastChatId INT NOT NULL DEFAULT 0,
    IsChatting TINYINT(1) NOT NULL DEFAULT 1,
    CONSTRAINT UQ_GroupRelation_UserGroup UNIQUE (GroupId, UserId),
    CONSTRAINT FK_GroupRelation_Group FOREIGN KEY (GroupId) REFERENCES `Groups`(Id) ON DELETE CASCADE,
    CONSTRAINT FK_GroupRelation_User FOREIGN KEY (UserId) REFERENCES `Users`(Id) ON DELETE CASCADE
);



CREATE TABLE GroupRequests (
    Id INT AUTO_INCREMENT PRIMARY KEY,
    UserFromId VARCHAR(10) NOT NULL,
    GroupId VARCHAR(10) NOT NULL,
    RequestTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `Grouping` VARCHAR(20) NOT NULL,  -- 使用反引号转义关键字
    Remark VARCHAR(50) NOT NULL,
    NickName VARCHAR(30) NOT NULL,
    Message TEXT NOT NULL,
    IsAccept TINYINT(1) NOT NULL DEFAULT 0,
    IsSolved TINYINT(1) NOT NULL DEFAULT 0,
    SolveTime DATETIME NULL,
    AcceptByUserId VARCHAR(10) NULL,
    CONSTRAINT FK_GroupRequest_UserFrom FOREIGN KEY (UserFromId) REFERENCES `Users`(Id) ON DELETE CASCADE,
    CONSTRAINT FK_GroupRequest_Group FOREIGN KEY (GroupId) REFERENCES `Groups`(Id) ON DELETE CASCADE,
    CONSTRAINT FK_GroupRequest_AcceptBy FOREIGN KEY (AcceptByUserId) REFERENCES `Users`(Id) ON DELETE SET NULL
);



CREATE TABLE GroupDeletes (
    Id INT AUTO_INCREMENT PRIMARY KEY,
    GroupId VARCHAR(10) NOT NULL,
    MemberId VARCHAR(10) NOT NULL,
    DeleteMethod TINYINT NOT NULL,
    OperateUserId VARCHAR(10) NOT NULL,
    Time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_GroupDelete_Group FOREIGN KEY (GroupId) REFERENCES `Groups`(Id) ON DELETE CASCADE,
    CONSTRAINT FK_GroupDelete_Member FOREIGN KEY (MemberId) REFERENCES `Users`(Id) ON DELETE CASCADE,
    CONSTRAINT FK_GroupDelete_OperateUser FOREIGN KEY (OperateUserId) REFERENCES `Users`(Id) ON DELETE CASCADE,
    CONSTRAINT CHK_GroupDelete_Method CHECK (DeleteMethod IN (0, 1, 2))
);






























