// ignore_for_file: unused_catch_stack

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:karing/app/modules/auto_update_manager.dart';
import 'package:karing/app/modules/remote_config_manager.dart';
import 'package:karing/app/modules/setting_manager.dart';
import 'package:karing/app/utils/analytics_utils.dart';
import 'package:karing/app/utils/app_utils.dart';
import 'package:karing/app/utils/file_utils.dart';
import 'package:karing/app/utils/install_referrer_utils.dart';
import 'package:karing/app/utils/path_utils.dart';
import 'package:karing/app/utils/platform_utils.dart';
import 'package:karing/app/utils/proxy_conf_utils.dart';
import 'package:karing/app/utils/singbox_json_utils.dart';
import 'package:karing/app/utils/url_launcher_utils.dart';
import 'package:karing/i18n/strings.g.dart';
import 'package:karing/screens/dialog_utils.dart';
import 'package:karing/screens/file_content_viewer_screen.dart';
import 'package:karing/screens/group_item.dart';
import 'package:karing/screens/group_screen.dart';
import 'package:karing/screens/theme_config.dart';
import 'package:karing/screens/widgets/framework.dart';
import 'package:path/path.dart' as path;
import 'package:advertising_id/advertising_id.dart';

class AboutScreen extends LasyRenderingStatefulWidget {
  static RouteSettings routSettings() {
    return const RouteSettings(name: "AboutScreen");
  }

  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => AboutScreenState();
}

