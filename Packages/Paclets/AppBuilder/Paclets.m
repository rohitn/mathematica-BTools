(* ::Package:: *)

(* Autogenerated Package *)

(* ::Text:: *)
(*Internal paclets cruft that\[CloseCurlyQuote]s been pushed to a lower-context*)



(* ::Subsubsection::Closed:: *)
(*Paclets*)



AppPacletBundle::usage=
  "Packs the .paclet file, removing the specified paths first";
AppPaclet::usage=
  "Generates the paclet expression for app";
AppPacletInfo::usage=
  "Gathers paclet info as an association";
AppRegeneratePacletInfo::usage=
  "Regenerates the PacletInfo file";
AppPacletSiteBundle::usage=
  "Generates the PacletSite.mz file for a collection of apps";
AppPacletSiteInfo::usage=
  "Pulls PacletSite expressions";
AppPacletBackup::usage=
  "Backs up an app to a server";
AppPacletDirectoryAdd::usage=
  "PacletDirectoryAdd on an app name";
AppPacletSiteURL::usage=
  "Gets an app paclet site to add";
AppPacletInstallerURL::usage=
  "Gets the URL to the auto-configured installer";
AppPacletUninstallerURL::usage=
  "Gets the URL to the auto-configure uninstaller";
AppPacletServerPage::usage=
  "Uploads a paclet access page to a server";
AppPacletUpload::usage=
  "Uploads paclet files to a server";
AppSubpacletUpload::usage=
  "Uploads a sub-app";


Begin["`Private`"];


(* ::Subsection:: *)
(*Paclet Dist*)



(* ::Subsubsection::Closed:: *)
(*AppPacletDocs*)



Options[AppPacletDocs]=
  Options[PacletDocsInfo]
AppPacletDocs[ops:OptionsPattern[]]:=
  PacletDocsInfo[ops];
AppPacletDocs[app_String,ops:OptionsPattern[]]:=
  PacletDocsInfo[AppDirectory[app],ops];


(* ::Subsubsection::Closed:: *)
(*AppPaclet*)



Options[AppPaclet]=
  Options[PacletInfoExpression];
AppPaclet[ops:OptionsPattern[]]:=
  PacletInfoExpression[ops];
