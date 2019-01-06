import 'package:anlage_app_game/api/dtos.generated.dart';
import 'package:anlage_app_game/utils/deps.dart';
import 'package:anlage_app_game/utils/dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CompanyDetailsScreen extends StatelessWidget {
  CompanyInfoDetails details;
  InstrumentImageDto logo;

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
                margin: EdgeInsets.symmetric(horizontal: 32),
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
              Container(
                padding: EdgeInsets.only(top: 64),
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
