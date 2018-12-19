(* ::Package:: *)

(* Autogenerated Package *)

PartialDirectoryCopy::usage="";
CopyDirectoryFiles::usage="";
PruneDirectoryFiles::usage="";


Begin["`Private`"];


(* ::Subsubsection::Closed:: *)
(*PartialDirectoryCopy*)



Options[PartialDirectoryCopy]=
  {
    "RemovePaths"->{},
    "RemovePatterns"->{},
    "ModeSwitchByteCount"->5*10^6
    };
PartialDirectoryCopy[src_, targ_, ops:OptionsPattern[]]:=
  Module[
    {
      rempaths=
        Select[
          Flatten@{OptionValue["RemovePaths"]},
          StringPattern`StringPatternQ
          ],
      rempatts=
        Select[
          Flatten@{OptionValue["RemovePatterns"]},
          StringPattern`StringPatternQ
          ],
      fullFNames,
      fileBytesTotal,
      remFiles,
      restFiles
      },
    If[Length@Join[rempaths, rempatts]>0,
      fullFNames=FileNames["*", src, \[Infinity]];
      remFiles=
        Join[
          FileNames[rempaths, src],
          FileNames[rempatts, src, \[Infinity]]
          ];
      restFiles=
        Select[
          Complement[
            fullFNames,
            remFiles
            ],
          Not@*StringStartsQ[Alternatives@@remFiles]
          ];
      fileBytesTotal=
        Total[FileByteCount/@Select[remFiles, Not@*DirectoryQ]];
      Quiet@DeleteDirectory[targ, DeleteContents->True];
      If[TrueQ[fileBytesTotal>OptionValue["ModeSwitchByteCount"]],
        CopyDirectoryFiles[src, targ, 
          getMinimalFileModSpec[restFiles, fullFNames]
          ],
        CopyDirectory[src, targ];
        PruneDirectoryFiles[targ, 
          StringTrim[
            getMinimalFileModSpec[remFiles, fullFNames, False],
            src
            ]
          ]
        ],
      If[True(*OptionValue@OverwriteTarget//TrueQ*),
        Quiet@DeleteDirectory[targ, DeleteContents->True];
        ];
      CopyDirectory[src, targ]
      ]
    ];


(* ::Subsubsection::Closed:: *)
(*getMinimalFileModSpec*)



getMinimalFileModSpec[
  restFiles_, 
  files_,
  pruneEmpties:True|False:True
  ]:=
  Module[
    {
      g1=GroupBy[restFiles, DirectoryName],
      g2=GroupBy[files, DirectoryName],
      unchangedReduction,
      changedReduction,
      containedReduction,
      keys,
      changedKeys,
      missingDirs,
      baseSpec,
      deadDirs
      },
    (* all the directories are keys in the Associations optimally *)
    g1=Select[Not@*DirectoryQ]/@g1;
    deadDirs=Complement[Select[restFiles, DirectoryQ], Keys@g1];
    g2=Select[Not@*DirectoryQ]/@g2;
    (* figures out which directories may be copied across wholesale *)
    unchangedReduction=
      AssociationMap[
        #[[1]]->
          If[
            !ListQ@g2[#[[1]]]||
              (
                (*Length@#[[2]]>0&&*)(* this test needs to come at the *very* end I think... *)
                Length@Complement[Flatten@{g2[#[[1]]]}, #[[2]]]==0
                ),
            #[[1]],
            #[[2]]
            ]&,
        g1
        ];
    missingDirs=
      AssociationThread[
        Complement[Keys@g2, Keys@g1],
        0
        ];
    containedReduction=
      FixedPoint[
        KeySelect[
          (* 
					checks if both the child *and* the parent are unchanged *and* 
						if there's nothing missing vis-a-vis the original 
					*)
          !StringQ@unchangedReduction[#]||
            !StringQ@unchangedReduction[DirectoryName[#]]||
            KeyExistsQ[missingDirs, DirectoryName[#]]||
            AnyTrue[Keys@missingDirs, StringStartsQ[DirectoryName[#]]]&
          ],
        unchangedReduction
        ];
    keys=Keys@containedReduction;
    changedKeys=
      Select[keys, !AnyTrue[keys, StringMatchQ[#~~__]&]];
    baseSpec=
      Flatten@Values@
          KeyDrop[containedReduction, changedKeys];
    If[pruneEmpties,
      (* makes sure we're not pulling directories with no stuff to copy *)
      Select[
        !DirectoryQ[#]||
          Length@g1[#]>0||
          AnyTrue[
            Flatten@Values@KeySelect[g1, StringStartsQ[#]], 
            !DirectoryQ
            ]&
        ],
      Union[#, deadDirs]&
      ]@baseSpec
    ]


(* ::Subsubsection::Closed:: *)
(*CopyDirectoryFiles*)



CopyDirectoryFiles[src_, targ_, files_]:=
  (
    MapThread[
      Which[
        DirectoryQ@#, 
          If[!DirectoryQ@DirectoryName[#2], 
            CreateDirectory[#2, CreateIntermediateDirectories->True]
            ];
          CopyDirectory[#, #2],
        FileExistsQ@#,
          If[!DirectoryQ@DirectoryName[#2], 
            CreateDirectory[DirectoryName[#2], CreateIntermediateDirectories->True]
            ];
          CopyFile[#, #2, OverwriteTarget->True]
        ]&,
      {
        files,
        Map[FileNameJoin@{targ, #}&, StringTrim[files, src]]
        }
      ];
      )


(* ::Subsubsection::Closed:: *)
(*PruneDirectoryFiles*)



PruneDirectoryFiles[targ_, files_]:=
  (
    Which[
      DirectoryQ@#, 
        DeleteDirectory[#, DeleteContents->True],
      FileExistsQ@#,
        DeleteFile[#]
      ]&/@Map[FileNameJoin@{targ, #}&, files];
    )


End[];



