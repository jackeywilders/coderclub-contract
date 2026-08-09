# CoderClub 深入开发设计文档

> 日期：2026-07-28  
> 状态：Iteration 1 已确认

## 概述

在现有 Auth + Subject + OSS 三微服务体系上，采用「修 Bug + 加功能 + 补测试」三线并行的迭代策略。

### 总迭代规划

| 迭代 | 架构修复 | 新功能 | 测试 |
|------|---------|--------|------|
| **1** | 修复 OSS 注入 bug + DDD 违规 | 用户管理（CRUD + 角色分配） | Auth DomainService 单元测试 |
| **2** | 修复 N+1 查询 + 统一异常处理 | 数据统计报表 | Subject DomainService 单元测试 |
| **3** | 提取共享模块 + OSS 安全加固 | OSS 鉴权 + presignedURL | 集成测试 |

### 设计原则

- **最小改动半径**：每个修复只动直接相关文件，不做批量重构
- **复用现有基础设施**：新功能优先用已有的 `ResponseResult`、`BaseException`、`PageResult`、`Converter`、`@SaCheckRole` 等
- **不引入新依赖**：能用 Spring Boot 4.0.0 内置的绝不上新库

---

## Iteration 1 — 用户管理 + OSS 修复 + DDD 清理 + 基础测试

### 1.1 OSS StorageAdapter 注入修复

**问题：** `StorageConfig.storageService()` 使用 `new MinioStorageAdapter()` 创建实例，该实例不受 Spring 管理。其内部的 `@Resource MinioUtil` 和 `@Value("${minio.url}")` 均为 null，运行时必然 NPE。

**根本原因：** `StorageConfig` 作为配置工厂用 `new` 创建 adapter，绕过了 Spring 的依赖注入容器。

**修复方案：** Adapter 加 `@Component` + 构造器注入，`StorageConfig` 改按类型注入。

**改动文件：**

| 文件 | 改动 |
|------|------|
| `coder-club-oss/.../adapter/MinioStorageAdapter.java` | 加 `@Component`；`@Resource MinioUtil` 改为构造器注入；`@Value("${minio.url}")` 改为构造器参数 |
| `coder-club-oss/.../adapter/AliStorageAdapter.java` | 加 `@Component`；空壳 adapter 保留结构一致性 |
| `coder-club-oss/.../config/StorageConfig.java` | 改方法签名为参数注入两个 adapter bean；移除类级别 `@RefreshScope`（保留方法级别）；按 `storageType` 字符串匹配返回对应 adapter |

**选择原因：** 这是最标准的 Spring 惯用法。另一种方案（StorageConfig 手动调用 setter 设值）更冗长且与项目其他 Bean（使用 `@Resource` 字段注入）风格不一致。

---

### 1.2 DDD 分层违规修复

**问题：** `SubjectController` 4 处直接调用 Infra 层服务（`SubjectInfoService`），`AuthLoginController.loadRoleAndPermission()` 在 Controller 内部直接操作 Infra 实体和服务。违反项目 DDD 规范（Controller → DomainService → Infra Service）。

**修复方案：**

**SubjectController（4 处）：**

| 当前调用 | 问题 | 修复 |
|---------|------|------|
| `subjectInfoService.removeById(id)` | Controller 直调 Infra | 在 `SubjectInfoDomainService` 新增 `deleteSubjectInfo(Long id)` |
| `subjectInfoService.updateById(entity)` | Controller 直调 Infra，且接收 Entity 而非 DTO | 在 `SubjectInfoDomainService` 新增 `updateSubjectInfo(SubjectInfoBO)` |
| `subjectInfoService.list()` | Controller 直调 Infra | 在 `SubjectInfoDomainService` 新增 `listAll()` |

**AuthLoginController：**

将整个 `loadRoleAndPermission()` 方法（约 15 行）下沉到 `AuthUserDomainService`，作为 `loadRoleAndPermission(Long userId)` 方法。Controller 只调用一行 `authUserDomainService.loadRoleAndPermission(userId)`。

**改动文件：**

