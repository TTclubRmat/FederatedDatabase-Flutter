# FederateDatabase-Flutter 项目文档

FederateDatabase-Flutter 是 FederateDatabase 的前端项目，专注于提供一个基于 Flutter 构建的跨平台应用。有关后端的详细信息，请参阅 [FederateDatabase 后端项目](https://github.com/7fenfen/FederatedDataBase)。本文档将简要介绍该 Flutter 应用的设计和实现。

## Flutter 使用感受

本应用是我首次使用 Flutter 构建的正式项目，过程中充分感受到 Flutter 在以下方面的优势：

- **快速开发**：Flutter 提供了极高的开发效率，极大缩短了开发周期。
- **强大功能**：它支持 gRPC 数据传输，能够处理图形绘制、动画等复杂的前端需求。
- **美观和高性能**：Flutter 构建的界面非常美观，性能也非常优异，提供了流畅的用户体验。
- **跨平台支持**：使用 Flutter 开发的应用可以一次编写，部署到多平台，包括 Web、Windows、macOS、iOS、Android 和 Linux，无需针对不同平台编写原生代码，尽管在某些平台上仍需进行一些优化（如 Web 字体问题）。

## 项目文档

### 1. 部分自建函数

以下是一些自定义的函数，用于处理与 SharedPreferences 的数据存储与检索。

#### `saveDb`

保存字符串键值对到 SharedPreferences。

```dart
void saveDb(String key, String value) async
```

- **参数**：
  - `key`：字符串类型，用于标识存储的数据。
  - `value`：字符串类型，存储的数据。
  
#### `saveDbList`

保存字符串列表到 SharedPreferences，特别适用于 JSON 数据。

```dart
Future<void> saveDbList(String key, List<String> value) async
```

- **参数**：
  - `key`：字符串类型，用于标识存储的数据。
  - `value`：字符串列表，要存储的数据。

#### `getDb`

从 SharedPreferences 获取字符串数据。

```dart
Future<String> getDb(String key) async
```

- **参数**：
  - `key`：字符串类型，用于检索存储的数据。
  
- **返回值**：
  - 返回与 `key` 关联的字符串值。如果不存在，返回空字符串。

#### `getDbList`

从 SharedPreferences 获取字符串列表数据，并将其转换为 Dart 字符串列表。

```dart
Future<List<String>> getDbList(String key) async
```

- **参数**：
  - `key`：字符串类型，用于检索存储的数据。
  
- **返回值**：
  - 返回与 `key` 关联的字符串列表。如果不存在或发生错误，返回空列表。

#### `removeDb`

从 SharedPreferences 中移除指定 `key` 的数据。

```dart
void removeDb(String key) async
```

- **参数**：
  - `key`：字符串类型，要移除的数据的标识符。

> 注意：所有函数均为异步操作，需使用 `await` 关键字或 `.then()` 方法处理返回结果。

### 2. 代码结构

项目的代码结构简洁明了，主要包含以下几个部分：

- **核心业务逻辑**：包含前端应用的主功能实现。
- **UI 层**：用于显示和处理用户界面的 Flutter 小部件。
- **数据层**：处理数据存储与检索，主要与 SharedPreferences 进行交互。

### 3. 绘图功能

本项目包含一个名为 `PlotChart` 的小部件，用于绘制交互式散点图。该图表主要用于显示来自不同数据库的数据点，并支持多种交互功能。

#### 主要组件

- **PlotChart**：`PlotChart` 是一个 `StatefulWidget`，负责图表的整体布局和交互。主要特点：
  - 使用 `AspectRatio` 来确保图表保持正方形。
  - 支持鼠标悬停检测。
  - 包含图例。

- **PlotPainter**：`PlotPainter` 是一个 `CustomPainter`，负责实际的绘图逻辑。

#### 绘图步骤

1. **计算坐标范围**：
   - 遍历所有数据点，动态确定 X 和 Y 轴的最小值和最大值。
   - 考虑默认点的位置。
   - 添加边距并确保坐标范围在 0-200 之间。

2. **绘制坐标轴**：
   - 绘制 X 轴和 Y 轴。
   - 绘制网格线。
   - 添加刻度标签。

3. **绘制数据点**：
   - 根据数据库 ID 使用不同的颜色（如红色、绿色、蓝色）。
   - 使用圆形绘制数据点。

4. **绘制默认点**：
   - 使用黑色绘制较大的圆形。

5. **绘制提示框**：
   - 当鼠标悬停在数据点附近时，显示该点的 X 和 Y 坐标。

#### 交互特性

- **鼠标悬停**：当鼠标悬停在数据点附近时，显示该点的详细信息（X 和 Y 坐标）。
- **图例**：在图表下方显示颜色图例，解释不同颜色代表的数据库。

#### 辅助函数

- `_getPointPosition`：将数据坐标转换为画布坐标。
- `_findNearestResult`：查找最接近鼠标位置的数据点。
- `_drawTooltip`：绘制提示框，显示数据点的信息。

#### 性能考虑

- 使用 `shouldRepaint` 方法优化重绘逻辑，确保图表仅在必要时重绘，从而提高性能。

此绘图组件提供了一个灵活且交互式的方式来可视化来自多个数据库的数据点，用户可通过鼠标悬停获取更多详细信息。

### 4. 动画效果

本应用提供了流畅的动画效果，包括渐显、渐隐、缩放和弹出动画等，增强了用户交互体验。这些动画在用户操作时能够带来丝滑流畅的过渡效果，使得应用更加富有吸引力。

### 5. 其它功能

- **跨平台支持**：应用支持在多个平台（Windows、macOS、iOS、Android 和 Linux）上运行，代码只需编写一次，即可在多平台上部署。由于web不支持gRPC，故无法在web上进行部署。
- **略**：不好意思写累了，下次有了兴趣再来写。嘿嘿~~~

---

如需gRPC及联邦数据库、最近邻与反向最近邻、加密查询等实现的细节，请参阅 **Zhang Hengxin** 开发的后端项目文档，文档链接已在开篇给出。
