/*
 * ============================================================
 * CoderClub 数据库初始化脚本（结构重建 + 种子数据）
 * ------------------------------------------------------------
 * 依据：云端 coder-club dump（25 表，腾讯云 8.4.11）+ grill 改造共识（2026-08-31，用户逐项确认）
 * 用途：后端项目数据库的**开发数据依据**（B-Impl 落地到后端 docs/database/）
 * 约定（grill Q1-Q12 共识）：
 *   1. 全库 DROP 重建，字符集统一 utf8mb4 / collation utf8mb4_0900_ai_ci
 *   2. 23 张既有表保持业务字段结构；修正项：share_comment_reply 删弃用列+单列主键、
 *      is_deleted 统一 DEFAULT 0、share_message.is_read 默认 2、practice_detail.answer_content→512、
 *      高频查询列补索引
 *   3. 新增 interview 3 表（interview_history / interview_question_history / interview_keyword，utf8mb4）
 *   4. Redis 作读写加速层（缓存/计数/排行/会话/锁），表保留持久兜底字段
 *   5. 种子数据：语义化占位（规则 8，无真实环境信息）；测试账号密码统一 123456，
 *      存 BCrypt 哈希（$2a$10$RnrjjuXTYfnzb.uXETp0Juu/u.EV547TArFj8k07x97dL1DQ4uCQO，可被后端 matches 验证）
 * 测试账号：admin/123456（管理员）、test01~test04/123456（普通用户）
 * ============================================================
 */

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================
-- 一、建表（26 张）
-- ============================================================