| 文件 | 改动 |
|------|------|
| `SubjectController.java` | `SubjectInfoService` 注入改为 `SubjectInfoDomainService`；`remove`/`update`/`list` 方法改为调 DomainService |
| `SubjectInfoDomainService.java` | 新增 `deleteSubjectInfo(Long id)`、`updateSubjectInfo(SubjectInfoBO)`、`listAll()` 三个方法签名 |
| `SubjectInfoDomainServiceImpl.java` | 实现新增的三个方法，内部委托给 Infra Service |
| `AuthLoginController.java` | 移除 `loadRoleAndPermission()` 方法体；改为调用 `authUserDomainService.loadRoleAndPermission(userId)`；移除 `AuthUserRoleService`、`AuthRoleService`、`AuthRolePermissionService` 的注入 |
| `AuthUserDomainService.java` | 新增 `void loadRoleAndPermission(Long userId)` 方法签名 |
| `AuthUserDomainServiceImpl.java` | 移植 `loadRoleAndPermission()` 逻辑 |

**选择原因：** 这恢复了项目的 DDD 分层纪律。不改变现有业务行为——只是把代码从错误的位置移到正确的位置。改动纯属重构，零功能影响。

---

### 1.3 用户管理功能

**背景：** 数据库已有 `auth_user` 表 + `auth_user_role` 关联表 + 种子角色数据（`admin_user`、`normal_user`）。`AuthUserDomainService` 已有 `register`、`update`、`getById`、`queryByUserName` 等基础方法。只需新增管理端 Controller 和对应 DomainService 方法。

**新增 Controller：`AuthUserManageController`**

| HTTP | 路径 | 功能 | 鉴权 |
|------|------|------|------|
| `POST` | `/auth/admin/user/page` | 分页查询用户列表 | `@SaCheckRole("admin_user")` |
| `GET` | `/auth/admin/user/{id}` | 查看用户详情 | `@SaCheckRole("admin_user")` |
| `PUT` | `/auth/admin/user/status` | 启用/禁用用户 | `@SaCheckRole("admin_user")` |
| `POST` | `/auth/admin/user/assign-role` | 给用户分配角色 | `@SaCheckRole("admin_user")` |

**新增 DTO：**

| DTO | 文件路径 | 字段 |
|-----|---------|------|
| `UserPageQueryDTO` | `app/entity/UserPageQueryDTO.java` | `pageNo: Integer`, `pageSize: Integer`, `userName: String`（可选，模糊搜索）, `status: Integer`（可选，筛选启用/禁用状态） |
| `UserStatusUpdateDTO` | `app/entity/UserStatusUpdateDTO.java` | `userId: Long`（`@NotNull`）, `status: Integer`（`@NotNull`，0=启用 1=禁用） |
| `UserRoleAssignDTO` | `app/entity/UserRoleAssignDTO.java` | `userId: Long`（`@NotNull`）, `roleIds: List<Long>`（`@NotNull`） |

**新增 DomainService 方法（`AuthUserDomainService`）：**

| 方法 | 说明 |
|------|------|
| `PageResult<AuthUserBO> page(UserPageQueryDTO dto)` | 分页查询；userName 非空时用 MyBatis-Flex `like()` 模糊匹配；status 非空时用 `eq()` 精确筛选 |
| `AuthUserBO detail(Long id)` | 与已有 `getById(Long)` 的区别：返回 BO 而非 Entity（遵循 DDD 分层） |
| `Boolean updateStatus(Long userId, Integer status)` | 更新 `auth_user.status` 字段；禁止禁用自己 |
| `Boolean assignRoles(Long userId, List<Long> roleIds)` | 先删掉 userId 对应的旧 `auth_user_role` 记录，再批量插入新的 |

**选择原因：**
- `@SaCheckRole("admin_user")` 直接复用种子数据中的管理员角色，零额外配置
- 分页复用 subject 已有的 `PageResult` 结构（auth 模块可在 common 中新增一份，或者暂时在 auth 模块内定义）
- `assignRoles` 用「先删后插」策略：简单可靠、无并发竞态风险（角色分配是低频操作）、比 diff 新旧角色更容易实现且不易出错
- `updateStatus` 加防呆（禁止禁用自己）避免管理员误操作把自己锁在外面

---

### 1.4 基础测试

**范围：** 仅 Auth 模块 DomainService 层的单元测试。

| 测试类 | 覆盖方法 |
|--------|---------|
| `AuthUserDomainServiceImplTest` | `register()` 正常注册 + 用户名重复抛异常；`updatePassword()` BCrypt 加密验证；`updateStatus()` 状态切换 |
| `AuthRoleDomainServiceImplTest` | `add()` 正常新增；`delete()` 正常删除；`list()` 返回包含种子数据的列表 |

**技术选型：**

