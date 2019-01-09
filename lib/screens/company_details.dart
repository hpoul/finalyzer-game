import 'package:anlage_app_game/api/api_pricedata.dart';
import 'package:anlage_app_game/api/dtos.generated.dart';
import 'package:anlage_app_game/utils/deps.dart';
import 'package:anlage_app_game/utils/dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:logging/logging.dart';

final _logger = Logger('app.anlage.game.screens.company_details');

class CompanyDetailsScreen extends StatelessWidget {
  final CompanyInfoDetails details;
  final InstrumentImageDto logo;

  CompanyDetailsScreen(this.details, this.logo);

  @override
  Widget build(BuildContext context) {
    final api = DepsProvider.of(context).api;
    return Scaffold(
      appBar: AppBar(
        title: Text(details.name),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                margin: EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                child: CachedNetworkImage(
                  imageUrl: api.getImageUrl(logo),
                  height: 100,
//              width: 100,
                  fit: BoxFit.contain,
                ),
              ),
              Text(
                '${details.name} (${details.symbol})',
                style: Theme.of(context).textTheme.title,
                textAlign: TextAlign.center,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  details.description,
                  style: Theme.of(context).textTheme.subtitle,
                  textAlign: TextAlign.right,
                ),
              ),
              Container(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () {
                    DialogUtil.launchUrl(details.website);
                  },
//                  icon: Icon(Icons.open_in_new, size: 16,),
                  child: Text(
                    details.website,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ),
              ),
              details.extractText == null
                  ? Container()
                  : Column(
                      children: [
                        Container(
                            margin: EdgeInsets.only(top: 16),
                            child: Text(
                              details.extractText.content,
                              style:
                                  Theme.of(context).textTheme.body1.apply(fontSizeFactor: 0.8, color: Colors.black45),
                              textAlign: TextAlign.justify,
                            )),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FlatButton.icon(
                            onPressed: () {
                              DialogUtil.launchUrl(details.extractText.sourceUrl);
                            },
                            padding: EdgeInsets.all(0),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            icon: Icon(
                              Icons.open_in_new,
                              size: 16,
                            ),
                            label: Text('Wikipedia'),
                          ),
                        ),
                      ],
                    ),
              SizedBox(
                height: 150,
                child: StockChart(details.symbol),
              ),
              Text(
                'Last 52 week stock price',
                style: Theme.of(context).textTheme.caption,
                textAlign: TextAlign.center,
              ),
              Container(
                padding: EdgeInsets.only(top: 16),
                child: FlatButton(
                  onPressed: () {
                    DialogUtil.openFeedback(origin: 'company_details');
                  },
                  child: Text(
                    'Report problem/Feedback',
                    style: Theme.of(context)
                        .textTheme
                        .body1
                        .apply(color: Theme.of(context).primaryColor, fontSizeFactor: 0.8),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class StockChart extends StatefulWidget {
  String symbol;
  DateTime start = DateTime.now().subtract(Duration(days: 7 * 52));
  DateTime end = DateTime.now();

  StockChart(this.symbol);

  @override
  _StockChartState createState() => _StockChartState();
}

class _StockChartState extends State<StockChart> {
  ApiPriceData _apiPriceData;
  Future<charts.Series<double, DateTime>> stockDataFuture;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    this._apiPriceData = DepsProvider.of(context).apiPriceData;
    _loadData();
  }

  void _loadData() {
    if (stockDataFuture == null) {
      stockDataFuture = _apiPriceData.getEodStockData(
        symbols: [this.widget.symbol],
        start: widget.start,
        end: widget.end,
      ).then((response) {
        return charts.Series<double, DateTime>(
          id: widget.symbol,
          data: response.data[widget.symbol],
          domainFn: (value, index) => widget.start.add(Duration(days: response.sampleEveryNth * index)),
          measureFn: (value, index) => value,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<charts.Series<double, DateTime>>(
      future: stockDataFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorRetry(
            onPressed: () {
              setState(() {
                _loadData();
              });
            },
            error: snapshot.error,
          );
        }
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.data.data?.isEmpty ?? true) {
          _logger.severe('No data available for ${widget.symbol}');
          return Center(child: Text('No data available.'));
        }

        return charts.TimeSeriesChart(
          [snapshot.data],
          animate: false,
          primaryMeasureAxis: charts.NumericAxisSpec(
            tickProviderSpec: charts.BasicNumericTickProviderSpec(zeroBound: false, desiredTickCount: 5),
          ),
//          behaviors: [
//            charts.SeriesLegend(position: charts.BehaviorPosition.bottom),
//          ],
//          domainAxis: new charts.EndPointsTimeAxisSpec(
////            tickProviderSpec: charts.AutoDateTimeTickProviderSpec(includeTime: false),
//          ),
//          secondaryMeasureAxis: charts.EndPointsTimeAxisSpec(
//            tickProviderSpec: charts.AutoDateTimeTickProviderSpec(includeTime: false),
//          ),
        );
      },
    );
  }
}