-- ------------------------------------------------------------
-- auth 域
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `auth_permission`;
CREATE TABLE `auth_permission` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '权限名称',
  `parent_id` bigint NULL DEFAULT NULL COMMENT '父id',
  `type` tinyint NULL DEFAULT NULL COMMENT '权限类型 0菜单 1操作',
  `menu_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '菜单路由',
  `status` tinyint NULL DEFAULT NULL COMMENT '状态 0启用 1禁用',
  `show` tinyint NULL DEFAULT NULL COMMENT '展示状态 0展示 1隐藏',
  `icon` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '图标',
  `permission_key` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '权限唯一标识',
  `created_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '创建人',
  `created_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '更新人',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `is_deleted` int NOT NULL DEFAULT 0 COMMENT '是否被删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 100 COMMENT = '权限表' ROW_FORMAT = Dynamic;

DROP TABLE IF EXISTS `auth_role`;
CREATE TABLE `auth_role` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `role_name` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '角色名称',
  `role_key` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '角色唯一标识',
  `created_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '创建人',
  `created_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '更新人',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `is_deleted` int NOT NULL DEFAULT 0 COMMENT '是否被删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 100 COMMENT = '角色表' ROW_FORMAT = Dynamic;

DROP TABLE IF EXISTS `auth_role_permission`;
CREATE TABLE `auth_role_permission` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `role_id` bigint NULL DEFAULT NULL COMMENT '角色id',
  `permission_id` bigint NULL DEFAULT NULL COMMENT '权限id',
  `created_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '创建人',
  `created_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '更新人',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `is_deleted` int NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_role_id`(`role_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 100 COMMENT = '角色权限关联表' ROW_FORMAT = Dynamic;

DROP TABLE IF EXISTS `auth_user`;
CREATE TABLE `auth_user` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_name` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '用户名称/账号',
  `nick_name` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '昵称',
  `email` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '邮箱',
  `phone` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '手机号',
  `password` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '密码（BCrypt）',
  `sex` tinyint NULL DEFAULT NULL COMMENT '性别',
  `avatar` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '头像',
  `status` tinyint NULL DEFAULT NULL COMMENT '状态 0启用 1禁用',
  `introduce` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '个人介绍',
  `ext_json` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '特殊字段',
  `created_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '创建人',
  `created_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '更新人',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `is_deleted` int NOT NULL DEFAULT 0 COMMENT '是否被删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 100 COMMENT = '用户信息表' ROW_FORMAT = Dynamic;

DROP TABLE IF EXISTS `auth_user_role`;
CREATE TABLE `auth_user_role` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` bigint NULL DEFAULT NULL COMMENT '用户id',
  `role_id` bigint NULL DEFAULT NULL COMMENT '角色id',
  `created_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '创建人',
  `created_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '更新人',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `is_deleted` int NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_user_id`(`user_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 100 COMMENT = '用户角色表' ROW_FORMAT = Dynamic;

-- ------------------------------------------------------------
-- interview 域（新增，grill Q7 设计）
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `interview_history`;
CREATE TABLE `interview_history` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` bigint NULL DEFAULT NULL COMMENT '用户id',
  `category_id` bigint NULL DEFAULT NULL COMMENT '面试分类id',
  `avg_score` decimal(5, 2) NULL DEFAULT NULL COMMENT '平均分（0-100）',
  `score_text` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '分数段文案',
  `created_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '创建人',
  `created_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '更新人',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `is_deleted` int NOT NULL DEFAULT 0 COMMENT '是否被删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_user_id`(`user_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 100 COMMENT = '面试记录表' ROW_FORMAT = Dynamic;

DROP TABLE IF EXISTS `interview_question_history`;
CREATE TABLE `interview_question_history` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `history_id` bigint NOT NULL COMMENT '面试记录id',
  `question_id` bigint NULL DEFAULT NULL COMMENT '题目id',
  `answer` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '用户答案',
  `hit_keywords` json NULL COMMENT '命中关键词（JSON 数组）',
  `score` decimal(5, 2) NULL DEFAULT NULL COMMENT '得分（0-100）',
  `score_text` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '分数段文案',
  `created_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '创建人',
  `created_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '更新人',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `is_deleted` int NOT NULL DEFAULT 0 COMMENT '是否被删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_history_id`(`history_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 100 COMMENT = '面试答题记录表' ROW_FORMAT = Dynamic;

DROP TABLE IF EXISTS `interview_keyword`;
CREATE TABLE `interview_keyword` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `category_id` bigint NULL DEFAULT NULL COMMENT '关联分类id',
  `keyword` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '评分关键词',
  `weight` int NULL DEFAULT 1 COMMENT '权重（默认1）',
  `created_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '创建人',
  `created_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '更新人',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `is_deleted` int NOT NULL DEFAULT 0 COMMENT '是否被删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_category_id`(`category_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 100 COMMENT = '面试评分关键词表' ROW_FORMAT = Dynamic;

-- ------------------------------------------------------------
-- practice 域
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `practice_detail`;
CREATE TABLE `practice_detail` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `practice_id` bigint NULL DEFAULT NULL COMMENT '练题id',
  `subject_id` bigint NULL DEFAULT NULL COMMENT '题目id',
  `subject_type` int NULL DEFAULT NULL COMMENT '题目类型',
  `answer_status` int NULL DEFAULT NULL COMMENT '回答状态',
  `answer_content` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '回答内容',
  `created_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '创建人',
  `created_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '更新人',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `is_deleted` int NOT NULL DEFAULT 0 COMMENT '是否被删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_practice_id`(`practice_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 100 COMMENT = '练习详情表' ROW_FORMAT = Dynamic;

DROP TABLE IF EXISTS `practice_info`;
CREATE TABLE `practice_info` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `set_id` bigint NULL DEFAULT NULL COMMENT '套题id',
  `complete_status` int NULL DEFAULT NULL COMMENT '是否完成 1完成 0未完成',
  `time_use` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '用时',
  `submit_time` datetime NULL DEFAULT NULL COMMENT '交卷时间',
  `correct_rate` decimal(10, 2) NULL DEFAULT NULL COMMENT '正确率',
  `created_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '创建人',
  `created_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '更新人',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `is_deleted` int NOT NULL DEFAULT 0 COMMENT '是否被删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 100 COMMENT = '练习表' ROW_FORMAT = Dynamic;

DROP TABLE IF EXISTS `practice_set`;
CREATE TABLE `practice_set` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `set_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '套题名称',
  `set_type` int NULL DEFAULT NULL COMMENT '套题类型 1实时生成 2预设套题',
  `set_heat` int NULL DEFAULT NULL COMMENT '热度',
  `set_desc` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '套题描述',
  `primary_category_id` bigint NULL DEFAULT NULL COMMENT '大类id',
  `created_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '创建人',
  `created_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '更新人',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `is_deleted` int NOT NULL DEFAULT 0 COMMENT '是否被删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 100 COMMENT = '套题信息表' ROW_FORMAT = Dynamic;

DROP TABLE IF EXISTS `practice_set_detail`;
CREATE TABLE `practice_set_detail` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `set_id` bigint NOT NULL COMMENT '套题id',
  `subject_id` bigint NULL DEFAULT NULL COMMENT '题目id',
  `subject_type` int NULL DEFAULT NULL COMMENT '题目类型',
  `created_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '创建人',
  `created_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '更新人',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `is_deleted` int NOT NULL DEFAULT 0 COMMENT '是否被删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_set_id`(`set_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 100 COMMENT = '套题内容表' ROW_FORMAT = Dynamic;

-- ------------------------------------------------------------
-- sensitive_words（敏感词）
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `sensitive_words`;
CREATE TABLE `sensitive_words` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT 'id',
  `words` varchar(1024) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '内容',
  `type` int NULL DEFAULT 0 COMMENT '1=黑名单 2=白名单',
  `created_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `is_deleted` int NOT NULL DEFAULT 0 COMMENT '是否被删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 100 COMMENT = '敏感词表' ROW_FORMAT = Dynamic;

-- ------------------------------------------------------------
-- share 域（圈子/动态/评论/消息）
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `share_circle`;
CREATE TABLE `share_circle` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '圈子ID',
  `parent_id` bigint NOT NULL COMMENT '父级ID,-1为大类',
  `circle_name` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '圈子名称',
  `icon` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '圈子图片',
  `created_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '创建人',
  `created_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '更新人',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `is_deleted` int NOT NULL DEFAULT 0 COMMENT '是否被删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_parent_id`(`parent_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 100 COMMENT = '圈子信息' ROW_FORMAT = Dynamic;

DROP TABLE IF EXISTS `share_comment_reply`;
CREATE TABLE `share_comment_reply` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '评论ID',
  `moment_id` bigint NOT NULL COMMENT '原始动态ID',
  `reply_type` int NOT NULL COMMENT '回复类型 1评论 2回复',
  `to_id` bigint NULL DEFAULT NULL COMMENT '评论目标id（type1=动态作者/type2=被回复评论者，读时派生人员语义）',
  `reply_id` bigint NULL DEFAULT NULL COMMENT '回复目标id',
  `parent_id` bigint NULL DEFAULT NULL COMMENT '父评论id（0=顶层）',
  `content` varchar(1024) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '内容',
  `pic_urls` varchar(1024) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '图片内容',
  `created_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '创建人',
  `created_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '更新人',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `is_deleted` int NOT NULL DEFAULT 0 COMMENT '是否被删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_moment_id`(`moment_id` ASC) USING BTREE,
  INDEX `idx_parent_id`(`parent_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 100 COMMENT = '评论及回复信息' ROW_FORMAT = Dynamic;

DROP TABLE IF EXISTS `share_message`;
CREATE TABLE `share_message` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `from_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '来自人（登录标识）',
  `to_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '送达人（登录标识）',
  `content` varchar(256) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '消息内容（JSON 结构化）',
  `is_read` int NOT NULL DEFAULT 2 COMMENT '是否已读 1=已读 2=未读',
  `created_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '创建人',
  `created_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '更新人',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `is_deleted` int NOT NULL DEFAULT 0 COMMENT '是否被删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_to_id`(`to_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 100 COMMENT = '消息表' ROW_FORMAT = Dynamic;

DROP TABLE IF EXISTS `share_moment`;
CREATE TABLE `share_moment` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '动态ID',
  `circle_id` bigint NOT NULL COMMENT '圈子ID',
  `content` varchar(1024) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '动态内容',
  `pic_urls` varchar(1024) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '动态图片内容',
  `reply_count` int NOT NULL DEFAULT 0 COMMENT '回复数',
  `created_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '创建人',
  `created_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '更新人',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `is_deleted` int NOT NULL DEFAULT 0 COMMENT '是否被删除 0未删除 1已删除',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_circle_id`(`circle_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 100 COMMENT = '动态信息' ROW_FORMAT = Dynamic;

-- ------------------------------------------------------------
-- subject 域
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `subject_brief`;
CREATE TABLE `subject_brief` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `subject_id` bigint NULL DEFAULT NULL COMMENT '题目id',
  `subject_answer` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '题目答案',
  `created_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '创建人',
  `created_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '更新人',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `is_deleted` int NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_subject_id`(`subject_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 100 COMMENT = '简答题' ROW_FORMAT = Dynamic;

DROP TABLE IF EXISTS `subject_category`;
CREATE TABLE `subject_category` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `category_name` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '分类名称',
  `category_type` tinyint NULL DEFAULT NULL COMMENT '分类类型',
  `image_url` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '图标连接',
  `parent_id` bigint NULL DEFAULT NULL COMMENT '父级id',
  `sort` int NULL DEFAULT NULL COMMENT '排序（升序，空值排最后）',
  `created_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '创建人',
  `created_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '更新人',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `is_deleted` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否删除 0: 未删除 1: 已删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 100 COMMENT = '题目分类' ROW_FORMAT = Dynamic;

DROP TABLE IF EXISTS `subject_info`;
CREATE TABLE `subject_info` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `subject_name` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '题目名称',
  `subject_difficult` tinyint NULL DEFAULT NULL COMMENT '题目难度',
  `settle_name` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '出题人名',
  `subject_type` tinyint NULL DEFAULT NULL COMMENT '题目类型 1单选 2多选 3判断 4简答',
  `subject_score` tinyint NULL DEFAULT NULL COMMENT '题目分数',
  `subject_parse` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '题目解析',
  `created_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '创建人',
  `created_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '修改人',
  `update_time` datetime NULL DEFAULT NULL COMMENT '修改时间',
  `is_deleted` int NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 100 COMMENT = '题目信息表' ROW_FORMAT = Dynamic;

DROP TABLE IF EXISTS `subject_judge`;
CREATE TABLE `subject_judge` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `subject_id` bigint NULL DEFAULT NULL COMMENT '题目id',
  `is_correct` tinyint NULL DEFAULT NULL COMMENT '是否正确',
  `created_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '创建人',
  `created_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '更新人',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `is_deleted` int NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_subject_id`(`subject_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 100 COMMENT = '判断题' ROW_FORMAT = Dynamic;

DROP TABLE IF EXISTS `subject_label`;
CREATE TABLE `subject_label` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `label_name` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '标签分类',
  `sort_num` int NULL DEFAULT NULL COMMENT '排序',
  `category_id` bigint NULL DEFAULT NULL COMMENT '分类id',
  `created_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '创建人',
  `created_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '更新人',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `is_deleted` int NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 100 COMMENT = '题目标签表' ROW_FORMAT = Dynamic;

DROP TABLE IF EXISTS `subject_liked`;
CREATE TABLE `subject_liked` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `subject_id` bigint NULL DEFAULT NULL COMMENT '题目id',
  `like_user_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '点赞人id',
  `status` int NULL DEFAULT NULL COMMENT '点赞状态 1点赞 0不点赞',
  `created_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '创建人',
  `created_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '修改人',
  `update_time` datetime NULL DEFAULT NULL COMMENT '修改时间',
  `is_deleted` int NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uniq_like`(`subject_id` ASC, `like_user_id` ASC) USING BTREE COMMENT '点赞唯一索引'
) ENGINE = InnoDB AUTO_INCREMENT = 100 COMMENT = '题目点赞表' ROW_FORMAT = Dynamic;

DROP TABLE IF EXISTS `subject_mapping`;
CREATE TABLE `subject_mapping` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `subject_id` bigint NULL DEFAULT NULL COMMENT '题目id',
  `category_id` bigint NULL DEFAULT NULL COMMENT '分类id',
  `label_id` bigint NULL DEFAULT NULL COMMENT '标签id',
  `created_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '创建人',
  `created_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '修改人',
  `update_time` datetime NULL DEFAULT NULL COMMENT '修改时间',
  `is_deleted` int NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_subject_id`(`subject_id` ASC) USING BTREE,
  INDEX `idx_category_id`(`category_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 100 COMMENT = '题目分类关系表' ROW_FORMAT = Dynamic;

DROP TABLE IF EXISTS `subject_multiple`;
CREATE TABLE `subject_multiple` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `subject_id` bigint NULL DEFAULT NULL COMMENT '题目id',
  `option_type` bigint NULL DEFAULT NULL COMMENT '选项类型',
  `option_content` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '选项内容',
  `is_correct` tinyint NULL DEFAULT NULL COMMENT '是否正确',
  `created_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '创建人',
  `created_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '更新人',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  `is_deleted` int NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_subject_id`(`subject_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 100 COMMENT = '多选题信息表' ROW_FORMAT = Dynamic;

DROP TABLE IF EXISTS `subject_radio`;
CREATE TABLE `subject_radio` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `subject_id` bigint NULL DEFAULT NULL COMMENT '题目id',
  `option_type` tinyint NULL DEFAULT NULL COMMENT 'a,b,c,d',
  `option_content` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '选项内容',
  `is_correct` tinyint NULL DEFAULT NULL COMMENT '是否正确',
  `created_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '创建人',
  `created_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '修改人',
  `update_time` datetime NULL DEFAULT NULL COMMENT '修改时间',
  `is_deleted` int NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_subject_id`(`subject_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 100 COMMENT = '单选题信息表' ROW_FORMAT = Dynamic;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- 二、种子数据（语义化占位，规则 8；测试密码统一 123456 → BCrypt）
-- ============================================================

-- ------------------------------------------------------------
-- auth_role（角色）
-- ------------------------------------------------------------
INSERT INTO `auth_role` (`id`, `role_name`, `role_key`, `created_by`, `created_time`, `is_deleted`) VALUES
(1, '管理员', 'admin_user', 'system', NOW(), 0),
(2, '普通用户', 'user', 'system', NOW(), 0);

-- ------------------------------------------------------------
-- auth_permission（菜单/操作权限）
-- ------------------------------------------------------------
INSERT INTO `auth_permission` (`id`, `name`, `parent_id`, `type`, `menu_url`, `status`, `show`, `icon`, `permission_key`, `created_by`, `created_time`, `is_deleted`) VALUES
(1, '仪表盘', -1, 0, '/dashboard', 0, 0, 'Odometer', 'dashboard:view', 'system', NOW(), 0),
(2, '题库管理', -1, 0, '/subject', 0, 0, 'Notebook', 'subject:manage', 'system', NOW(), 0),
(3, '分类管理', 2, 0, '/subject/category', 0, 0, 'Folder', 'subject:category:view', 'system', NOW(), 0),
(4, '标签管理', 2, 0, '/subject/label', 0, 0, 'PriceTag', 'subject:label:view', 'system', NOW(), 0),
(5, '题目列表', 2, 0, '/subject/list', 0, 0, 'Document', 'subject:list:view', 'system', NOW(), 0),
(6, '用户管理', -1, 0, '/user/manage', 0, 0, 'User', 'user:manage:view', 'system', NOW(), 0),
(7, '角色管理', -1, 0, '/role/manage', 0, 0, 'Avatar', 'role:manage:view', 'system', NOW(), 0),
(8, '权限管理', -1, 0, '/permission/manage', 0, 0, 'Key', 'permission:manage:view', 'system', NOW(), 0),
(9, '圈子管理', -1, 0, '/circle', 0, 0, 'ChatDotRound', 'circle:manage:view', 'system', NOW(), 0),
(10, '敏感词管理', -1, 0, '/sensitive', 0, 0, 'Warning', 'sensitive:manage:view', 'system', NOW(), 0),
(11, '面试管理', -1, 0, '/interview', 0, 0, 'Microphone', 'interview:manage:view', 'system', NOW(), 0),
(12, '面试词库', 11, 0, '/interview-keyword', 0, 0, 'Collection', 'interview:keyword:view', 'system', NOW(), 0),
(13, '题目新增', 5, 1, NULL, 0, 1, NULL, 'subject:add', 'system', NOW(), 0),
(14, '题目编辑', 5, 1, NULL, 0, 1, NULL, 'subject:edit', 'system', NOW(), 0),
(15, '题目删除', 5, 1, NULL, 0, 1, NULL, 'subject:delete', 'system', NOW(), 0),
(16, '敏感词新增', 10, 1, NULL, 0, 1, NULL, 'sensitive:add', 'system', NOW(), 0),
(17, '敏感词删除', 10, 1, NULL, 0, 1, NULL, 'sensitive:delete', 'system', NOW(), 0),
(18, '词库新增', 12, 1, NULL, 0, 1, NULL, 'interview:keyword:add', 'system', NOW(), 0),
(19, '词库删除', 12, 1, NULL, 0, 1, NULL, 'interview:keyword:delete', 'system', NOW(), 0),
(20, '用户编辑', 6, 1, NULL, 0, 1, NULL, 'user:edit', 'system', NOW(), 0);

-- ------------------------------------------------------------
-- auth_role_permission（角色权限：admin 全量；普通用户基础浏览）
-- ------------------------------------------------------------
INSERT INTO `auth_role_permission` (`role_id`, `permission_id`, `created_by`, `created_time`, `is_deleted`) VALUES
(1, 1, 'system', NOW(), 0), (1, 2, 'system', NOW(), 0), (1, 3, 'system', NOW(), 0), (1, 4, 'system', NOW(), 0),
(1, 5, 'system', NOW(), 0), (1, 6, 'system', NOW(), 0), (1, 7, 'system', NOW(), 0), (1, 8, 'system', NOW(), 0),
(1, 9, 'system', NOW(), 0), (1, 10, 'system', NOW(), 0), (1, 11, 'system', NOW(), 0), (1, 12, 'system', NOW(), 0),
(1, 13, 'system', NOW(), 0), (1, 14, 'system', NOW(), 0), (1, 15, 'system', NOW(), 0), (1, 16, 'system', NOW(), 0),
(1, 17, 'system', NOW(), 0), (1, 18, 'system', NOW(), 0), (1, 19, 'system', NOW(), 0), (1, 20, 'system', NOW(), 0),
(2, 1, 'system', NOW(), 0), (2, 2, 'system', NOW(), 0), (2, 3, 'system', NOW(), 0), (2, 4, 'system', NOW(), 0),
(2, 5, 'system', NOW(), 0), (2, 9, 'system', NOW(), 0), (2, 11, 'system', NOW(), 0);

-- ------------------------------------------------------------
-- auth_user（测试账号：admin/test01~test04，密码 123456，BCrypt 哈希）
-- ------------------------------------------------------------
INSERT INTO `auth_user` (`id`, `user_name`, `nick_name`, `email`, `phone`, `password`, `sex`, `avatar`, `status`, `introduce`, `ext_json`, `created_by`, `created_time`, `is_deleted`) VALUES
(1, 'admin', '系统管理员', 'admin@example.com', '13800000001', '$2a$10$RnrjjuXTYfnzb.uXETp0Juu/u.EV547TArFj8k07x97dL1DQ4uCQO', 1, 'https://cdn.example.com/avatar/admin.png', 0, '平台管理员账号', NULL, 'system', NOW(), 0),
(2, 'test01', '测试用户一', 'test01@example.com', '13800000002', '$2a$10$RnrjjuXTYfnzb.uXETp0Juu/u.EV547TArFj8k07x97dL1DQ4uCQO', 0, 'https://cdn.example.com/avatar/1.png', 0, '测试账号一', NULL, 'system', NOW(), 0),
(3, 'test02', '测试用户二', 'test02@example.com', '13800000003', '$2a$10$RnrjjuXTYfnzb.uXETp0Juu/u.EV547TArFj8k07x97dL1DQ4uCQO', 1, 'https://cdn.example.com/avatar/2.png', 0, '测试账号二', NULL, 'system', NOW(), 0),
(4, 'test03', '测试用户三', 'test03@example.com', '13800000004', '$2a$10$RnrjjuXTYfnzb.uXETp0Juu/u.EV547TArFj8k07x97dL1DQ4uCQO', 0, 'https://cdn.example.com/avatar/3.png', 0, '测试账号三', NULL, 'system', NOW(), 0),
(5, 'test04', '测试用户四', 'test04@example.com', '13800000005', '$2a$10$RnrjjuXTYfnzb.uXETp0Juu/u.EV547TArFj8k07x97dL1DQ4uCQO', 1, 'https://cdn.example.com/avatar/4.png', 0, '测试账号四', NULL, 'system', NOW(), 0);

-- ------------------------------------------------------------
-- auth_user_role（用户角色）
-- ------------------------------------------------------------
INSERT INTO `auth_user_role` (`user_id`, `role_id`, `created_by`, `created_time`, `is_deleted`) VALUES
(1, 1, 'system', NOW(), 0),
(2, 2, 'system', NOW(), 0), (3, 2, 'system', NOW(), 0), (4, 2, 'system', NOW(), 0), (5, 2, 'system', NOW(), 0);

-- ------------------------------------------------------------
-- subject_category（分类：5 大类 + 15 子类）
-- ------------------------------------------------------------
INSERT INTO `subject_category` (`id`, `category_name`, `category_type`, `image_url`, `parent_id`, `sort`, `created_by`, `created_time`, `is_deleted`) VALUES
(1, 'Java', 1, 'https://cdn.example.com/icons/java.png', -1, 1, 'system', NOW(), 0),
(2, '前端', 1, 'https://cdn.example.com/icons/vue.png', -1, 2, 'system', NOW(), 0),
(3, '数据库', 1, 'https://cdn.example.com/icons/db.png', -1, 3, 'system', NOW(), 0),
(4, '中间件', 1, 'https://cdn.example.com/icons/mq.png', -1, 4, 'system', NOW(), 0),
(5, '算法', 1, 'https://cdn.example.com/icons/algo.png', -1, 5, 'system', NOW(), 0),
(6, 'JVM', 2, NULL, 1, 1, 'system', NOW(), 0),
(7, '集合', 2, NULL, 1, 2, 'system', NOW(), 0),
(8, '并发', 2, NULL, 1, 3, 'system', NOW(), 0),
(9, 'Spring', 2, NULL, 1, 4, 'system', NOW(), 0),
(10, 'Vue', 2, NULL, 2, 1, 'system', NOW(), 0),
(11, 'JavaScript', 2, NULL, 2, 2, 'system', NOW(), 0),
(12, 'HTML/CSS', 2, NULL, 2, 3, 'system', NOW(), 0),
(13, 'MySQL', 2, NULL, 3, 1, 'system', NOW(), 0),
(14, 'Redis', 2, NULL, 3, 2, 'system', NOW(), 0),
(15, '消息队列', 2, NULL, 4, 1, 'system', NOW(), 0),
(16, '网关', 2, NULL, 4, 2, 'system', NOW(), 0),
(17, '注册中心', 2, NULL, 4, 3, 'system', NOW(), 0),
(18, '数据结构', 2, NULL, 5, 1, 'system', NOW(), 0),
(19, '算法题', 2, NULL, 5, 2, 'system', NOW(), 0),
(20, '设计模式', 2, NULL, 5, 3, 'system', NOW(), 0);

-- ------------------------------------------------------------
-- subject_label（标签 30）
-- ------------------------------------------------------------
INSERT INTO `subject_label` (`id`, `label_name`, `sort_num`, `category_id`, `created_by`, `created_time`, `is_deleted`) VALUES
(1, '内存模型', 1, 6, 'system', NOW(), 0), (2, '垃圾回收', 2, 6, 'system', NOW(), 0),
(3, 'HashMap', 1, 7, 'system', NOW(), 0), (4, 'ArrayList', 2, 7, 'system', NOW(), 0),
(5, '线程安全', 1, 8, 'system', NOW(), 0), (6, '锁', 2, 8, 'system', NOW(), 0),
(7, 'IOC', 1, 9, 'system', NOW(), 0), (8, 'AOP', 2, 9, 'system', NOW(), 0),
(9, '组件通信', 1, 10, 'system', NOW(), 0), (10, '响应式', 2, 10, 'system', NOW(), 0),
(11, 'ES6', 1, 11, 'system', NOW(), 0), (12, '异步', 2, 11, 'system', NOW(), 0),
(13, '布局', 1, 12, 'system', NOW(), 0), (14, '盒模型', 2, 12, 'system', NOW(), 0),
(15, '索引', 1, 13, 'system', NOW(), 0), (16, '事务', 2, 13, 'system', NOW(), 0),
(17, '缓存策略', 1, 14, 'system', NOW(), 0), (18, '持久化', 2, 14, 'system', NOW(), 0),
(19, 'Kafka', 1, 15, 'system', NOW(), 0), (20, 'RocketMQ', 2, 15, 'system', NOW(), 0),
(21, '路由', 1, 16, 'system', NOW(), 0), (22, '限流', 2, 16, 'system', NOW(), 0),
(23, 'Nacos', 1, 17, 'system', NOW(), 0), (24, '服务发现', 2, 17, 'system', NOW(), 0),
(25, '链表', 1, 18, 'system', NOW(), 0), (26, '树', 2, 18, 'system', NOW(), 0),
(27, '排序', 1, 19, 'system', NOW(), 0), (28, '动态规划', 2, 19, 'system', NOW(), 0),
(29, '单例', 1, 20, 'system', NOW(), 0), (30, '工厂', 2, 20, 'system', NOW(), 0);

-- ------------------------------------------------------------
-- subject_info（题目 100：单选 1-30 / 多选 31-50 / 判断 51-70 / 简答 71-100）
-- ------------------------------------------------------------
INSERT INTO `subject_info` (`id`, `subject_name`, `subject_difficult`, `settle_name`, `subject_type`, `subject_score`, `subject_parse`, `created_by`, `created_time`, `is_deleted`) VALUES
(1, 'Java 中 JVM 内存区域不包括以下哪个？', 1, '出题人', 1, 5, '示例解析：程序计数器/堆/栈/方法区均为 JVM 内存区域。', 'system', NOW(), 0),
(2, '下列哪个是 Java 的包装类型？', 1, '出题人', 1, 5, '示例解析：Integer 为 int 的包装类型。', 'system', NOW(), 0),
(3, 'String 与 StringBuilder 的区别是？', 2, '出题人', 1, 5, '示例解析：String 不可变，StringBuilder 可变。', 'system', NOW(), 0),
(4, 'Java 中接口可以包含以下哪项？', 1, '出题人', 1, 5, '示例解析：接口可含默认方法与静态方法。', 'system', NOW(), 0),
(5, '下列哪个集合基于哈希实现？', 1, '出题人', 1, 5, '示例解析：HashMap 基于哈希表。', 'system', NOW(), 0),
(6, 'HashMap 默认初始容量是？', 1, '出题人', 1, 5, '示例解析：默认 16。', 'system', NOW(), 0),
(7, '下列哪个关键字用于线程同步？', 1, '出题人', 1, 5, '示例解析：synchronized。', 'system', NOW(), 0),
(8, 'volatile 关键字的作用是？', 2, '出题人', 1, 5, '示例解析：保证可见性与有序性，不保证原子性。', 'system', NOW(), 0),
(9, 'Spring IOC 容器管理的对象称为？', 1, '出题人', 1, 5, '示例解析：Bean。', 'system', NOW(), 0),
(10, 'Spring AOP 的核心概念不包括？', 2, '出题人', 1, 5, '示例解析：切点/通知/切面为 AOP 核心概念。', 'system', NOW(), 0),
(11, 'Vue 中用于组件间传值的选项是？', 1, '出题人', 1, 5, '示例解析：props/emit。', 'system', NOW(), 0),
(12, 'Vue 响应式原理依赖的技术是？', 2, '出题人', 1, 5, '示例解析：Vue3 使用 Proxy。', 'system', NOW(), 0),
(13, 'JavaScript 中 typeof null 的结果是？', 2, '出题人', 1, 5, '示例解析：object。', 'system', NOW(), 0),
(14, '下列哪个是 ES6 新增特性？', 1, '出题人', 1, 5, '示例解析：箭头函数为 ES6 特性。', 'system', NOW(), 0),
(15, 'CSS 中用于水平居中的属性是？', 1, '出题人', 1, 5, '示例解析：text-align/margin auto/flex 等。', 'system', NOW(), 0),
(16, 'MySQL 默认存储引擎是？', 1, '出题人', 1, 5, '示例解析：InnoDB。', 'system', NOW(), 0),
(17, '下列哪个 SQL 语句用于去重？', 1, '出题人', 1, 5, '示例解析：SELECT DISTINCT。', 'system', NOW(), 0),
(18, 'MySQL 索引失效的场景是？', 2, '出题人', 1, 5, '示例解析：函数运算/隐式类型转换等。', 'system', NOW(), 0),
(19, 'Redis 中 String 类型最大存储容量是？', 1, '出题人', 1, 5, '示例解析：512MB。', 'system', NOW(), 0),
(20, 'Redis 过期策略默认是？', 2, '出题人', 1, 5, '示例解析：惰性删除 + 定期删除。', 'system', NOW(), 0),
(21, '消息队列的主要作用不包括？', 1, '出题人', 1, 5, '示例解析：MQ 用于解耦/削峰/异步。', 'system', NOW(), 0),
(22, 'Kafka 中消息的基本单位是？', 1, '出题人', 1, 5, '示例解析：Record。', 'system', NOW(), 0),
(23, '网关的常见功能不包括？', 1, '出题人', 1, 5, '示例解析：网关含路由/鉴权/限流等。', 'system', NOW(), 0),
(24, 'Nacos 的主要职责是？', 1, '出题人', 1, 5, '示例解析：服务注册发现与配置中心。', 'system', NOW(), 0),
(25, '下列哪个是线性数据结构？', 1, '出题人', 1, 5, '示例解析：数组/链表为线性结构。', 'system', NOW(), 0),
(26, '二分查找的前提条件是？', 1, '出题人', 1, 5, '示例解析：有序数组。', 'system', NOW(), 0),
(27, '快速排序的平均时间复杂度是？', 1, '出题人', 1, 5, '示例解析：O(n log n)。', 'system', NOW(), 0),
(28, '单例模式的核心思想是？', 1, '出题人', 1, 5, '示例解析：保证一个类只有一个实例。', 'system', NOW(), 0),
(29, '工厂模式的主要作用是？', 1, '出题人', 1, 5, '示例解析：封装对象创建过程。', 'system', NOW(), 0),
(30, 'Java 中 equals 与 == 的区别是？', 2, '出题人', 1, 5, '示例解析：== 比引用，equals 比内容（可重写）。', 'system', NOW(), 0),
(31, 'JVM 内存区域包括哪些？', 2, '出题人', 2, 10, '示例解析：堆/栈/方法区/程序计数器等。', 'system', NOW(), 0),
(32, 'Java 中线程安全的集合有哪些？', 2, '出题人', 2, 10, '示例解析：ConcurrentHashMap/CopyOnWriteArrayList 等。', 'system', NOW(), 0),
(33, 'HashMap 在 JDK8 中引入的优化有哪些？', 2, '出题人', 2, 10, '示例解析：红黑树/尾插法。', 'system', NOW(), 0),
(34, 'Spring 中 Bean 的作用域有哪些？', 1, '出题人', 2, 10, '示例解析：singleton/prototype/request/session。', 'system', NOW(), 0),
(35, 'Spring AOP 通知类型有哪些？', 1, '出题人', 2, 10, '示例解析：前置/后置/环绕/异常等。', 'system', NOW(), 0),
(36, 'Vue 生命周期钩子有哪些？', 1, '出题人', 2, 10, '示例解析：created/mounted/updated 等。', 'system', NOW(), 0),
(37, 'JavaScript 中数组去重方法有哪些？', 1, '出题人', 2, 10, '示例解析：Set/Map/filter。', 'system', NOW(), 0),
(38, 'CSS 盒模型包含哪些部分？', 1, '出题人', 2, 10, '示例解析：content/padding/border/margin。', 'system', NOW(), 0),
(39, 'MySQL 索引类型有哪些？', 1, '出题人', 2, 10, '示例解析：B+树/哈希/全文等。', 'system', NOW(), 0),
(40, 'Redis 数据类型有哪些？', 1, '出题人', 2, 10, '示例解析：String/Hash/List/Set/ZSet。', 'system', NOW(), 0),
(41, 'Redis 持久化方式有哪些？', 1, '出题人', 2, 10, '示例解析：RDB/AOF。', 'system', NOW(), 0),
(42, '消息中间件的选型考虑有哪些？', 2, '出题人', 2, 10, '示例解析：吞吐/可靠性/顺序性等。', 'system', NOW(), 0),
(43, '网关统一处理的功能有哪些？', 1, '出题人', 2, 10, '示例解析：鉴权/限流/路由/日志。', 'system', NOW(), 0),
(44, '微服务注册中心的能力有哪些？', 1, '出题人', 2, 10, '示例解析：注册/发现/配置/健康检查。', 'system', NOW(), 0),
(45, '常见排序算法有哪些？', 1, '出题人', 2, 10, '示例解析：冒泡/快排/归并等。', 'system', NOW(), 0),
(46, '设计模式分为哪几类？', 1, '出题人', 2, 10, '示例解析：创建型/结构型/行为型。', 'system', NOW(), 0),
(47, 'Java 集合框架的核心接口有哪些？', 1, '出题人', 2, 10, '示例解析：Collection/Map/List/Set。', 'system', NOW(), 0),
(48, 'MySQL 事务隔离级别有哪些？', 2, '出题人', 2, 10, '示例解析：读未提交/读已提交/可重复读/串行化。', 'system', NOW(), 0),
(49, 'HTTP 常用状态码有哪些？', 1, '出题人', 2, 10, '示例解析：200/400/401/403/404/500。', 'system', NOW(), 0),
(50, '前端性能优化手段有哪些？', 1, '出题人', 2, 10, '示例解析：懒加载/缓存/压缩等。', 'system', NOW(), 0),
(51, 'Java 中 String 是可变类型。（）', 1, '出题人', 3, 5, '示例解析：String 不可变。', 'system', NOW(), 0),
(52, 'HashMap 线程不安全。（）', 1, '出题人', 3, 5, '示例解析：正确。', 'system', NOW(), 0),
(53, 'volatile 关键字保证原子性。（）', 2, '出题人', 3, 5, '示例解析：volatile 不保证原子性。', 'system', NOW(), 0),
(54, 'Spring 默认 Bean 作用域是单例。（）', 1, '出题人', 3, 5, '示例解析：正确。', 'system', NOW(), 0),
(55, 'AOP 可以用于日志记录。（）', 1, '出题人', 3, 5, '示例解析：正确。', 'system', NOW(), 0),
(56, 'Vue 3 使用 Proxy 实现响应式。（）', 1, '出题人', 3, 5, '示例解析：正确。', 'system', NOW(), 0),
(57, 'JavaScript 是单线程语言。（）', 1, '出题人', 3, 5, '示例解析：正确。', 'system', NOW(), 0),
(58, 'MySQL InnoDB 支持事务。（）', 1, '出题人', 3, 5, '示例解析：正确。', 'system', NOW(), 0),
(59, 'Redis 是单线程处理命令。（）', 1, '出题人', 3, 5, '示例解析：正确（命令执行）。', 'system', NOW(), 0),
(60, '消息队列可以削峰填谷。（）', 1, '出题人', 3, 5, '示例解析：正确。', 'system', NOW(), 0),
(61, '网关可以做统一鉴权。（）', 1, '出题人', 3, 5, '示例解析：正确。', 'system', NOW(), 0),
(62, 'Nacos 只能作为注册中心。（）', 1, '出题人', 3, 5, '示例解析：Nacos 兼配置中心。', 'system', NOW(), 0),
(63, '二分查找需要数组有序。（）', 1, '出题人', 3, 5, '示例解析：正确。', 'system', NOW(), 0),
(64, '栈是先进先出结构。（）', 1, '出题人', 3, 5, '示例解析：栈是后进先出。', 'system', NOW(), 0),
(65, '快速排序是不稳定排序。（）', 2, '出题人', 3, 5, '示例解析：正确。', 'system', NOW(), 0),
(66, '单例模式可以延迟初始化。（）', 1, '出题人', 3, 5, '示例解析：懒汉式可延迟。', 'system', NOW(), 0),
(67, '工厂模式隐藏对象创建细节。（）', 1, '出题人', 3, 5, '示例解析：正确。', 'system', NOW(), 0),
(68, 'HTTP 200 表示请求成功。（）', 1, '出题人', 3, 5, '示例解析：正确。', 'system', NOW(), 0),
(69, 'cookie 存储在客户端。（）', 1, '出题人', 3, 5, '示例解析：正确。', 'system', NOW(), 0),
(70, 'session 存储在服务端。（）', 1, '出题人', 3, 5, '示例解析：正确。', 'system', NOW(), 0),
(71, '简述 JVM 内存区域划分。', 2, '出题人', 4, 10, '示例答案：程序计数器/虚拟机栈/本地方法栈/堆/方法区（含运行时常量池）。', 'system', NOW(), 0),
(72, '简述 GC 垃圾回收过程。', 2, '出题人', 4, 10, '示例答案：标记-清除/复制/标记-整理；分代收集。', 'system', NOW(), 0),
(73, '简述 HashMap 底层实现。', 2, '出题人', 4, 10, '示例答案：数组+链表+红黑树；哈希定位。', 'system', NOW(), 0),
(74, '简述 ConcurrentHashMap 线程安全实现。', 2, '出题人', 4, 10, '示例答案：CAS+synchronized 锁桶。', 'system', NOW(), 0),
(75, '简述 volatile 与 synchronized 的区别。', 2, '出题人', 4, 10, '示例答案：volatile 可见性/有序性，synchronized 原子性+互斥。', 'system', NOW(), 0),
(76, '简述线程池核心参数。', 2, '出题人', 4, 10, '示例答案：核心/最大线程数、队列、拒绝策略等。', 'system', NOW(), 0),
(77, '简述 Spring IOC 思想。', 2, '出题人', 4, 10, '示例答案：控制反转，容器管理对象生命周期与依赖。', 'system', NOW(), 0),
(78, '简述 Spring AOP 实现原理。', 2, '出题人', 4, 10, '示例答案：动态代理（JDK/CGLIB）。', 'system', NOW(), 0),
(79, '简述 Spring Boot 自动配置原理。', 2, '出题人', 4, 10, '示例答案：@EnableAutoConfiguration + 条件装配。', 'system', NOW(), 0),
(80, '简述 Vue 组件通信方式。', 2, '出题人', 4, 10, '示例答案：props/emit/Provide/inject/pinia。', 'system', NOW(), 0),
(81, '简述 Vue 响应式原理。', 2, '出题人', 4, 10, '示例答案：Vue3 Proxy 拦截 + 依赖收集。', 'system', NOW(), 0),
(82, '简述 JavaScript 事件循环。', 2, '出题人', 4, 10, '示例答案：宏任务/微任务队列调度。', 'system', NOW(), 0),
(83, '简述闭包及作用。', 2, '出题人', 4, 10, '示例答案：函数捕获外部变量；封装/缓存。', 'system', NOW(), 0),
(84, '简述 CSS 定位方式。', 1, '出题人', 4, 10, '示例答案：static/relative/absolute/fixed/sticky。', 'system', NOW(), 0),
(85, '简述 MySQL 索引原理。', 2, '出题人', 4, 10, '示例答案：B+树结构，减少磁盘 IO。', 'system', NOW(), 0),
(86, '简述 MySQL 事务隔离级别。', 2, '出题人', 4, 10, '示例答案：读未提交/读已提交/可重复读/串行化。', 'system', NOW(), 0),
(87, '简述 Redis 缓存穿透与击穿。', 2, '出题人', 4, 10, '示例答案：穿透=查不存在；击穿=热点失效。', 'system', NOW(), 0),
(88, '简述 Redis 持久化 RDB/AOF。', 2, '出题人', 4, 10, '示例答案：RDB 快照/AOF 追加日志。', 'system', NOW(), 0),
(89, '简述消息队列应用场景。', 1, '出题人', 4, 10, '示例答案：解耦/异步/削峰。', 'system', NOW(), 0),
(90, '简述 Kafka 分区机制。', 2, '出题人', 4, 10, '示例答案：分区并行、副本冗余、offset 管理。', 'system', NOW(), 0),
(91, '简述网关路由与过滤器。', 2, '出题人', 4, 10, '示例答案：路由匹配转发，过滤器链处理请求。', 'system', NOW(), 0),
(92, '简述 Nacos 服务注册与发现。', 1, '出题人', 4, 10, '示例答案：服务注册到 Nacos，消费方订阅发现。', 'system', NOW(), 0),
(93, '简述负载均衡策略。', 1, '出题人', 4, 10, '示例答案：轮询/随机/加权/一致性哈希。', 'system', NOW(), 0),
(94, '简述快速排序思想。', 2, '出题人', 4, 10, '示例答案：分治，基准划分。', 'system', NOW(), 0),
(95, '简述链表反转实现。', 2, '出题人', 4, 10, '示例答案：迭代头插或递归。', 'system', NOW(), 0),
(96, '简述动态规划适用场景。', 2, '出题人', 4, 10, '示例答案：最优子结构+重叠子问题。', 'system', NOW(), 0),
(97, '简述单例模式实现方式。', 1, '出题人', 4, 10, '示例答案：饿汉/懒汉/双重检查/枚举。', 'system', NOW(), 0),
(98, '简述观察者模式。', 2, '出题人', 4, 10, '示例答案：主题订阅通知，解耦发布订阅。', 'system', NOW(), 0),
(99, '简述 HTTP 与 HTTPS 区别。', 1, '出题人', 4, 10, '示例答案：HTTPS 加密传输（TLS）。', 'system', NOW(), 0),
(100, '简述分布式事务方案。', 3, '出题人', 4, 10, '示例答案：两阶段提交/事务消息/最终一致性。', 'system', NOW(), 0);

-- ------------------------------------------------------------
-- subject_radio（单选选项 30×4=120）
-- ------------------------------------------------------------
INSERT INTO `subject_radio` (`subject_id`, `option_type`, `option_content`, `is_correct`, `created_by`, `created_time`, `is_deleted`) VALUES
(1, 0, '程序计数器', 0, 'system', NOW(), 0), (1, 1, '堆', 0, 'system', NOW(), 0), (1, 2, 'CPU 寄存器', 1, 'system', NOW(), 0), (1, 3, '方法区', 0, 'system', NOW(), 0),
(2, 0, 'Integer', 1, 'system', NOW(), 0), (2, 1, 'int', 0, 'system', NOW(), 0), (2, 2, 'String', 0, 'system', NOW(), 0), (2, 3, 'boolean', 0, 'system', NOW(), 0),
(3, 0, 'String 可变', 0, 'system', NOW(), 0), (3, 1, 'StringBuilder 可变', 1, 'system', NOW(), 0), (3, 2, '两者均不可变', 0, 'system', NOW(), 0), (3, 3, '无区别', 0, 'system', NOW(), 0),
(4, 0, '只能有抽象方法', 0, 'system', NOW(), 0), (4, 1, '默认方法与静态方法', 1, 'system', NOW(), 0), (4, 2, '可实例化', 0, 'system', NOW(), 0), (4, 3, '无方法', 0, 'system', NOW(), 0),
(5, 0, 'ArrayList', 0, 'system', NOW(), 0), (5, 1, 'LinkedList', 0, 'system', NOW(), 0), (5, 2, 'HashMap', 1, 'system', NOW(), 0), (5, 3, 'ArrayDeque', 0, 'system', NOW(), 0),
(6, 0, '8', 0, 'system', NOW(), 0), (6, 1, '16', 1, 'system', NOW(), 0), (6, 2, '32', 0, 'system', NOW(), 0), (6, 3, '64', 0, 'system', NOW(), 0),
(7, 0, 'volatile', 0, 'system', NOW(), 0), (7, 1, 'synchronized', 1, 'system', NOW(), 0), (7, 2, 'transient', 0, 'system', NOW(), 0), (7, 3, 'static', 0, 'system', NOW(), 0),
(8, 0, '保证原子性', 0, 'system', NOW(), 0), (8, 1, '保证可见性与有序性', 1, 'system', NOW(), 0), (8, 2, '保证互斥', 0, 'system', NOW(), 0), (8, 3, '无作用', 0, 'system', NOW(), 0),
(9, 0, 'Entity', 0, 'system', NOW(), 0), (9, 1, 'Bean', 1, 'system', NOW(), 0), (9, 2, 'Component', 0, 'system', NOW(), 0), (9, 3, 'Service', 0, 'system', NOW(), 0),
(10, 0, '切点', 0, 'system', NOW(), 0), (10, 1, '通知', 0, 'system', NOW(), 0), (10, 2, '切面', 0, 'system', NOW(), 0), (10, 3, '事务', 1, 'system', NOW(), 0),
(11, 0, 'props/emit', 1, 'system', NOW(), 0), (11, 1, 'css', 0, 'system', NOW(), 0), (11, 2, 'html', 0, 'system', NOW(), 0), (11, 3, 'img', 0, 'system', NOW(), 0),
(12, 0, 'Object.defineProperty', 0, 'system', NOW(), 0), (12, 1, 'Proxy', 1, 'system', NOW(), 0), (12, 2, 'Reflect', 0, 'system', NOW(), 0), (12, 3, 'Symbol', 0, 'system', NOW(), 0),
(13, 0, 'null', 0, 'system', NOW(), 0), (13, 1, 'undefined', 0, 'system', NOW(), 0), (13, 2, 'object', 1, 'system', NOW(), 0), (13, 3, 'string', 0, 'system', NOW(), 0),
(14, 0, 'var', 0, 'system', NOW(), 0), (14, 1, '箭头函数', 1, 'system', NOW(), 0), (14, 2, 'with', 0, 'system', NOW(), 0), (14, 3, 'alert', 0, 'system', NOW(), 0),
(15, 0, 'float', 0, 'system', NOW(), 0), (15, 1, 'clear', 0, 'system', NOW(), 0), (15, 2, 'flex 布局居中', 1, 'system', NOW(), 0), (15, 3, 'overflow', 0, 'system', NOW(), 0),
(16, 0, 'MyISAM', 0, 'system', NOW(), 0), (16, 1, 'InnoDB', 1, 'system', NOW(), 0), (16, 2, 'MEMORY', 0, 'system', NOW(), 0), (16, 3, 'CSV', 0, 'system', NOW(), 0),
(17, 0, 'SELECT DISTINCT', 1, 'system', NOW(), 0), (17, 1, 'SELECT ALL', 0, 'system', NOW(), 0), (17, 2, 'SELECT TOP', 0, 'system', NOW(), 0), (17, 3, 'SELECT GROUP', 0, 'system', NOW(), 0),
(18, 0, '等值查询', 0, 'system', NOW(), 0), (18, 1, '函数运算导致失效', 1, 'system', NOW(), 0), (18, 2, '前缀匹配', 0, 'system', NOW(), 0), (18, 3, '范围查询', 0, 'system', NOW(), 0),
(19, 0, '256MB', 0, 'system', NOW(), 0), (19, 1, '512MB', 1, 'system', NOW(), 0), (19, 2, '1GB', 0, 'system', NOW(), 0), (19, 3, '无限制', 0, 'system', NOW(), 0),
(20, 0, '仅定期删除', 0, 'system', NOW(), 0), (20, 1, '惰性+定期删除', 1, 'system', NOW(), 0), (20, 2, '仅惰性删除', 0, 'system', NOW(), 0), (20, 3, '不删除', 0, 'system', NOW(), 0),
(21, 0, '解耦', 0, 'system', NOW(), 0), (21, 1, '削峰', 0, 'system', NOW(), 0), (21, 2, '异步', 0, 'system', NOW(), 0), (21, 3, '存储数据', 1, 'system', NOW(), 0),
(22, 0, 'Message', 0, 'system', NOW(), 0), (22, 1, 'Record', 1, 'system', NOW(), 0), (22, 2, 'Topic', 0, 'system', NOW(), 0), (22, 3, 'Partition', 0, 'system', NOW(), 0),
(23, 0, '路由', 0, 'system', NOW(), 0), (23, 1, '鉴权', 0, 'system', NOW(), 0), (23, 2, '限流', 0, 'system', NOW(), 0), (23, 3, '数据存储', 1, 'system', NOW(), 0),
(24, 0, '服务注册发现与配置', 1, 'system', NOW(), 0), (24, 1, '消息存储', 0, 'system', NOW(), 0), (24, 2, '文件存储', 0, 'system', NOW(), 0), (24, 3, '数据计算', 0, 'system', NOW(), 0),
(25, 0, '二叉树', 0, 'system', NOW(), 0), (25, 1, '链表', 1, 'system', NOW(), 0), (25, 2, '图', 0, 'system', NOW(), 0), (25, 3, '哈希表', 0, 'system', NOW(), 0),
(26, 0, '无序数组', 0, 'system', NOW(), 0), (26, 1, '有序数组', 1, 'system', NOW(), 0), (26, 2, '链表', 0, 'system', NOW(), 0), (26, 3, '树', 0, 'system', NOW(), 0),
(27, 0, 'O(n)', 0, 'system', NOW(), 0), (27, 1, 'O(n log n)', 1, 'system', NOW(), 0), (27, 2, 'O(n²)', 0, 'system', NOW(), 0), (27, 3, 'O(log n)', 0, 'system', NOW(), 0),
(28, 0, '多实例复用', 0, 'system', NOW(), 0), (28, 1, '全局唯一实例', 1, 'system', NOW(), 0), (28, 2, '快速创建', 0, 'system', NOW(), 0), (28, 3, '并发安全', 0, 'system', NOW(), 0),
(29, 0, '封装创建过程', 1, 'system', NOW(), 0), (29, 1, '减少继承', 0, 'system', NOW(), 0), (29, 2, '缓存数据', 0, 'system', NOW(), 0), (29, 3, '实现排序', 0, 'system', NOW(), 0),
(30, 0, '== 比内容', 0, 'system', NOW(), 0), (30, 1, 'equals 比引用', 0, 'system', NOW(), 0), (30, 2, '== 比引用，equals 比内容', 1, 'system', NOW(), 0), (30, 3, '无区别', 0, 'system', NOW(), 0);

-- ------------------------------------------------------------
-- subject_multiple（多选选项 20×4=80）
-- ------------------------------------------------------------
INSERT INTO `subject_multiple` (`subject_id`, `option_type`, `option_content`, `is_correct`, `created_by`, `created_time`, `is_deleted`) VALUES
(31, 0, '堆', 1, 'system', NOW(), 0), (31, 1, '栈', 1, 'system', NOW(), 0), (31, 2, '方法区', 1, 'system', NOW(), 0), (31, 3, 'CPU 缓存', 0, 'system', NOW(), 0),
(32, 0, 'ConcurrentHashMap', 1, 'system', NOW(), 0), (32, 1, 'CopyOnWriteArrayList', 1, 'system', NOW(), 0), (32, 2, 'ArrayList', 0, 'system', NOW(), 0), (32, 3, 'HashSet', 0, 'system', NOW(), 0),
(33, 0, '红黑树', 1, 'system', NOW(), 0), (33, 1, '尾插法', 1, 'system', NOW(), 0), (33, 2, '头插法', 0, 'system', NOW(), 0), (33, 3, '分段锁', 0, 'system', NOW(), 0),
(34, 0, 'singleton', 1, 'system', NOW(), 0), (34, 1, 'prototype', 1, 'system', NOW(), 0), (34, 2, 'request', 1, 'system', NOW(), 0), (34, 3, 'final', 0, 'system', NOW(), 0),
(35, 0, '前置通知', 1, 'system', NOW(), 0), (35, 1, '环绕通知', 1, 'system', NOW(), 0), (35, 2, '异常通知', 1, 'system', NOW(), 0), (35, 3, '查询通知', 0, 'system', NOW(), 0),
(36, 0, 'created', 1, 'system', NOW(), 0), (36, 1, 'mounted', 1, 'system', NOW(), 0), (36, 2, 'updated', 1, 'system', NOW(), 0), (36, 3, 'compile', 0, 'system', NOW(), 0),
(37, 0, 'Set', 1, 'system', NOW(), 0), (37, 1, 'filter', 1, 'system', NOW(), 0), (37, 2, 'reduce', 1, 'system', NOW(), 0), (37, 3, 'alert', 0, 'system', NOW(), 0),
(38, 0, 'content', 1, 'system', NOW(), 0), (38, 1, 'padding', 1, 'system', NOW(), 0), (38, 2, 'border', 1, 'system', NOW(), 0), (38, 3, 'opacity', 0, 'system', NOW(), 0),
(39, 0, 'B+树索引', 1, 'system', NOW(), 0), (39, 1, '哈希索引', 1, 'system', NOW(), 0), (39, 2, '全文索引', 1, 'system', NOW(), 0), (39, 3, '内存索引', 0, 'system', NOW(), 0),
(40, 0, 'String', 1, 'system', NOW(), 0), (40, 1, 'Hash', 1, 'system', NOW(), 0), (40, 2, 'List', 1, 'system', NOW(), 0), (40, 3, 'File', 0, 'system', NOW(), 0),
(41, 0, 'RDB', 1, 'system', NOW(), 0), (41, 1, 'AOF', 1, 'system', NOW(), 0), (41, 2, 'MIXED', 0, 'system', NOW(), 0), (41, 3, 'WAL', 0, 'system', NOW(), 0),
(42, 0, '吞吐量', 1, 'system', NOW(), 0), (42, 1, '可靠性', 1, 'system', NOW(), 0), (42, 2, '顺序性', 1, 'system', NOW(), 0), (42, 3, '颜色', 0, 'system', NOW(), 0),
(43, 0, '鉴权', 1, 'system', NOW(), 0), (43, 1, '限流', 1, 'system', NOW(), 0), (43, 2, '日志', 1, 'system', NOW(), 0), (43, 3, '建表', 0, 'system', NOW(), 0),
(44, 0, '服务注册', 1, 'system', NOW(), 0), (44, 1, '服务发现', 1, 'system', NOW(), 0), (44, 2, '配置管理', 1, 'system', NOW(), 0), (44, 3, '对象存储', 0, 'system', NOW(), 0),
(45, 0, '冒泡排序', 1, 'system', NOW(), 0), (45, 1, '快速排序', 1, 'system', NOW(), 0), (45, 2, '归并排序', 1, 'system', NOW(), 0), (45, 3, '遍历排序', 0, 'system', NOW(), 0),
(46, 0, '创建型', 1, 'system', NOW(), 0), (46, 1, '结构型', 1, 'system', NOW(), 0), (46, 2, '行为型', 1, 'system', NOW(), 0), (46, 3, '并发型', 0, 'system', NOW(), 0),
(47, 0, 'Collection', 1, 'system', NOW(), 0), (47, 1, 'Map', 1, 'system', NOW(), 0), (47, 2, 'List', 1, 'system', NOW(), 0), (47, 3, 'Date', 0, 'system', NOW(), 0),
(48, 0, '读未提交', 1, 'system', NOW(), 0), (48, 1, '读已提交', 1, 'system', NOW(), 0), (48, 2, '可重复读', 1, 'system', NOW(), 0), (48, 3, '多版本读', 0, 'system', NOW(), 0),
(49, 0, '200', 1, 'system', NOW(), 0), (49, 1, '400', 1, 'system', NOW(), 0), (49, 2, '401', 1, 'system', NOW(), 0), (49, 3, '600', 0, 'system', NOW(), 0),
(50, 0, '懒加载', 1, 'system', NOW(), 0), (50, 1, '资源压缩', 1, 'system', NOW(), 0), (50, 2, '缓存', 1, 'system', NOW(), 0), (50, 3, '无限重绘', 0, 'system', NOW(), 0);

-- ------------------------------------------------------------
-- subject_judge（判断 20：1 对 0 错）
-- ------------------------------------------------------------
INSERT INTO `subject_judge` (`subject_id`, `is_correct`, `created_by`, `created_time`, `is_deleted`) VALUES
(51, 0, 'system', NOW(), 0), (52, 1, 'system', NOW(), 0), (53, 0, 'system', NOW(), 0), (54, 1, 'system', NOW(), 0),
(55, 1, 'system', NOW(), 0), (56, 1, 'system', NOW(), 0), (57, 1, 'system', NOW(), 0), (58, 1, 'system', NOW(), 0),
(59, 1, 'system', NOW(), 0), (60, 1, 'system', NOW(), 0), (61, 1, 'system', NOW(), 0), (62, 0, 'system', NOW(), 0),
(63, 1, 'system', NOW(), 0), (64, 0, 'system', NOW(), 0), (65, 1, 'system', NOW(), 0), (66, 1, 'system', NOW(), 0),
(67, 1, 'system', NOW(), 0), (68, 1, 'system', NOW(), 0), (69, 1, 'system', NOW(), 0), (70, 1, 'system', NOW(), 0);

-- ------------------------------------------------------------
-- subject_brief（简答 30：参考答案）
-- ------------------------------------------------------------
INSERT INTO `subject_brief` (`subject_id`, `subject_answer`, `created_by`, `created_time`, `is_deleted`) VALUES
(71, '程序计数器、虚拟机栈、本地方法栈、堆、方法区（含运行时常量池）。', 'system', NOW(), 0),
(72, '可达性分析标记，分代收集：新生代复制、老年代标记整理。', 'system', NOW(), 0),
(73, '数组加链表，JDK8 引入红黑树优化长链表；哈希定位、负载因子扩容。', 'system', NOW(), 0),
(74, 'JDK8 起 CAS + synchronized 锁单个桶，粒度更细。', 'system', NOW(), 0),
(75, 'volatile 保证可见性与有序性；synchronized 保证互斥与原子性。', 'system', NOW(), 0),
(76, '核心线程数、最大线程数、工作队列、线程工厂、拒绝策略、keepAlive。', 'system', NOW(), 0),
(77, '控制反转：容器管理 Bean 生命周期与依赖注入，对象不自行创建依赖。', 'system', NOW(), 0),
(78, '动态代理：有接口用 JDK 代理，无接口用 CGLIB 字节码增强。', 'system', NOW(), 0),
(79, '@EnableAutoConfiguration 导入自动配置类，按条件装配生效。', 'system', NOW(), 0),
(80, '父传子 props、子传父 emit、跨级 Provide/Inject、全局 Pinia。', 'system', NOW(), 0),
(81, 'Vue3 用 Proxy 拦截属性读写，收集依赖、变更派发更新。', 'system', NOW(), 0),
(82, '同步代码执行后清微任务队列，再取宏任务，循环往复。', 'system', NOW(), 0),
(83, '函数引用外层变量形成闭包，用于封装私有状态与缓存。', 'system', NOW(), 0),
(84, 'static、relative、absolute、fixed、sticky。', 'system', NOW(), 0),
(85, 'B+ 树多路平衡，叶子存数据，减少随机 IO。', 'system', NOW(), 0),
(86, '读未提交、读已提交、可重复读、串行化；MySQL 默认可重复读。', 'system', NOW(), 0),
(87, '穿透：查询不存在的数据；击穿：热点 key 过期瞬时打库。', 'system', NOW(), 0),
(88, 'RDB 定期全量快照；AOF 追加写命令，可重放恢复。', 'system', NOW(), 0),
(89, '应用解耦、异步处理、流量削峰。', 'system', NOW(), 0),
(90, 'Topic 分分区并行存储与消费，副本保证可用性，offset 记录进度。', 'system', NOW(), 0),
(91, '路由：匹配路径转发到服务；过滤器链：鉴权/限流/改写等横切处理。', 'system', NOW(), 0),
(92, '服务启动注册到 Nacos，消费方订阅获取实例列表并负载调用。', 'system', NOW(), 0),
(93, '轮询、随机、加权轮询、一致性哈希、最小连接数。', 'system', NOW(), 0),
(94, '选基准分治：小于基准与大于基准递归排序。', 'system', NOW(), 0),
(95, '迭代：逐个头插反转；或递归：反转后续再接当前节点。', 'system', NOW(), 0),
(96, '问题可分解为重叠子问题且存在最优子结构时适用。', 'system', NOW(), 0),
(97, '饿汉式、懒汉式（双重检查）、静态内部类、枚举。', 'system', NOW(), 0),
(98, '主题维护观察者列表，状态变化时通知所有观察者。', 'system', NOW(), 0),
(99, 'HTTPS 在 HTTP 之上加 TLS 加密，保证机密性与完整性。', 'system', NOW(), 0),
(100, '两阶段提交、事务消息、本地消息表最终一致性、TCC。', 'system', NOW(), 0);

-- ------------------------------------------------------------
-- subject_mapping（题目-分类-标签映射 100）
-- ------------------------------------------------------------
INSERT INTO `subject_mapping` (`subject_id`, `category_id`, `label_id`, `created_by`, `created_time`, `is_deleted`) VALUES
(1, 6, 1, 'system', NOW(), 0), (2, 6, 1, 'system', NOW(), 0), (3, 6, 2, 'system', NOW(), 0), (4, 6, 2, 'system', NOW(), 0), (5, 6, 3, 'system', NOW(), 0),
(6, 6, 3, 'system', NOW(), 0), (7, 6, 4, 'system', NOW(), 0), (8, 6, 4, 'system', NOW(), 0), (9, 8, 5, 'system', NOW(), 0), (10, 8, 5, 'system', NOW(), 0),
(11, 8, 6, 'system', NOW(), 0), (12, 8, 6, 'system', NOW(), 0), (13, 9, 7, 'system', NOW(), 0), (14, 9, 7, 'system', NOW(), 0), (15, 9, 8, 'system', NOW(), 0),
(16, 9, 8, 'system', NOW(), 0), (17, 6, 1, 'system', NOW(), 0), (18, 6, 2, 'system', NOW(), 0), (19, 7, 3, 'system', NOW(), 0), (20, 7, 4, 'system', NOW(), 0),
(21, 10, 9, 'system', NOW(), 0), (22, 10, 9, 'system', NOW(), 0), (23, 10, 10, 'system', NOW(), 0), (24, 10, 10, 'system', NOW(), 0), (25, 11, 11, 'system', NOW(), 0),
(26, 11, 11, 'system', NOW(), 0), (27, 11, 12, 'system', NOW(), 0), (28, 11, 12, 'system', NOW(), 0), (29, 12, 13, 'system', NOW(), 0), (30, 12, 13, 'system', NOW(), 0),
(31, 13, 15, 'system', NOW(), 0), (32, 13, 15, 'system', NOW(), 0), (33, 13, 16, 'system', NOW(), 0), (34, 13, 16, 'system', NOW(), 0), (35, 14, 17, 'system', NOW(), 0),
(36, 14, 17, 'system', NOW(), 0), (37, 14, 18, 'system', NOW(), 0), (38, 14, 18, 'system', NOW(), 0), (39, 13, 15, 'system', NOW(), 0), (40, 14, 17, 'system', NOW(), 0),
(41, 15, 19, 'system', NOW(), 0), (42, 15, 19, 'system', NOW(), 0), (43, 16, 21, 'system', NOW(), 0), (44, 16, 21, 'system', NOW(), 0), (45, 17, 23, 'system', NOW(), 0),
(46, 17, 23, 'system', NOW(), 0), (47, 18, 25, 'system', NOW(), 0), (48, 18, 25, 'system', NOW(), 0), (49, 19, 27, 'system', NOW(), 0), (50, 19, 27, 'system', NOW(), 0),
(51, 6, 1, 'system', NOW(), 0), (52, 7, 3, 'system', NOW(), 0), (53, 8, 5, 'system', NOW(), 0), (54, 9, 7, 'system', NOW(), 0), (55, 9, 8, 'system', NOW(), 0),
(56, 10, 10, 'system', NOW(), 0), (57, 11, 12, 'system', NOW(), 0), (58, 13, 16, 'system', NOW(), 0), (59, 14, 17, 'system', NOW(), 0), (60, 15, 19, 'system', NOW(), 0),
(61, 16, 21, 'system', NOW(), 0), (62, 17, 23, 'system', NOW(), 0), (63, 18, 26, 'system', NOW(), 0), (64, 18, 25, 'system', NOW(), 0), (65, 19, 27, 'system', NOW(), 0),
(66, 20, 29, 'system', NOW(), 0), (67, 20, 30, 'system', NOW(), 0), (68, 12, 14, 'system', NOW(), 0), (69, 12, 13, 'system', NOW(), 0), (70, 11, 12, 'system', NOW(), 0),
(71, 6, 1, 'system', NOW(), 0), (72, 6, 2, 'system', NOW(), 0), (73, 7, 3, 'system', NOW(), 0), (74, 7, 3, 'system', NOW(), 0), (75, 8, 5, 'system', NOW(), 0),
(76, 8, 6, 'system', NOW(), 0), (77, 9, 7, 'system', NOW(), 0), (78, 9, 8, 'system', NOW(), 0), (79, 9, 7, 'system', NOW(), 0), (80, 10, 9, 'system', NOW(), 0),
(81, 10, 10, 'system', NOW(), 0), (82, 11, 12, 'system', NOW(), 0), (83, 11, 12, 'system', NOW(), 0), (84, 12, 13, 'system', NOW(), 0), (85, 13, 15, 'system', NOW(), 0),
(86, 13, 16, 'system', NOW(), 0), (87, 14, 17, 'system', NOW(), 0), (88, 14, 18, 'system', NOW(), 0), (89, 15, 19, 'system', NOW(), 0), (90, 15, 20, 'system', NOW(), 0),
(91, 16, 21, 'system', NOW(), 0), (92, 17, 23, 'system', NOW(), 0), (93, 16, 22, 'system', NOW(), 0), (94, 19, 27, 'system', NOW(), 0), (95, 18, 25, 'system', NOW(), 0),
(96, 19, 28, 'system', NOW(), 0), (97, 20, 29, 'system', NOW(), 0), (98, 20, 30, 'system', NOW(), 0), (99, 16, 22, 'system', NOW(), 0), (100, 15, 20, 'system', NOW(), 0);

-- ------------------------------------------------------------
-- practice_set（预设套题 5）+ practice_set_detail（套题内容 50）
-- ------------------------------------------------------------
INSERT INTO `practice_set` (`id`, `set_name`, `set_type`, `set_heat`, `set_desc`, `primary_category_id`, `created_by`, `created_time`, `is_deleted`) VALUES
(1, 'Java 基础套题', 2, 100, 'Java 核心知识点综合套题', 1, 'system', NOW(), 0),
(2, '前端综合套题', 2, 90, '前端三件套综合', 2, 'system', NOW(), 0),
(3, '数据库套题', 2, 80, 'MySQL 与 Redis 综合', 3, 'system', NOW(), 0),
(4, '中间件套题', 2, 70, 'MQ/网关/注册中心综合', 4, 'system', NOW(), 0),
(5, '算法套题', 2, 60, '数据结构与算法', 5, 'system', NOW(), 0);

INSERT INTO `practice_set_detail` (`set_id`, `subject_id`, `subject_type`, `created_by`, `created_time`, `is_deleted`) VALUES
(1, 1, 1, 'system', NOW(), 0), (1, 2, 1, 'system', NOW(), 0), (1, 3, 1, 'system', NOW(), 0), (1, 4, 1, 'system', NOW(), 0), (1, 5, 1, 'system', NOW(), 0),
(1, 6, 1, 'system', NOW(), 0), (1, 7, 1, 'system', NOW(), 0), (1, 8, 1, 'system', NOW(), 0), (1, 9, 1, 'system', NOW(), 0), (1, 10, 1, 'system', NOW(), 0),
(2, 11, 1, 'system', NOW(), 0), (2, 12, 1, 'system', NOW(), 0), (2, 13, 1, 'system', NOW(), 0), (2, 14, 1, 'system', NOW(), 0), (2, 15, 1, 'system', NOW(), 0),
(2, 36, 2, 'system', NOW(), 0), (2, 37, 2, 'system', NOW(), 0), (2, 38, 2, 'system', NOW(), 0), (2, 56, 3, 'system', NOW(), 0), (2, 57, 3, 'system', NOW(), 0),
(3, 16, 1, 'system', NOW(), 0), (3, 17, 1, 'system', NOW(), 0), (3, 18, 1, 'system', NOW(), 0), (3, 19, 1, 'system', NOW(), 0), (3, 20, 1, 'system', NOW(), 0),
(3, 39, 2, 'system', NOW(), 0), (3, 40, 2, 'system', NOW(), 0), (3, 41, 2, 'system', NOW(), 0), (3, 58, 3, 'system', NOW(), 0), (3, 59, 3, 'system', NOW(), 0),
(4, 21, 1, 'system', NOW(), 0), (4, 22, 1, 'system', NOW(), 0), (4, 23, 1, 'system', NOW(), 0), (4, 24, 1, 'system', NOW(), 0), (4, 42, 2, 'system', NOW(), 0),
(4, 43, 2, 'system', NOW(), 0), (4, 44, 2, 'system', NOW(), 0), (4, 60, 3, 'system', NOW(), 0), (4, 61, 3, 'system', NOW(), 0), (4, 62, 3, 'system', NOW(), 0),
(5, 25, 1, 'system', NOW(), 0), (5, 26, 1, 'system', NOW(), 0), (5, 27, 1, 'system', NOW(), 0), (5, 45, 2, 'system', NOW(), 0), (5, 46, 2, 'system', NOW(), 0),
(5, 63, 3, 'system', NOW(), 0), (5, 64, 3, 'system', NOW(), 0), (5, 94, 4, 'system', NOW(), 0), (5, 95, 4, 'system', NOW(), 0), (5, 96, 4, 'system', NOW(), 0);

-- ------------------------------------------------------------
-- share_circle（圈子 15：3 大类 + 12 子圈）
-- ------------------------------------------------------------
INSERT INTO `share_circle` (`id`, `parent_id`, `circle_name`, `icon`, `created_by`, `created_time`, `is_deleted`) VALUES
(1, -1, 'Java 圈子', 'https://cdn.example.com/circle/java.png', 'system', NOW(), 0),
(2, -1, '前端圈子', 'https://cdn.example.com/circle/frontend.png', 'system', NOW(), 0),
(3, -1, '数据库圈子', 'https://cdn.example.com/circle/db.png', 'system', NOW(), 0),
(4, 1, 'JVM 圈', NULL, 'system', NOW(), 0),
(5, 1, '集合圈', NULL, 'system', NOW(), 0),
(6, 1, '并发圈', NULL, 'system', NOW(), 0),
(7, 1, 'Spring 圈', NULL, 'system', NOW(), 0),
(8, 2, 'Vue 圈', NULL, 'system', NOW(), 0),
(9, 2, 'JavaScript 圈', NULL, 'system', NOW(), 0),
(10, 2, 'HTML/CSS 圈', NULL, 'system', NOW(), 0),
(11, 3, 'MySQL 圈', NULL, 'system', NOW(), 0),
(12, 3, 'Redis 圈', NULL, 'system', NOW(), 0),
(13, 1, '消息队列圈', NULL, 'system', NOW(), 0),
(14, 1, '网关圈', NULL, 'system', NOW(), 0),
(15, 3, '算法圈', NULL, 'system', NOW(), 0);

-- ------------------------------------------------------------
-- share_moment / share_comment_reply / share_message（演示样例）
-- ------------------------------------------------------------
INSERT INTO `share_moment` (`id`, `circle_id`, `content`, `pic_urls`, `reply_count`, `created_by`, `created_time`, `is_deleted`) VALUES
(1, 4, 'JVM 内存模型学习打卡', NULL, 1, '2', NOW(), 0),
(2, 4, '垃圾回收算法分享', NULL, 0, '3', NOW(), 0),
(3, 8, 'Vue 组件通信技巧', NULL, 0, '2', NOW(), 0),
(4, 11, 'MySQL 索引优化笔记', NULL, 0, '4', NOW(), 0),
(5, 13, '消息队列选型讨论', NULL, 0, '5', NOW(), 0);

INSERT INTO `share_comment_reply` (`id`, `moment_id`, `reply_type`, `to_id`, `reply_id`, `parent_id`, `content`, `pic_urls`, `created_by`, `created_time`, `is_deleted`) VALUES
(1, 1, 1, 2, NULL, 0, '讲得很清楚，学习了', NULL, '3', NOW(), 0),
(2, 1, 2, 3, 1, 1, '同感，已收藏', NULL, '2', NOW(), 0),
(3, 1, 2, 2, 1, 1, '感谢支持', NULL, '3', NOW(), 0),
(4, 3, 1, 2, NULL, 0, '正好需要，感谢分享', NULL, '5', NOW(), 0),
(5, 4, 1, 4, NULL, 0, '索引失效的场景可以再补充', NULL, '2', NOW(), 0);

INSERT INTO `share_message` (`id`, `from_id`, `to_id`, `content`, `is_read`, `created_by`, `created_time`, `is_deleted`) VALUES
(1, '3', '2', '{"msgType":"COMMENT","msg":"评论了你的动态","targetId":1}', 1, 'system', NOW(), 0),
(2, '2', '3', '{"msgType":"COMMENT_REPLY","msg":"回复了你的评论","targetId":1}', 2, 'system', NOW(), 0),
(3, '5', '2', '{"msgType":"COMMENT","msg":"评论了你的动态","targetId":3}', 2, 'system', NOW(), 0);

-- ------------------------------------------------------------
-- sensitive_words（黑名单 10 + 白名单 5）
-- ------------------------------------------------------------
INSERT INTO `sensitive_words` (`words`, `type`, `created_time`, `is_deleted`) VALUES
('赌博', 1, NOW(), 0), ('代开发票', 1, NOW(), 0), ('博彩', 1, NOW(), 0), ('刷单', 1, NOW(), 0),
('违禁品', 1, NOW(), 0), ('诈骗', 1, NOW(), 0), ('外挂', 1, NOW(), 0), ('作弊', 1, NOW(), 0),
('代刷', 1, NOW(), 0), ('色情', 1, NOW(), 0),
('学习', 2, NOW(), 0), ('技术', 2, NOW(), 0), ('交流', 2, NOW(), 0), ('分享', 2, NOW(), 0), ('编程', 2, NOW(), 0);

-- ------------------------------------------------------------
-- interview_keyword（面试评分词库 5 类 × 10）
-- ------------------------------------------------------------
INSERT INTO `interview_keyword` (`category_id`, `keyword`, `weight`, `created_by`, `created_time`, `is_deleted`) VALUES
(6, '内存模型', 1, 'system', NOW(), 0), (6, '垃圾回收', 1, 'system', NOW(), 0), (6, '堆', 1, 'system', NOW(), 0), (6, '栈', 1, 'system', NOW(), 0),
(6, '方法区', 1, 'system', NOW(), 0), (6, '类加载', 1, 'system', NOW(), 0), (6, '可达性', 1, 'system', NOW(), 0), (6, '分代', 1, 'system', NOW(), 0),
(6, '标记', 1, 'system', NOW(), 0), (6, '复制', 1, 'system', NOW(), 0),
(7, '哈希', 1, 'system', NOW(), 0), (7, 'HashMap', 1, 'system', NOW(), 0), (7, '链表', 1, 'system', NOW(), 0), (7, '红黑树', 1, 'system', NOW(), 0),
(7, '扩容', 1, 'system', NOW(), 0), (7, '线程安全', 1, 'system', NOW(), 0), (7, '遍历', 1, 'system', NOW(), 0), (7, '并发', 1, 'system', NOW(), 0),
(7, '排序', 1, 'system', NOW(), 0), (7, '去重', 1, 'system', NOW(), 0),
(8, '线程', 1, 'system', NOW(), 0), (8, '锁', 1, 'system', NOW(), 0), (8, '同步', 1, 'system', NOW(), 0), (8, 'volatile', 1, 'system', NOW(), 0),
(8, '原子', 1, 'system', NOW(), 0), (8, '可见性', 1, 'system', NOW(), 0), (8, '线程池', 1, 'system', NOW(), 0), (8, '信号量', 1, 'system', NOW(), 0),
(8, '死锁', 1, 'system', NOW(), 0), (8, 'CAS', 1, 'system', NOW(), 0),
(9, 'IOC', 1, 'system', NOW(), 0), (9, 'AOP', 1, 'system', NOW(), 0), (9, 'Bean', 1, 'system', NOW(), 0), (9, '依赖注入', 1, 'system', NOW(), 0),
(9, '事务', 1, 'system', NOW(), 0), (9, '代理', 1, 'system', NOW(), 0), (9, '容器', 1, 'system', NOW(), 0), (9, '配置', 1, 'system', NOW(), 0),
(9, '注解', 1, 'system', NOW(), 0), (9, '拦截', 1, 'system', NOW(), 0),
(10, '组件', 1, 'system', NOW(), 0), (10, 'props', 1, 'system', NOW(), 0), (10, 'emit', 1, 'system', NOW(), 0), (10, '响应式', 1, 'system', NOW(), 0),
(10, '生命周期', 1, 'system', NOW(), 0), (10, '路由', 1, 'system', NOW(), 0), (10, '状态', 1, 'system', NOW(), 0), (10, '模板', 1, 'system', NOW(), 0),
(10, '指令', 1, 'system', NOW(), 0), (10, '插槽', 1, 'system', NOW(), 0);

-- ============================================================
-- 结束
-- ============================================================