class AboutScreenState extends LasyRenderingState<AboutScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    if (SettingManager.getDirty()) {
      SettingManager.saveConfig();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tcontext = Translations.of(context);
    Size windowSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.zero,
        child: AppBar(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const SizedBox(
                        width: 50,
                        height: 30,
                        child: Icon(
                          Icons.arrow_back_ios_outlined,
                          size: 26,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: windowSize.width - 50 * 2,
                      child: Text(
                        tcontext.about,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: ThemeConfig.kFontWeightTitle,
                            fontSize: ThemeConfig.kFontSizeTitle),
                      ),
                    ),
                    const SizedBox(
                      width: 50,
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Expanded(
                child: Column(
                  children: [
                    InkWell(
                      onDoubleTap: () {
                        SettingManager.getConfig().dev.devMode = true;

                        setState(() {});
                      },
                      child: Image.asset(
                        "assets/images/app_icon_128.png",
                        width: 128,
                        height: 128,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    SingleChildScrollView(
                      child: FutureBuilder(
                        future: getGroupOptions(),
                        builder: (BuildContext context,
                            AsyncSnapshot<List<GroupItem>> snapshot) {
                          List<GroupItem> data =
                              snapshot.hasData ? snapshot.data! : [];
                          return Column(
                              children:
                                  GroupItemCreator.createGroups(context, data));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<GroupItem>> getGroupOptions() async {
    final tcontext = Translations.of(context);

    String termOfUse = AppUtils.getTermsOfServiceUrl();
    List<GroupItem> groupOptions = [];

    {
      List<GroupItemOptions> options = [
        GroupItemOptions(
            textOptions: GroupItemTextOptions(
          name: tcontext.name,
          text: AppUtils.getName(),
        )),
        GroupItemOptions(
            textOptions: GroupItemTextOptions(
          name: tcontext.version,
          text: AppUtils.getBuildinVersion(),
        )),
        GroupItemOptions(
            textOptions: GroupItemTextOptions(
          name: tcontext.AboutScreen.installRefer,
          text: await InstallReferrerUtils.getString(),
        )),
        AutoUpdateManager.isSupport()
            ? GroupItemOptions(
                pushOptions: GroupItemPushOptions(
                    name: tcontext.AboutScreen.versionChannel,
                    text: SettingManager.getConfig().autoUpdateChannel,
                    onPush: () async {
                      onTapAutoUpdateChannel();
                    }))
            : GroupItemOptions()
      ];

      groupOptions.add(GroupItem(options: options));
    }
    {
      List<GroupItemOptions> options = [
        termOfUse.isNotEmpty
            ? GroupItemOptions(
                pushOptions: GroupItemPushOptions(
                    name: tcontext.termOfUse,
                    onPush: () async {
                      DialogUtils.showTermsofService(context);
                    }))
            : GroupItemOptions(),
        GroupItemOptions(
            pushOptions: GroupItemPushOptions(
                name: tcontext.privacyPolicy,
                onPush: () async {
                  DialogUtils.showPrivacyPolicy(context);
                })),
        GroupItemOptions(
            switchOptions: GroupItemSwitchOptions(
                name: tcontext.AboutScreen.disableUAReport,
                tips: tcontext.AboutScreen.disableUAReportTip,
                switchValue: RemoteConfigManager.rejectAnalyticsSubmit() ||
                    SettingManager.getConfig().disableUAReport,
                onSwitch: RemoteConfigManager.rejectAnalyticsSubmit()
                    ? null
                    : (bool value) async {
                        AnalyticsUtils.logEvent(
                            analyticsEventType: analyticsEventTypeUA,
                            name: 'SSS_diableUAReport',
                            parameters: {"value": value});

                        AnalyticsUtils.setEventType(value
                            ? analyticsEventTypeNoUA
                            : analyticsEventTypeAll);
                        SettingManager.getConfig().disableUAReport = value;
                        SettingManager.saveConfig();
                        setState(() {});
                      })),
      ];
      groupOptions.add(GroupItem(options: options));
    }

    List<GroupItemOptions> options = [
      GroupItemOptions(
          pushOptions: GroupItemPushOptions(
              name: tcontext.AboutScreen.devOptions,
              onPush: () async {
                onTapDevOptions();
              }))
    ];
    groupOptions.add(GroupItem(options: options));

    return groupOptions;
  }

  void onTapDevOptions() async {
    final tcontext = Translations.of(context);
    var settingConfig = SettingManager.getConfig();
    var dev = settingConfig.dev;
    String advertisingId = "";
    if (Platform.isIOS || Platform.isAndroid) {
      try {
        advertisingId = (await AdvertisingId.id(true)) ?? "";
      } catch (err) {}
    }

    AnalyticsUtils.logEvent(
        analyticsEventType: analyticsEventTypeUA, name: 'SSS_devOptions');
    Future<List<GroupItem>> getOptions(BuildContext context) async {
      List<GroupItemOptions> options = [
        !settingConfig.novice
            ? GroupItemOptions(
                switchOptions: GroupItemSwitchOptions(
                    name: tcontext.AboutScreen.enableDebugLog,
                    switchValue: dev.enableDebugLog,
                    onSwitch: (bool value) async {
                      dev.enableDebugLog = value;
                      SettingManager.setDirty(true);
                      setState(() {});
                    }))
            : GroupItemOptions(),
        GroupItemOptions(
            pushOptions: GroupItemPushOptions(
                name: tcontext.AboutScreen.viewFilsContent,
                onPush: () async {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          settings: FileContentViewerScreen.routSettings(),
                          builder: (context) =>
                              const FileContentViewerScreen()));
                })),
        PlatformUtils.isPC()
            ? GroupItemOptions(
                pushOptions: GroupItemPushOptions(
                    name: tcontext.AboutScreen.openDir,
                    onPush: () async {
                      await FileUtils.openDirectory(
                          await PathUtils.profileDir());
                    }))
            : GroupItemOptions(),
      ];
      List<GroupItemOptions> options1 = [
        !settingConfig.novice
            ? GroupItemOptions(
                pushOptions: GroupItemPushOptions(
                    name: tcontext.AboutScreen.useOriginalSBProfile,
                    text: path
                        .basename(SettingManager.getConfig().originSBProfile),
                    textWidthPercent: 0.4,
                    onPush: () async {
                      await onTapUseOriginSBProfile();
                    }))
            : GroupItemOptions(),
      ];
      List<GroupItemOptions> options2 = [
        dev.devMode && !settingConfig.novice
            ? GroupItemOptions(
                switchOptions: GroupItemSwitchOptions(
                    name: tcontext.AboutScreen.enablePprof,
                    switchValue: SettingManager.getConfig().dev.pprofPort ==
                        SettingConfigItemDev.pprofPortDefault,
                    onSwitch: (bool value) async {
                      SettingManager.getConfig().dev.pprofPort =
                          value ? SettingConfigItemDev.pprofPortDefault : 0;
                      SettingManager.setDirty(true);
                      setState(() {});
                    }))
            : GroupItemOptions(),
        dev.devMode && !settingConfig.novice
            ? GroupItemOptions(
                pushOptions: GroupItemPushOptions(
                    name: tcontext.AboutScreen.pprofPanel,
                    onPush: () async {
                      UrlLauncherUtils.loadUrl(
                          "http://localhost:${SettingManager.getConfig().dev.pprofPort}/debug/pprof/");
                    }))
            : GroupItemOptions(),
      ];
      List<GroupItemOptions> options3 = [
        (Platform.isIOS || Platform.isAndroid) &&
                dev.devMode &&
                !settingConfig.novice
            ? GroupItemOptions(
                textOptions: GroupItemTextOptions(
                    name: "Advertising Id",
                    text: advertisingId,
                    textWidthPercent: 0.5,
                    onPush: () async {
                      try {
                        await Clipboard.setData(
                            ClipboardData(text: advertisingId));
                      } catch (err) {}
                    }))
            : GroupItemOptions(),
      ];
      return [
        GroupItem(options: options),
        GroupItem(options: options1),
        GroupItem(options: options2),
        GroupItem(options: options3)
      ];
    }

    await Navigator.push(
        context,
        MaterialPageRoute(
            settings: GroupScreen.routSettings("devOptions"),
            builder: (context) => GroupScreen(
                  title: tcontext.AboutScreen.devOptions,
                  getOptions: getOptions,
                )));
    setState(() {});
  }

  void onTapAutoUpdateChannel() async {
    final tcontext = Translations.of(context);

    Future<List<GroupItem>> getOptions(BuildContext context) async {
      List<GroupItemOptions> options = [];

      for (var channel in AutoUpdateManager.updateChannels()) {
        options.add(GroupItemOptions(
            textOptions: GroupItemTextOptions(
                name: channel,
                text: "",
                onPush: () async {
                  if (SettingManager.getConfig().autoUpdateChannel == channel) {
                    return;
                  }
                  SettingManager.getConfig().autoUpdateChannel = channel;

                  AutoUpdateManager.updateChannelChanged();
                  Navigator.pop(context);
                })));
      }
      return [GroupItem(options: options)];
    }

    await Navigator.push(
        context,
        MaterialPageRoute(
            settings: GroupScreen.routSettings("versionChannel"),
            builder: (context) => GroupScreen(
                  title: tcontext.AboutScreen.versionChannel,
                  getOptions: getOptions,
                )));
    setState(() {});
  }

  Future<void> onTapUseOriginSBProfile() async {
    if (SettingManager.getConfig().originSBProfile.isNotEmpty) {
      bool? ok = await DialogUtils.showConfirmDialog(context, "Clear ?");
      if (ok == true) {
        SettingManager.getConfig().originSBProfile = "";
        setState(() {});
        SettingManager.setDirty(true);
      }

      return;
    }
    try {
      List<String> extensions = ["json"];
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: extensions,
      );
      if (result != null) {
        String filePath = result.files.first.path!;
        String ext = path.extension(filePath).replaceAll('.', '').toLowerCase();
        if (!extensions.contains(ext)) {
          return;
        }
        var file = File(filePath);
        String content = await file.readAsString();
        ServerConfigGroupItem proxyItem = ServerConfigGroupItem();
        List<ServerDiversionGroupRuleSetItem> rulesetItems = [];
        TransExceptionAndUnsupport eu = TransExceptionAndUnsupport();

        var cresult = SingboxJsonUtils.tryConvert(
            content, proxyItem, rulesetItems, null, eu);
        if (cresult.error != null) {
          if (!mounted) {
            return;
          }
          DialogUtils.showAlertDialog(
              context, cresult.error!.message.toString(),
              showCopy: true, showFAQ: true, withVersion: true);
          return;
        }
        SettingManager.getConfig().originSBProfile = filePath;
        setState(() {});
        SettingManager.setDirty(true);
      }
    } catch (err, stacktrace) {
      if (!mounted) {
        return;
      }
      DialogUtils.showAlertDialog(context, err.toString(),
          showCopy: true, showFAQ: true, withVersion: true);
    }
  }
}