AppPaclet[app_String,ops:OptionsPattern[]]:=
  PacletInfoExpression[
    AppDirectory[app],
    "Kernel"->{
      "Root" -> ".",
      "Context" -> 
        Join[
          {app<>"`"},
          StringRiffle[
            Prepend[app]@
              FileNameSplit[
                FileNameDrop[#,
                  FileNameDepth@AppDirectory[app,"Packages"]
                  ]
                ],
            "`"]<>"`"
            &/@
            Select[
              FileNames["*",AppDirectory[app,"Packages"],\[Infinity]],
              DirectoryQ@#&&
                AllTrue[
                  FileNameSplit@
                    FileNameDrop[#,FileNameDepth@AppDirectory[app,"Packages"]],
                  StringMatchQ[
                    #,
                    (WordCharacter|"$")..
                    ]
                  ]&
              ]
          ]
      },
    ops];


(* ::Subsubsection::Closed:: *)
(*AppPacletInfo*)



AppPacletInfo[app_String]:=
  PacletInfoAssociation@AppDirectory[app];


(* ::Subsubsection::Closed:: *)
(*AppRegeneratePacletInfo*)



Options[AppRegeneratePacletInfo]=
  Options[AppPaclet];
AppRegeneratePacletInfo[name_,
  pacletOps:OptionsPattern[]
  ]:=
  PacletInfoExpressionBundle[
    AppPaclet[name,pacletOps],
    AppDirectory[name]
    ];


(* ::Subsubsection::Closed:: *)
(*AppPacletSiteURL*)



Options[AppPacletSiteURL]=
  Options[PacletSiteURL];
AppPacletSiteURL[ops:OptionsPattern[]]:=
  PacletSiteURL[ops];
AppPacletSiteURL[app_String,ops:OptionsPattern[]]:=
  AppPacletSiteURL[ops,"ServerName"->app];


(* ::Subsubsection::Closed:: *)
(*AppPacletSiteInfo*)



Options[AppPacletSiteInfo]=
  Options@AppPacletSiteURL;
AppPacletSiteInfo[app_String,o:OptionsPattern[]]:=
  PacletSiteInfo@
    StringReplace[
      URLBuild@{
        AppPacletSiteURL[app,o],
        "PacletSite.mz"
        },
      StartOfString~~"file:":>"file://"
      ];


(* ::Subsubsection::Closed:: *)
(*AppPacletSiteBundle*)



Options[AppPacletSiteBundle]=
  DeleteDuplicatesBy[First]@
    Join[{
      "BuildRoot":>$AppDirectory,
      "FilePrefix"->Automatic
      },
      Options[PacletSiteBundle]
      ];
AppPacletSiteBundle[apps__String,ops:OptionsPattern[]]:=
  PacletSiteBundle[Sequence@@Map[AppDirectory,{apps}],
    FilterRules[{
      ops,
      If[OptionValue["FilePrefix"]===Automatic,
        "FilePrefix"->First@{apps},
        Nothing
        ],
      Options[AppPacletSiteBundle]
      },
      Options[PacletSiteBundle]
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*AppPacletBundle*)



Options[AppPacletBundle]=
  DeleteDuplicatesBy[First]@
    Join[
      {
        "BuildRoot":>$AppDirectory,
        "BundleInfo"->Automatic,
        "AppRegeneratePacletInfo"->Automatic,
        "UpdatePacletInfo"->False,
        "UpdateDependencies"->True
        },
      Options[PacletBundle]
      ];
AppPacletBundle[
  app_String,
  ops:OptionsPattern[]
  ]:=
  Replace[OptionValue["BundleInfo"],
    {
      Automatic:>
        AppPacletBundle[app,
          "BundleInfo"->
            Replace[AppPath[First@{app},"Config", "BundleInfo.m"],
              Except[_String?FileExistsQ]:>
                AppPath[First@{app},"BundleInfo.wl"]
              ],
          ops
          ],
      f:(_String|_File)?FileExistsQ|_URL:>
        AppPacletBundle[app,
          "BundleInfo"->None,
          ops,
          Replace[Import[f],{
            o:{__?OptionQ}:>
              (Sequence@@FilterRules[o,Options@AppPacletBundle]),
            _:>(Sequence@@{})
            }]
          ],
      _:>
        (
          If[TrueQ@OptionValue["UpdateDependencies"], 
            AppUpdateDepdencies[app]
            ];
          PacletBundle[
            AppDirectory[app],
            FilterRules[{ops, Options[AppPacletBundle]},
              Options[PacletBundle]
              ]
            ]
          )
      }
    ];


(* ::Subsubsection::Closed:: *)
(*AppPacletInstallerURL*)



Options[AppPacletInstallerURL]=
  Options@PacletInstallerURL;
AppPacletInstallerURL[ops:OptionsPattern[]]:=
  PacletInstallerURL[ops];
AppPacletInstallerURL[app_String,ops:OptionsPattern[]]:=
  PacletInstallerURL[ops,"ServerName"->app];


(* ::Subsubsection::Closed:: *)
(*AppPacletInstaller*)



Options[AppPacletUploadInstaller]:=
  Options[PacletUploadInstaller];
AppPacletUploadInstaller[ops:OptionsPattern[]]:=
  PacletUploadInstaller[ops];
AppPacletUploadInstaller[app_,ops:OptionsPattern[]]:=
  PacletUploadInstaller[ops,"ServerName"->app]


(* ::Subsubsection::Closed:: *)
(*AppPacletUninstallerURL*)



Options[AppPacletUninstallerURL]=
  Options@PacletUninstallerURL;
AppPacletUninstallerURL[ops:OptionsPattern[]]:=
  PacletUninstallerURL[ops];
AppPacletUninstallerURL[app_String,ops:OptionsPattern[]]:=
  PacletUninstallerURL[ops,"ServerName"->app];


(* ::Subsubsection::Closed:: *)
(*AppPacletUninstaller*)



Options[AppPacletUploadUninstaller]:=
  Options[PacletUploadUninstaller];
AppPacletUploadUninstaller[ops:OptionsPattern[]]:=
  PacletUploadUninstaller[ops];
AppPacletUploadUninstaller[app_,ops:OptionsPattern[]]:=
  PacletUploadUninstaller[ops,"ServerName"->app]


(* ::Subsubsection::Closed:: *)
(*AppPacletUpload*)



(* ::Text:: *)
(*
	This is pretty much deprecated now, but it shows up in too many spots to kill just yet
*)



Options[AppPacletUpload]=
  DeleteDuplicatesBy[First]@
    Join[
      {
        "PacletFiles"->Automatic,
        "UploadInfo"->Automatic,
        "RebundlePaclets"->True,
        "UploadSiteFile"->True,
        "UploadInstaller"->False,
        "UploadInstallLink"->False,
        "UploadUninstaller"->False
        },
      Options[PacletUpload],
      Options[AppPacletBundle]
      ];
AppPacletUpload[apps__String, ops:OptionsPattern[]]:=
  Replace[OptionValue["UploadInfo"], {
      Automatic:>
        AppPacletUpload[apps,
          "UploadInfo"->
            With[{app=
              If[Length@{apps}>0,
                First@{apps},
                OptionValue@"ServerName"]
              },
              If[StringQ@app,
                Replace[AppPath[app,"Config","UploadInfo.m"],
                  Except[_String?FileExistsQ]:>
                    AppPath[app,"UploadInfo.wl"]
                  ],
                None
                ]
              ],
          ops
          ],
      f:(_String|_File)?FileExistsQ|_URL:>
        AppPacletUpload[apps,
          Sequence@@FilterRules[{ops},
            Except["UploadInfo"]
            ],
          "UploadInfo"->None,
          Replace[Import[f],{
            o:{__?OptionQ}:>
              (Sequence@@
                FilterRules[
                  DeleteCases[o,Alternatives@@Options@AppPacletUpload],
                  Options@AppPacletUpload]),
            _:>(Sequence@@{})
            }]
          ],
      _:>
        With[{
          pacletFiles=
            Replace[OptionValue["PacletFiles"],
              Automatic:>
                If[OptionValue["RebundlePaclets"]//TrueQ,
                  AppPacletBundle[#,
                    FilterRules[{ops},Options@AppPacletBundle]
                    ]&/@{apps},
                  If[FileExistsQ@
                      AppPath[$PacletBuildExtension,#<>".paclet"],
                    AppPath[$PacletBuildExtension,#<>".paclet"],
                    AppPacletBundle[#,
                      FilterRules[{ops},
                        Options@AppPacletBundle
                        ]]
                    ]&/@{apps}
                  ]
              ],
          site=
            Replace[OptionValue["SiteFile"],
              Except[_String?FileExistsQ]:>
                If[Not@FileExistsQ@
                  AppPath[$PacletBuildExtension,
                    First@{apps}<>"-PacletSite.mz"],
                  AppPacletSiteBundle[apps],
                  AppPath[$PacletBuildExtension,
                    First@{apps}<>"-PacletSite.mz"]
                  ]
              ]
          },
          PacletUpload[pacletFiles,
            FilterRules[
              Flatten@{
                "ServerName"->
                  Replace[OptionValue["ServerName"],{
                    Automatic:>First@{apps}
                    }],
                ops,
                "ServerBase"->
                  Replace[OptionValue["ServerBase"],
                    Automatic:>$AppUploadDefault
                    ],
                Options[AppPacletUpload],
                "SiteFile"->site
                },
              Options@PacletUpload
              ]]
          ]
      }];


(* ::Subsubsection::Closed:: *)
(*AppPacletBackup*)



Options[AppPacletBackup]=
  Options[AppPacletUpload];
AppPacletBackup[
  app_,
  server:Automatic|"Cloud"|"GoogleDrive"|"DropBox"|"OneDrive":Automatic,
  ops:OptionsPattern[]
  ]:=
  AppPacletUpload[
    app,
    "ServerBase"->
      Replace[server,
        Automatic:>$AppBackupDefault
        ],
    ops,
    "ServerExtension"->"backups",
    "RemovePaths"->{},
    "RemovePatterns"->".DS_Store",
    "UploadSiteFile"->False,
    "UploadInstaller"->False,
    "UploadUninstaller"->False,
    "UploadInstallLink"->False
    ]


(* ::Subsubsection::Closed:: *)
(*AppPacletDirectoryAdd*)



AppPacletDirectoryAdd[app_]:=
  If[DirectoryQ@AppDirectory[app],  
    PacletDirectoryAdd@AppDirectory[app]
    ];


(* ::Subsubsection::Closed:: *)
(*AppSubpacletUpload*)



Options[AppSubpacletUpload]=
  Join[
    Options@AppPacletUpload,
    Options@AppConfigureSubapp
    ];
AppSubpacletUpload[
  app_:Automatic,
  name:_String|{__String},
  ops:OptionsPattern[]
  ]:=
  With[{
    dir=
      AppConfigureSubapp[app,name,
        FilterRules[{
          ops,
          "PacletInfo"->{
            "Description"->
              TemplateApply["A subpaclet of ``",AppFromFile[app]]
            }
          },
          Options@AppConfigureSubapp
          ]
        ]
    },
    Block[{
      $AppDirectoryRoot=DirectoryName@dir,
      $AppDirectoryName=Nothing,
      appName=FileBaseName@dir
      },
      AppPacletBundle[appName];
      AppPacletUpload[appName,
        FilterRules[{
          ops
          },
          Options@AppPacletUpload
          ]
        ]
      ]
    ];


(* ::Subsubsection::Closed:: *)
(*AppPacletServerPage*)



Options[AppPacletServerPage]=
  Options[PacletServerPage];
AppPacletServerPage[ops:OptionsPattern[]]:=
  PacletServerPage[ops];
AppPacletServerPage[app:Except[_?OptionQ],ops:OptionsPattern[]]:=
  AppPacletServerPage[
    "ServerName"->
      Lookup[
        Association@Flatten@{ops},
        "ServerName",
        AppFromFile@app
        ],
    ops
    ];


End[];