| 组件 | 选型 | 原因 |
|------|------|------|
| 测试框架 | JUnit 5 | Spring Boot 4.0.0 BOM 已管理，零额外依赖 |
| Mock 框架 | Mockito | 同上，且项目已有 `spring-boot-starter-test` 的依赖路径 |
| 测试位置 | `coder-club-auth-domain/src/test/java/` | 只测 domain 层 |
| 断言 | JUnit 5 `Assertions` + Mockito `verify` | 不需要 AssertJ 等额外库 |

**新增依赖（`coder-club-auth-domain/pom.xml`）：**
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <scope>test</scope>
    <exclusions>
        <exclusion>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-logging</artifactId>
        </exclusion>
    </exclusions>
</dependency>
```

**不做什么（本迭代）：**
- 不写 Controller 层集成测试（需要 `@SpringBootTest` + 数据库实例，等 Iteration 3）
- 不写 Subject 模块测试（等 Iteration 2）
- 测试覆盖率目标：DomainService 核心方法即可，不追求数字

---

### 1.5 Iteration 1 文件清单

| 操作 | 文件 | 模块 |
|------|------|------|
| 修改 | `adapter/MinioStorageAdapter.java` | oss |
| 修改 | `adapter/AliStorageAdapter.java` | oss |
| 修改 | `config/StorageConfig.java` | oss |
| 修改 | `app/controller/SubjectController.java` | subject |
| 修改 | `domain/service/SubjectInfoDomainService.java` | subject |
| 修改 | `domain/service/impl/SubjectInfoDomainServiceImpl.java` | subject |
| 修改 | `app/controller/AuthLoginController.java` | auth |
| 修改 | `domain/service/AuthUserDomainService.java` | auth |
| 修改 | `domain/service/impl/AuthUserDomainServiceImpl.java` | auth |
| **新增** | `app/controller/AuthUserManageController.java` | auth |
| **新增** | `app/entity/UserPageQueryDTO.java` | auth |
| **新增** | `app/entity/UserStatusUpdateDTO.java` | auth |
| **新增** | `app/entity/UserRoleAssignDTO.java` | auth |
| **新增** | `common/entity/res/PageResult.java` | auth |
| 修改 | `domain/pom.xml`（加 test 依赖） | auth |
| **新增** | `domain/src/test/.../AuthUserDomainServiceImplTest.java` | auth |
| **新增** | `domain/src/test/.../AuthRoleDomainServiceImplTest.java` | auth |

---

## Iteration 2 — 数据统计 + N+1 修复 + 异常统一（概要）

*详细设计将在 Iteration 1 完成后确认。*

**数据统计报表：**

| 端点 | 功能 |
|------|------|
| `GET /subject/stats/overview` | 总题目数、按题型分布、按难度分布 |
| `GET /subject/stats/category` | 按分类统计题目数（含一级+二级汇总） |
| `GET /auth/admin/stats/users` | 用户总数、今日新增、活跃状态分布 |

**N+1 修复：**
- `SaTokenConfigure.getPermissionList()` — 改为一次查询获取所有 roleId 对应的权限（`WHERE role_id IN (...)`）
- `AuthUserDomainServiceImpl.loadRoleAndPermission()` — 同上
- `SubjectInfoDomainServiceImpl` 分页标签查询 — 批量预加载 labelId → labelName 映射

**异常统一：**
- `SubjectTypeHandlerFactory` 的 `RuntimeException` 改为 `BaseException`

**测试：**
- Subject 模块 DomainService 层单元测试

---

## Iteration 3 — 共享模块 + OSS 加固 + 集成测试（概要）

*详细设计将在 Iteration 2 完成后确认。*

**共享模块 `coder-club-common`：**
- 提取 `ResponseResult`、`BaseException`、`ResultCodeEnum` 为公共库
- Auth/Subject 改为依赖 `coder-club-common` 而非各自复制
- OSS 模块同步迁移

**OSS 安全加固：**
- `FileController` 加 `@SaCheckLogin` 保护
- 统一所有端点返回 `ResponseResult`（修复 `/getUrl` 不一致）
- `MinioUtil.getPreviewFileUrl` 接上来替代字符串拼接 URL

**集成测试：**
- Controller 层 `@SpringBootTest` + 测试数据库
- 覆盖核心链路的 happy path

---

## 验证方式

每个迭代完成后：
1. **编译：** `mvn install -DskipTests` 全模块通过
2. **测试：** `mvn test` 新增测试全部通过
3. **运行：** `start-auth.ps1` + `start-subject.ps1` 启动成功
4. **功能验证：** 运行 ApiFox 测试计划中对应新增的用例
