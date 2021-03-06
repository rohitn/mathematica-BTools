(* ::Package:: *)

(* Autogenerated Package *)

(* ::Text:: *)
(*Layer on top of lower-level clumsier implementation*)



$PacletExecuteSettings::usage=
  "Settings for PacletExecute and PacletTools";
PacletExecute::usage=
  "Wrapper for all paclet actions";


PackageScopeBlock[
  $PacletExecuteExpressionMethods::usage="internal";
  $PacletExecuteSiteMethods::usage="";
  $PacletExecuteUploadMethods::usage="";
  PacletExecuteSettingsLookup::usage=
    "Lookup on the $PacletExecuteSettings"
  ]


Begin["`Private`"];


PacletExecuteSettingsLookup[key_]:=
  Lookup[$PacletExecuteSettings, key];
PacletExecuteSettingsLookup[key_, default_]:=
  Lookup[$PacletExecuteSettings, key, default];
PacletExecuteSettingsLookup~SetAttributes~HoldRest


(* ::Subsubsection::Closed:: *)
(*Settings*)



If[!AssociationQ@$PacletExecuteSettings,
  $PacletExecuteSettings=
    <|
      "BuildRoot"->
        $TemporaryDirectory,
      "BuildExtension"->
        "_paclets",
      "ClearBuildCacheOnLoad"->
        True,
      "ServerDefaults":>
        <|
          "ServerBase"->
            $WebSiteDirectory,
          "ServerExtension"->
            Nothing,
          "ServerName"->
            "PacletServer",
          Permissions->
            "Public",
          CloudConnect->
            "PacletsAccount"
          |>,
      "ServerBase"->CloudObject,
      "UseKeychain"->False,
      "FormatPaclets"->False,
      "FilePattern"->
        (_String|_URL|_File|_PacletManager`Paclet)|
        (
          (_String|_PacletManager`Paclet)->
            (_String|_URL|_File|_PacletManager`Paclet)
          ),
      "UploadPattern"->
        (_String|_URL|_File|{_String,_String}|_PacletManager`Paclet)|
          Rule[
            _String|_PacletManager`Paclet,
            (_String|_URL|_File|{_String,_String}|_PacletManager`Paclet)
            ],
      "RemovePattern"->
        {_String,_String}|PacletManager`Paclet|_String
      |>
    ]


If[$pacletConfigLoaded//TrueQ//Not,
  Replace[
    SelectFirst[
      PackageFilePath["Private", "Config", "PacletConfig."<>#]&/@{"m","wl"},
      FileExistsQ
      ],
      f_String:>Get@f
    ]
  ];
$pacletConfigLoaded=True


(* ::Subsubsection::Closed:: *)
(*PacletExecute*)



$PacletExecuteExpressionMethods=
  <|
    "Paclet"->
      PacletInfo,
    "Association"->
      PacletInfoAssociation,
    "GeneratePacletExpression"->
      PacletInfoExpression,
    "GeneratePacletInfo"->
      PacletInfoGenerate,
    "AutoGeneratePaclet"->
      PacletAutoPaclet,
    "Bundle"->
      PacletBundle,
    "Lookup"->
      PacletLookup,
    "Open"->
      PacletOpen,
    "InstalledQ"->
      PacletInstalledQ,(*
		"ExistsQ"->
			PacletExistsQ,*)
    "FindDirectory"->
      PacletDirectoryFind,
    "ValidDirectoryQ"->
      PacletDirectoryQ,
    "SetFormatting"->
      SetPacletFormatting
    |>;


$PacletExecuteSiteMethods=
  <|
    "PacletSite"->
      PacletSiteInfo,
    "URL"->
      PacletSiteURL,
    "SiteDataset"->
      PacletSiteInfoDataset,
    "SiteFromDataset"->
      PacletSiteFromDataset,
    "BundleSite"->
      PacletSiteBundle
    |>;


$PacletExecuteUploadMethods=
  <|
    "Upload"->
      PacletUpload,
    "Remove"->
      PacletRemove,
    "SiteUpload"->
      PacletSiteUpload,
    "APIUpload"->
      PacletAPIUpload,
    "Install"->
      PacletInstallPaclet,
    "Download"->
      PacletDownloadPaclet,
    "FindPacletFile"->
      PacletFindBuiltFile
    |>;


$PacletExecuteMethods=
  Join[
    $PacletExecuteExpressionMethods,
    $PacletExecuteSiteMethods,
    $PacletExecuteUploadMethods
    ]


PacletExecute//Clear


(* ::Text:: *)
(*
	This is handles the discovery stuff
*)



PacletExecute[
  method_?(KeyExistsQ[$PacletExecuteMethods, #]&),
  Optional["Function", "Function"]
  ]:=
  $PacletExecuteMethods[method];
PacletExecute[
  method_?(KeyExistsQ[$PacletExecuteMethods, #]&),
  "Options"
  ]:=
  Options@Evaluate@$PacletExecuteMethods[method];


(* ::Text:: *)
(*
	This is the interface for all the basic stuff
*)



$PacletExpressionPatterns=
  _String|{_String, _String}|_PacletManager`Paclet|{__PacletManager`Paclet};
PacletExecute[
  method_?(KeyExistsQ[$PacletExecuteExpressionMethods, #]&),
  pac:_?(MatchQ[$PacletExpressionPatterns]),
  args___
  ]:=
  With[{fn=$PacletExecuteExpressionMethods[method]},
    With[{res=fn[pac, args]},
      res/;Head[res]=!=fn
      ]
    ];


(* ::Text:: *)
(*
	This is the interface for all the site stuff
*)



PacletExecute[
  method_?(KeyExistsQ[$PacletExecuteSiteMethods, #]&),
  pac:Except[_?OptionQ]...(*_?(MatchQ[$PacletFilePatterns])|None:None*),
  args___?OptionQ
  ]:=
  With[{fn=$PacletExecuteSiteMethods[method]},
    With[{res=fn[pac, args]},
      res/;Head[res]=!=fn
      ]/;pac=!=None||Length@{args}>0
    ];


(* ::Text:: *)
(*
	This does the upload stuff
*)



PacletExecute[
  method_?(KeyExistsQ[$PacletExecuteUploadMethods, #]&),
  pac:_?(MatchQ[$PacletUploadPatterns]),
  args___
  ]:=
  With[{fn=$PacletExecuteUploadMethods[method]},
    With[{res=fn[pac, args]},
      res/;Head[res]=!=fn
      ]
    ];


PackageAddAutocompletions[
  "PacletExecute",
  {
    Keys@$PacletExecuteMethods,
    Join[
      {"Function", "Options"},
      AppNames[]
      ]
    }
  ]


End[];



