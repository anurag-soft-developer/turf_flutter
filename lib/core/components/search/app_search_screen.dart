import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../components/shared/app_search_field.dart';
import '../../config/constants.dart';
import '../../services/search/search_history_store.dart';
import 'search_history.dart';

typedef AppSearchResultsBuilder = Widget Function(
  BuildContext context,
  String submittedQuery,
);

typedef AppSearchHeaderBuilder = Widget Function(
  BuildContext context,
  String submittedQuery,
);

class AppSearchScreen extends HookWidget {
  const AppSearchScreen({
    super.key,
    required this.historyScope,
    required this.hintText,
    required this.resultsBuilder,
    this.title = 'Search',
    this.headerBuilder,
    this.autofocus = true,
  });

  final SearchHistoryScope historyScope;
  final String hintText;
  final String title;
  final AppSearchResultsBuilder resultsBuilder;
  final AppSearchHeaderBuilder? headerBuilder;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final searchController = useTextEditingController();
    final focusNode = useFocusNode();
    final submittedQuery = useState('');
    final isFieldFocused = useState(autofocus);
    final historyItems = useState<List<String>>(const []);
    final historyStore = useMemoized(() => SearchHistoryStore(historyScope));

    Future<void> refreshHistory() async {
      historyItems.value = await historyStore.load();
    }

    useEffect(() {
      refreshHistory();
      return null;
    }, const []);

    useEffect(() {
      void listener() {
        isFieldFocused.value = focusNode.hasFocus;
      }

      focusNode.addListener(listener);
      return () => focusNode.removeListener(listener);
    }, [focusNode]);

    Future<void> submit(String raw) async {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) {
        submittedQuery.value = '';
        return;
      }

      searchController.value = TextEditingValue(
        text: trimmed,
        selection: TextSelection.collapsed(offset: trimmed.length),
      );
      submittedQuery.value = trimmed;
      await historyStore.add(trimmed);
      await refreshHistory();
      focusNode.unfocus();
    }

    void clearSubmitted() {
      submittedQuery.value = '';
    }

    final query = submittedQuery.value;
    final showResults = query.isNotEmpty && !isFieldFocused.value;

    return Scaffold(
      backgroundColor: const Color(AppColors.backgroundColor),
      appBar: AppBar(title: Text(title)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: AppSearchField(
              controller: searchController,
              focusNode: focusNode,
              hintText: hintText,
              autofocus: autofocus,
              onSubmitted: submit,
              onCleared: clearSubmitted,
            ),
          ),
          if (showResults && headerBuilder != null)
            headerBuilder!(context, query),
          Expanded(
            child: showResults
                ? resultsBuilder(context, query)
                : SearchHistory(
                    items: historyItems.value,
                    onSelect: submit,
                    onRemove: (term) async {
                      await historyStore.remove(term);
                      await refreshHistory();
                    },
                    onClearAll: () async {
                      await historyStore.clear();
                      await refreshHistory();
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
