# 后端项目模板

## 目录结构

```
backend/
├── src/
│   ├── controllers/      # 控制器
│   ├── services/         # 业务逻辑
│   ├── repositories/     # 数据访问
│   ├── models/           # 数据模型
│   ├── middlewares/      # 中间件
│   ├── utils/            # 工具函数
│   ├── config/           # 配置
│   └── types/            # 类型定义
├── tests/
│   ├── unit/             # 单元测试
│   └── integration/      # 集成测试
├── scripts/              # 脚本
└── package.json / pom.xml / requirements.txt
```

## 技术栈建议

### Node.js
- **框架**：Express / Fastify / NestJS
- **ORM**：Prisma / TypeORM
- **验证**：Zod / Joi
- **测试**：Jest / Vitest

### Java
- **框架**：Spring Boot
- **ORM**：JPA / MyBatis
- **测试**：JUnit 5 + Mockito

### Python
- **框架**：FastAPI / Django
- **ORM**：SQLAlchemy / Django ORM
- **测试**：pytest

## 开发规范

### 控制器规范

```typescript
// controllers/user-controller.ts
import { Request, Response, NextFunction } from 'express';
import { userService } from '@/services/user-service';
import { validate } from '@/middlewares/validate';
import { userSchema } from '@/validators/user-validator';

export class UserController {
  async getUser(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const user = await userService.getUser(id);
      res.json({ success: true, data: user });
    } catch (error) {
      next(error);
    }
  }

  async createUser(req: Request, res: Response, next: NextFunction) {
    try {
      const userData = userSchema.parse(req.body);
      const user = await userService.createUser(userData);
      res.status(201).json({ success: true, data: user });
    } catch (error) {
      next(error);
    }
  }
}
```

### 服务规范

```typescript
// services/user-service.ts
import { UserRepository } from '@/repositories/user-repository';
import { hashPassword } from '@/utils/crypto';
import { ConflictError, NotFoundError } from '@/errors';

export class UserService {
  constructor(private readonly userRepo: UserRepository) {}

  async getUser(id: string): Promise<User> {
    const user = await this.userRepo.findById(id);
    if (!user) {
      throw new NotFoundError(`User not found: ${id}`);
    }
    return user;
  }

  async createUser(data: CreateUserDTO): Promise<User> {
    const existingUser = await this.userRepo.findByEmail(data.email);
    if (existingUser) {
      throw new ConflictError(`User already exists: ${data.email}`);
    }

    const hashedPassword = await hashPassword(data.password);
    return this.userRepo.create({
      ...data,
      password: hashedPassword,
    });
  }
}
```

### 测试规范

```typescript
// tests/unit/user-service.test.ts
import { UserService } from '@/services/user-service';
import { UserRepository } from '@/repositories/user-repository';
import { NotFoundError, ConflictError } from '@/errors';

describe('UserService', () => {
  let service: UserService;
  let mockRepo: jest.Mocked<UserRepository>;

  beforeEach(() => {
    mockRepo = {
      findById: jest.fn(),
      findByEmail: jest.fn(),
      create: jest.fn(),
    };
    service = new UserService(mockRepo);
  });

  describe('getUser', () => {
    it('should return user when found', async () => {
      const mockUser = { id: '1', email: 'test@example.com' };
      mockRepo.findById.mockResolvedValue(mockUser);

      const result = await service.getUser('1');

      expect(result).toEqual(mockUser);
      expect(mockRepo.findById).toHaveBeenCalledWith('1');
    });

    it('should throw NotFoundError when user not found', async () => {
      mockRepo.findById.mockResolvedValue(null);

      await expect(service.getUser('999')).rejects.toThrow(NotFoundError);
    });
  });
});
```

### API 响应格式

```typescript
// 成功响应
{
  "success": true,
  "data": { ... },
  "message": "操作成功"
}

// 分页响应
{
  "success": true,
  "data": [...],
  "pagination": {
    "page": 1,
    "pageSize": 20,
    "total": 100,
    "totalPages": 5
  }
}

// 错误响应
{
  "success": false,
  "error": {
    "code": "USER_NOT_FOUND",
    "message": "用户不存在"
  }
}
```
