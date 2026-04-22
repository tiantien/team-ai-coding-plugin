# 移动端项目模板

## 目录结构

```
mobile/
├── src/
│   ├── screens/          # 页面
│   ├── components/       # 组件
│   ├── navigation/       # 导航配置
│   ├── services/         # API 服务
│   ├── stores/           # 状态管理
│   ├── hooks/            # 自定义 Hooks
│   ├── utils/            # 工具函数
│   ├── theme/            # 主题配置
│   └── types/            # 类型定义
├── assets/               # 静态资源
├── tests/
│   ├── unit/             # 单元测试
│   └── e2e/              # 端到端测试
└── package.json
```

## 技术栈建议

### React Native
- **框架**：React Native + Expo
- **导航**：React Navigation
- **状态管理**：Zustand / Redux Toolkit
- **样式**：NativeWind / StyleSheet
- **测试**：Jest + Detox

### Flutter
- **框架**：Flutter
- **状态管理**：Riverpod / Bloc
- **导航**：GoRouter
- **测试**：flutter_test + integration_test

## 开发规范

### 页面规范

```typescript
// screens/profile-screen.tsx
import { useUser } from '@/hooks/use-user';
import { ProfileHeader } from '@/components/profile-header';
import { ProfileList } from '@/components/profile-list';
import { LoadingSpinner } from '@/components/loading-spinner';
import { ErrorMessage } from '@/components/error-message';

export function ProfileScreen() {
  const { user, isLoading, error, refetch } = useUser();

  if (isLoading) {
    return <LoadingSpinner />;
  }

  if (error) {
    return <ErrorMessage error={error} onRetry={refetch} />;
  }

  return (
    <View style={styles.container}>
      <ProfileHeader user={user} />
      <ProfileList items={user.items} />
    </View>
  );
}
```

### 组件规范

```typescript
// components/button.tsx
import { Pressable, Text, StyleSheet } from 'react-native';

interface ButtonProps {
  variant?: 'primary' | 'secondary' | 'outline';
  size?: 'sm' | 'md' | 'lg';
  disabled?: boolean;
  children: string;
  onPress: () => void;
}

export function Button({
  variant = 'primary',
  size = 'md',
  disabled = false,
  children,
  onPress,
}: ButtonProps) {
  return (
    <Pressable
      style={({ pressed }) => [
        styles.base,
        styles[variant],
        styles[size],
        pressed && styles.pressed,
        disabled && styles.disabled,
      ]}
      disabled={disabled}
      onPress={onPress}
    >
      <Text style={[styles.text, styles[`${variant}Text`]]}>
        {children}
      </Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  base: {
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
  },
  primary: { backgroundColor: '#007AFF' },
  secondary: { backgroundColor: '#5856D6' },
  outline: { backgroundColor: 'transparent', borderWidth: 1, borderColor: '#007AFF' },
  sm: { paddingVertical: 8, paddingHorizontal: 16 },
  md: { paddingVertical: 12, paddingHorizontal: 24 },
  lg: { paddingVertical: 16, paddingHorizontal: 32 },
  pressed: { opacity: 0.8 },
  disabled: { opacity: 0.5 },
  text: { color: '#FFFFFF', fontWeight: '600' },
  outlineText: { color: '#007AFF' },
});
```

### API 服务规范

```typescript
// services/api-client.ts
import AsyncStorage from '@react-native-async-storage/async-storage';

class ApiClient {
  private readonly baseUrl: string;

  constructor(baseUrl: string) {
    this.baseUrl = baseUrl;
  }

  private async getHeaders(): Promise<HeadersInit> {
    const token = await AsyncStorage.getItem('auth_token');
    return {
      'Content-Type': 'application/json',
      ...(token && { Authorization: `Bearer ${token}` }),
    };
  }

  async get<T>(path: string): Promise<T> {
    const response = await fetch(`${this.baseUrl}${path}`, {
      method: 'GET',
      headers: await this.getHeaders(),
    });
    return this.handleResponse<T>(response);
  }

  async post<T>(path: string, body: unknown): Promise<T> {
    const response = await fetch(`${this.baseUrl}${path}`, {
      method: 'POST',
      headers: await this.getHeaders(),
      body: JSON.stringify(body),
    });
    return this.handleResponse<T>(response);
  }

  private async handleResponse<T>(response: Response): Promise<T> {
    if (!response.ok) {
      const error = await response.json();
      throw new ApiError(error.code, error.message, response.status);
    }
    return response.json();
  }
}

export const apiClient = new ApiClient(process.env.EXPO_PUBLIC_API_URL!);
```

### 测试规范

```typescript
// tests/unit/button.test.tsx
import { render, fireEvent } from '@testing-library/react-native';
import { Button } from '@/components/button';

describe('Button', () => {
  it('should render with correct text', () => {
    const { getByText } = render(<Button onPress={jest.fn()}>Click me</Button>);
    expect(getByText('Click me')).toBeTruthy();
  });

  it('should call onPress when pressed', () => {
    const onPress = jest.fn();
    const { getByText } = render(<Button onPress={onPress}>Click me</Button>);
    fireEvent.press(getByText('Click me'));
    expect(onPress).toHaveBeenCalledTimes(1);
  });

  it('should not call onPress when disabled', () => {
    const onPress = jest.fn();
    const { getByText } = render(
      <Button onPress={onPress} disabled>Click me</Button>
    );
    fireEvent.press(getByText('Click me'));
    expect(onPress).not.toHaveBeenCalled();
  });
});
```

## 平台适配

### iOS
- 遵循 Human Interface Guidelines
- 使用 SF Symbols 图标
- 支持动态字体大小

### Android
- 遵循 Material Design
- 使用 Material Icons
- 支持返回键导航
