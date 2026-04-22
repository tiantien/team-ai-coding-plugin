# 前端项目模板

## 目录结构

```
frontend/
├── src/
│   ├── components/       # 组件目录
│   ├── hooks/            # 自定义 Hooks
│   ├── services/         # API 服务
│   ├── stores/           # 状态管理
│   ├── utils/            # 工具函数
│   ├── styles/           # 样式文件
│   └── types/            # 类型定义
├── tests/
│   ├── unit/             # 单元测试
│   └── e2e/              # 端到端测试
├── public/               # 静态资源
└── package.json
```

## 技术栈建议

- **框架**：React / Vue / Angular
- **状态管理**：Zustand / Pinia / Redux Toolkit
- **样式**：Tailwind CSS / CSS Modules
- **测试**：Vitest + Playwright
- **构建**：Vite

## 开发规范

### 组件规范

```typescript
// 组件命名：PascalCase
// 文件命名：kebab-case

interface ButtonProps {
  variant?: 'primary' | 'secondary';
  size?: 'sm' | 'md' | 'lg';
  children: React.ReactNode;
  onClick?: () => void;
}

export function Button({ variant = 'primary', size = 'md', children, onClick }: ButtonProps) {
  return (
    <button
      className={cn(styles.button, styles[variant], styles[size])}
      onClick={onClick}
    >
      {children}
    </button>
  );
}
```

### API 服务规范

```typescript
// services/user-service.ts
class UserService {
  private readonly baseUrl = '/api/users';

  async getUser(id: string): Promise<User> {
    const response = await fetch(`${this.baseUrl}/${id}`);
    if (!response.ok) {
      throw new Error(`Failed to fetch user: ${response.statusText}`);
    }
    return response.json();
  }

  async updateUser(id: string, data: Partial<User>): Promise<User> {
    const response = await fetch(`${this.baseUrl}/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    if (!response.ok) {
      throw new Error(`Failed to update user: ${response.statusText}`);
    }
    return response.json();
  }
}

export const userService = new UserService();
```

### 测试规范

```typescript
// tests/unit/button.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import { Button } from '@/components/button';

describe('Button', () => {
  it('should render with correct text', () => {
    render(<Button>Click me</Button>);
    expect(screen.getByText('Click me')).toBeInTheDocument();
  });

  it('should call onClick when clicked', () => {
    const onClick = vi.fn();
    render(<Button onClick={onClick}>Click me</Button>);
    fireEvent.click(screen.getByText('Click me'));
    expect(onClick).toHaveBeenCalledTimes(1);
  });
});
```
