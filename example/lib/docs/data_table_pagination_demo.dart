import 'package:material_ui/material_ui.dart';
import 'package:yumeiro/yumeiro.dart';

// #region data-table-pagination
Widget dataTablePaginationDemo(
  BuildContext context, {
  Widget Function(String api, Widget child)? decorate,
}) => _DataTablePaginationDemo(decorate: decorate);

typedef _Record = ({int id, String name, String englishName, bool ready});
typedef _Request = ({int index, String query, bool ascending});
typedef _Page = ({String query, List<_Record> rows, int total});

const _pageSize = 4;
final _records = <_Record>[
  (id: 1, name: '01 示例 A', englishName: '01 Example A', ready: true),
  (id: 2, name: '02 示例 B1', englishName: '02 Example B1', ready: true),
  (id: 3, name: '03 示例 C', englishName: '03 Example C', ready: false),
  (id: 4, name: '04 示例 D', englishName: '04 Example D', ready: true),
  (id: 5, name: '05 示例 B2', englishName: '05 Example B2', ready: true),
  (id: 6, name: '06 示例 E', englishName: '06 Example E', ready: false),
  (id: 7, name: '07 示例 F', englishName: '07 Example F', ready: true),
  (id: 8, name: '08 示例 G', englishName: '08 Example G', ready: true),
  (id: 9, name: '09 示例 H', englishName: '09 Example H', ready: true),
  (id: 10, name: '10 示例 B3', englishName: '10 Example B3', ready: true),
  (id: 11, name: '11 示例 I', englishName: '11 Example I', ready: true),
  (id: 12, name: '12 示例 J', englishName: '12 Example J', ready: true),
  for (var id = 13; id <= 48; id++)
    (id: id, name: '$id 示例 $id', englishName: '$id Example $id', ready: true),
];

// Simulates a server that filters and sorts all matching records before slicing.
Future<_Page> _fetchPage(_Request request, {required bool fail}) async {
  // Page two responds more slowly so a newer request can finish first.
  await Future<void>.delayed(
    Duration(milliseconds: request.index == 1 ? 850 : 200),
  );
  if (fail) throw StateError('Simulated request failure');

  final keyword = request.query.trim().toLowerCase();
  final matches = _records
      .where(
        (record) =>
            record.name.toLowerCase().contains(keyword) ||
            record.englishName.toLowerCase().contains(keyword),
      )
      .toList();
  matches.sort(
    (a, b) =>
        request.ascending ? a.name.compareTo(b.name) : b.name.compareTo(a.name),
  );
  return (
    query: request.query,
    rows: matches
        .skip(request.index * _pageSize)
        .take(_pageSize)
        .toList(growable: false),
    total: matches.length,
  );
}

enum _FetchStatus { loading, ready, failed }

class _DataTablePaginationDemo extends StatefulWidget {
  const _DataTablePaginationDemo({this.decorate});

  final Widget Function(String api, Widget child)? decorate;

  @override
  State<_DataTablePaginationDemo> createState() =>
      _DataTablePaginationDemoState();
}

class _DataTablePaginationDemoState extends State<_DataTablePaginationDemo> {
  _Request _request = (index: 0, query: '', ascending: true);
  _Page? _page;
  _FetchStatus _status = _FetchStatus.loading;
  int _generation = 0;
  Set<Key> _selectedKeys = const {};
  bool _failNextRequest = false;

  @override
  void initState() {
    super.initState();
    _load(0);
  }

