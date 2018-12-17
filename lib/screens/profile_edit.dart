import 'package:anlage_app_game/api/api_service.dart';
import 'package:anlage_app_game/api/dtos.generated.dart';
import 'package:anlage_app_game/utils/deps.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';

final _logger = new Logger("app.anlage.game.screens.profile_edit");

class ProfileEdit extends StatefulWidget {
  static const ROUTE_NAME = '/profile/edit';

  @override
  State<StatefulWidget> createState() => ProfileEditState();
}

class ProfileEditState extends State<ProfileEdit> {
  ApiService _api;
  Future<UserInfoResponse> _uploadFuture;
  final _formKey = GlobalKey<FormState>();
  static final emailRegexp = RegExp('^.+@.*\..+\$');
  TextEditingController _displayNameCtrl;
  TextEditingController _emailCtrl;

  Future<UserInfoResponse> _userUpdateFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _api = DepsProvider.of(context).api;
  }

  @override
  Widget build(BuildContext context) {
    final api = DepsProvider.of(context).api;

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Profile'),
      ),
      body: StreamBuilder<LoginState>(
        stream: api.loginState,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (_displayNameCtrl == null) {
            _logger.finer('creating TextEditingControllers.');
            _displayNameCtrl = TextEditingController(text: snapshot.data.userInfo.displayName);
            _emailCtrl = TextEditingController(text: snapshot.data.userInfo.email);
          }

          _logger.finer('avatar url = ${snapshot.data.avatarUrl}');
          final state = snapshot.data;
          return Form(
            key: _formKey,
            child: Container(
              margin: EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    Text('Tell us a bit about yourself so you are immortalized in the MarketCap Leaderboard!'),
                    InkWell(
                      onTap: selectProfileImage,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 16.0),
                        constraints: BoxConstraints.tightFor(width: 100.0, height: 100.0),
                        alignment: Alignment.center,
                        child: Center(
                          child: FutureBuilder(
                            future: _uploadFuture,
                            builder: (context, snapshot) => snapshot.connectionState == ConnectionState.waiting
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: <Widget>[
                                      CircularProgressIndicator(),
                                      Text('Uploading …'),
                                    ],
                                  )
                                : Stack(
                                    children: [
                                      Container(
//                          constraints: BoxConstraints.tightFor(width: 80.0, height: 80.0),
                                        alignment: Alignment.center,
                                        child: CircleAvatar(
                                          backgroundImage: CachedNetworkImageProvider(state.avatarUrl),
//                                  radius: 40,
                                          minRadius: 40,
//                                  maxRadius: 80,
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: Container(
                                          height: 24.0,
                                          width: 24.0,
                                          padding: EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            boxShadow: [
                                              BoxShadow(),
                                            ],
                                            border: Border.all(color: Colors.white),
                                            borderRadius: BorderRadius.circular(12.0),
                                          ),
                                          child: FittedBox(fit: BoxFit.contain, child: Icon(Icons.edit)),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: _displayNameCtrl,
                      textCapitalization: TextCapitalization.words,
                      keyboardType: TextInputType.text,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Your full name',
                      ),
                    ),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(labelText: 'Your email address, so you can log back in'),
                      validator: (value) {
                        if (value.isEmpty || emailRegexp.hasMatch(value)) {
                          _logger.fine('has match. $value');
                          return null;
                        }
                        return 'Please enter a valid email address.';
                      },
                    ),
                    FutureBuilder(
                      builder: (context, snapshot) => Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: RaisedButton(
                          child: snapshot.connectionState == ConnectionState.waiting ? Text('Saving …') : Text('Save'),
                          color: Theme.of(context).accentColor,
                          onPressed: snapshot.connectionState == ConnectionState.waiting ? null : () {
                            if (!_formKey.currentState.validate()) {
                              Scaffold
                                  .of(context)
                                  .showSnackBar(SnackBar(content: Text('Please fix the errors.')));
                              return;
                            }
                            setState(() {
                              _userUpdateFuture = _api.updateUserInfo(displayName: _displayNameCtrl.text, email: _emailCtrl.text);
                            });
                            _userUpdateFuture.then((val) {
                              Scaffold
                                  .of(context)
                                  .showSnackBar(SnackBar(content: Text('Saved successfully.')));
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> selectProfileImage() async {
    final image = await ImagePicker.pickImage(source: ImageSource.gallery, maxWidth: 1000, maxHeight: 1000);
    if (image != null) {
      setState(() {
        // TODO handle (network) errors.
        _uploadFuture = _api.uploadAvatarImage(image);
      });
    }
  }
}
