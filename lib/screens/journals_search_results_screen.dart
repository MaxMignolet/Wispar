import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/crossref_api.dart';
import '../models/crossref_journals_models.dart' as Journals;
import '../widgets/journal_search_results_card.dart';

class SearchResultsScreen extends StatefulWidget {
  final ListAndMore<Journals.Item> searchResults;
  final String searchQuery;

  const SearchResultsScreen({
    Key? key,
    required this.searchResults,
    required this.searchQuery,
  }) : super(key: key);

  @override
  _SearchResultsScreenState createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  List<Journals.Item> items = [];
  bool isLoading = false;
  late ScrollController _scrollController;
  bool hasMoreResults = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    if (widget.searchResults.list.isNotEmpty) {
      items = widget.searchResults.list;
      hasMoreResults = widget.searchResults.hasMore;
    } else {
      hasMoreResults = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.searchresults),
      ),
      body: items.isEmpty
          ? Center(
              child: Text('No results found.'),
            )
          : ListView.builder(
              itemCount: items.length + (hasMoreResults ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == items.length) {
                  // Display a loading indicator at the end of the list
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else {
                  Journals.Item currentItem = items[index];

                  // Skip invalid items
                  if (currentItem.issn.isEmpty) return SizedBox.shrink();

                  return JournalsSearchResultCard(
                    key: UniqueKey(),
                    item: currentItem,
                    isFollowed: false,
                  );
                }
              },
              controller: _scrollController,
            ),
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !isLoading &&
        hasMoreResults) {
      loadMoreItems(widget.searchQuery);
    }
  }

  Future<void> loadMoreItems(String query) async {
    setState(() => isLoading = true);

    try {
      ListAndMore<Journals.Item> newResults =
          await CrossRefApi.queryJournalsByName(query);

      setState(() {
        items.addAll(newResults.list);
        hasMoreResults = newResults.hasMore && newResults.list.isNotEmpty;
      });
    } catch (e) {
      print('Error loading more items: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