  Future<void> _load(int index, {String? query, bool? ascending}) async {
    final request = (
      index: index,
      query: query ?? _request.query,
      ascending: ascending ?? _request.ascending,
    );
    final generation = ++_generation;
    final fail = _failNextRequest;
    setState(() {
      _request = request;
      _status = _FetchStatus.loading;
      _failNextRequest = false;
    });

    try {
      final page = await _fetchPage(request, fail: fail);
      if (!mounted || generation != _generation) return;
      setState(() {
        _page = page;
        _status = _FetchStatus.ready;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() => _status = _FetchStatus.failed);
    }
  }

  ValueKey<int> _rowKey(_Record record) => ValueKey(record.id);

  Widget _table(_Page page, {required bool chinese}) {
    String name(_Record record) => chinese ? record.name : record.englishName;
    Widget badge(_Record record) => YumeiroBadge(
      label: record.ready
          ? (chinese ? '可用' : 'Available')
          : (chinese ? '准备中' : 'Preparing'),
      statusRole: record.ready
          ? YumeiroStatusRole.success
          : YumeiroStatusRole.info,
    );

    return YumeiroScrollView(
      child: YumeiroDataTable<_Record>(
        items: page.rows,
        minWidth: 280,
        rowKey: _rowKey,
        rowSemanticsLabel: name,
        emptyPlaceholder: YumeiroEmptyState(
          title: chinese ? '没有匹配的示例' : 'No matching records',
          compact: true,
        ),
        columns: [
          YumeiroTableColumn(
            title: chinese ? '示例' : 'Example',
            cellBuilder: (_, record, _) => Text(name(record)),
          ),
          YumeiroTableColumn(
            title: chinese ? '状态' : 'Status',
            fixedWidth: 88,
            cellBuilder: (_, record, _) => badge(record),
          ),
        ],
        compactRowBuilder: (_, record, _) =>
            YumeiroDataRow(title: Text(name(record)), status: badge(record)),
        selection: YumeiroTableSelection(
          mode: YumeiroTableSelectionMode.multiple,
          selectedKeys: _selectedKeys,
          isItemEnabled: (record) => record.ready,
          onChanged: (keys) => setState(() => _selectedKeys = keys),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chinese = Localizations.localeOf(context).languageCode == 'zh';
    String text(String zh, String en) => chinese ? zh : en;
    Widget sample(String api, Widget child) =>
        widget.decorate?.call(api, child) ?? child;
    final ready = _status == _FetchStatus.ready;
    final lastPage = _page;
    final knownTotal = lastPage?.query == _request.query
        ? lastPage?.total
        : null;
    final pageCount = knownTotal == null
        ? 0
        : (knownTotal + _pageSize - 1) ~/ _pageSize;
    final page = ready ? lastPage! : null;
    final outsidePage = page == null
        ? 0
        : _selectedKeys.difference(page.rows.map(_rowKey).toSet()).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sample(
          'YumeiroSearchToolbar',
          YumeiroSearchToolbar(
            query: _request.query,
            placeholder: text('搜索示例', 'Search records'),
            onQueryChanged: (query) => _load(0, query: query),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            YumeiroButton(
              label: _request.ascending
                  ? text('按名称降序', 'Sort by name (descending)')
                  : text('按名称升序', 'Sort by name (ascending)'),
              onPressed: () => _load(0, ascending: !_request.ascending),
            ),
            YumeiroButton(
              label: _failNextRequest
                  ? text('取消模拟失败', 'Cancel simulated failure')
                  : text('模拟下次请求失败', 'Fail next request'),
              variant: YumeiroButtonVariant.secondary,
              onPressed: () =>
                  setState(() => _failNextRequest = !_failNextRequest),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildResult(context, page, chinese: chinese),
        if (pageCount > 0) ...[
          const SizedBox(height: 12),
          sample(
            'YumeiroPagination',
            Center(
              child: YumeiroPagination(
                pageIndex: _request.index,
                pageCount: pageCount,
                onChanged: _load,
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              text(
                '已选择 ${_selectedKeys.length} 项',
                'Selected: ${_selectedKeys.length}',
              ),
            ),
            if (outsidePage > 0)
              Text(
                text(
                  '其中 $outsidePage 项不在当前页',
                  '$outsidePage outside this page',
                ),
              ),
            YumeiroButton(
              label: text('清空全部选择', 'Clear all selections'),
              variant: YumeiroButtonVariant.ghost,
              dense: true,
              onPressed: _selectedKeys.isEmpty
                  ? null
                  : () => setState(() => _selectedKeys = const {}),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResult(
    BuildContext context,
    _Page? page, {
    required bool chinese,
  }) {
    final (api, result) = switch (_status) {
      _FetchStatus.loading => (
        'YumeiroLoadingCard',
        YumeiroLoadingCard(message: chinese ? '正在加载示例' : 'Loading records'),
      ),
      _FetchStatus.ready => (
        'YumeiroDataTable',
        _table(page!, chinese: chinese),
      ),
      _FetchStatus.failed => (
        'YumeiroErrorState',
        YumeiroErrorState(
          title: chinese ? '加载失败' : 'Unable to load records',
          message: chinese ? '本次请求未完成，可以重试。' : 'Try the same request again.',
          action: YumeiroButton(
            label: YumeiroLocalizations.of(context).retry,
            onPressed: () => _load(_request.index),
          ),
        ),
      ),
    };
    final panel = SizedBox(height: 260, width: double.infinity, child: result);
    return widget.decorate?.call(api, panel) ?? panel;
  }
}
// #endregion data-table-pagination
