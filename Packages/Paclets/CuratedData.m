(* ::Package:: *)

(************************************************************************)
(* This file was generated automatically by the Mathematica front end.  *)
(* It contains Initialization cells from a Notebook file, which         *)
(* typically will have the same name as this file except ending in      *)
(* ".nb" instead of ".m".                                               *)
(*                                                                      *)
(* This file is intended to be loaded into the Mathematica kernel using *)
(* the package loading commands Get or Needs.  Doing so is equivalent   *)
(* to using the Evaluate Initialization Cells menu command in the front *)
(* end.                                                                 *)
(*                                                                      *)
(* DO NOT EDIT THIS FILE.  This entire file is regenerated              *)
(* automatically each time the parent Notebook file is saved in the     *)
(* Mathematica front end.  Any changes you make to this file will be    *)
(* overwritten.                                                         *)
(************************************************************************)



CuratedDataExport::usage=
	"Exports an EntityStore as a CuratedData function backed by DataPaclets";


Begin["`Private`"];


(* ::Subsubsection::Closed:: *)
(*Constants*)



dataPacletIndexNumber[padLength_,num_Integer]:=
	StringPadLeft[ToString@num,padLength,"0"];
dataPacletIndexNumber[padLength_,{num_Integer}]:=
	dataPacletIndexNumber[padLength,num];
dataPacletIndexNumber[num_]:=
	dataPacletIndexNumber[$dataPacletPartitionNumber,num];


$dataPacletVersionNumber="1.0.0";


(* ::Subsubsection::Closed:: *)
(*IndexPaclet*)



dataPacletIndexFile[
	dir:_String?DirectoryQ|Automatic:Automatic,
	dataType_String,
	entityStore:_Association|{__Association}
	]:=
	With[{
		index=
			{
				"Sources"->
					{
						"Data"->
							If[AssociationQ@entityStore,
								{
								"Part01"->
									Keys@
										entityStore["Entities"]
										},
								MapIndexed[
									"Part"<>dataPacletIndexNumber[#2]->
										Keys@#["Entities"]&,
									entityStore
									]
								]
						},
				"Properties"->
					{
						"Data"->
							Thread@List@
								DeleteCases["Label"]@
									Keys@
										If[AssociationQ@entityStore,
											entityStore,
											First@entityStore
											]["Properties"]
						}
				}
		},
		Export[
			FileNameJoin@{
				Replace[dir,
					Automatic:>
						$TemporaryDirectory
					],
				StringTrim[dataType,"Data"]<>"Data_Index",
				"Data",
				"Index.wdx"
				},
			index,
			"DataIndex"
			]
		];


dataPacletNamesIndexFile[
	dir_,
	dataType_String,
	entityStore_Association
	]:=
	With[{
		names=
			Normal@
				AssociationMap[
					{#,First@StringSplit[#,"::"]}&,
					Flatten@{
						Keys@entityStore["Entities"],
						Lookup[
							Values@entityStore["Entities"],
							"AlternateNames",
							{}
							]
						}
					]
		},
		Export[
			FileNameJoin@{
				Replace[dir,
					Automatic:>
						$TemporaryDirectory
					],
				StringTrim[dataType,"Data"]<>"Data_Index",
				"Data",
				"Names.wdx"
				},
			names
			]
		];


dataPacletEntitiesIndexFile[
	dir_,
	dataType_String,
	entityStore_Association
	]:=
	Export[
		FileNameJoin@{
			Replace[dir,
				Automatic:>
					$TemporaryDirectory
				],
			StringTrim[dataType,"Data"]<>"Data_Index",
			"Data",
			"Entities.wdx"
			},
		Compress@
			Map[
				Hash[#,"Adler32"]->#&,
				Keys@entityStore["Entities"]
				]
		];


dataPacletPropertiesIndexFile[
	dir_,
	dataType_String,
	entityStore_Association
	]:=
	With[{
		properties=
			Thread@List@
				DeleteCases["Label"]@
					Keys@entityStore["Properties"]
		},
		Export[
			FileNameJoin@{
				Replace[dir,
					Automatic:>
						$TemporaryDirectory
					],
				StringTrim[dataType,"Data"]<>"Data_Index",
				"Data",
				"Properties.wdx"
				},
			Compress@{"Data"->properties}
			];
		]


dataPacletFunctionsIndexFile[
	dir_,
	dataType_String,
	entityStore_Association
	]:=
	With[{
		functions=
			With[{computeFunction=
				Symbol@Evaluate["DataPaclets`"<>StringTrim[dataType,"Data"]<>"DataDump`ComputeFunction"]
				},
			Normal@
				ReplacePart[#,
					"Helpers":>
						(
							Normal@GroupBy[First->Last]@Flatten@#["Helpers"]
							)
					]&@
			Join[
				<|
					"Primary"->{},
					"Helpers"->{}
					|>,
				GroupBy[First->Last]@
					Replace[
						Lookup[entityStore,"Functions",{}],{
							(Verbatim[HoldPattern][p___]:>f_):>
								"Primary"->
									(
										HoldPattern[computeFunction[p]]:>f
											),
							s_Symbol:>
								With[{key=
									SymbolName@Unevaluated@s
									},
									"Helpers"->
										{
											"OwnValues"->
												(key->OwnValues[s]),
											"DownValues"->
												(key->DownValues[s]),
											"UpValues"->
												(key->UpValues[s]),
											"SubValues"->
												(key->SubValues[s])
											}
									]
						}]
				]
			]
		},
		Export[
			FileNameJoin@{
				Replace[dir,
					Automatic:>
						$TemporaryDirectory
					],
				StringTrim[dataType,"Data"]<>"Data_Index",
				"Data",
				"Functions.wdx"
				},
			Compress@functions
			];
		]


dataPacletGroupsIndexFile[
	dir_,
	dataType_String,
	entityStore_Association
	]:=
	With[{
		groups=
			Replace[entityStore["EntityClasses"],{
				l_List:>
					Normal[Keys/@l],
				_->{}
				}]
		},
		Export[
			FileNameJoin@{
				Replace[dir,
					Automatic:>
						$TemporaryDirectory
					],
				StringTrim[dataType,"Data"]<>"Data_Index",
				"Data",
				"Groups.wdx"
				},
			Compress@groups
			];
		]


dataPacletPrivateGroupsIndexFile[
	dir_,
	dataType_String,
	entityStore_Association
	]:=
	Export[
		FileNameJoin@{
			Replace[dir,
				Automatic:>
					$TemporaryDirectory
				],
			StringTrim[dataType,"Data"]<>"Data_Index",
			"Data",
			"PrivateGroups.wdx"
			},
		Compress@{}
		];


dataPacletDataFile[
	n:_Integer:1,
	dir_,
	dataType_String,
	entityStore_Association
	]:=
	With[{
		ents=
			{
				"Keys"->
					Keys@entityStore["Entities"],
				"Properties"->
					Thread@List@
						DeleteCases["Label"]@
							Keys@entityStore["Properties"],
				"Data"->
					Map[
						Replace[
							Lookup[#,
								DeleteCases["Label"]@
									Keys@entityStore["Properties"]
								],
							_Missing->Missing["NotAvailable"],
							1]&,
						entityStore["Entities"]
						],
				"Attributes"->
					{
						"CreationDate"->DateList[],
						"Signature"->228610809693471781814095222429607185306
						}
				}
		},
		Quiet@
			CreateDirectory@
				FileNameJoin@{
					Replace[dir,
						Automatic:>
							$TemporaryDirectory
						],
					StringTrim[dataType,"Data"]<>"Data_Part"<>	
						StringPadLeft[ToString@n,2,"0"],
					"Data"
					};
		Export[
			FileNameJoin@{
				Replace[dir,
					Automatic:>
						$TemporaryDirectory
					],
				StringTrim[dataType,"Data"]<>"Data_Part"<>StringPadLeft[ToString@n,2,"0"],
				"Data",
				"Part"<>dataPacletIndexNumber[n]<>".wdx"
				},
			ents,
			"DataTable"
			];
		];


CuratedDataIndexPaclet[
	dir:_String?DirectoryQ|Automatic:Automatic,
	dataType_String,
	entityStore_Association,
	pack:True|False:True
	]:=
	CompoundExpression[
		Begin["DataPaclets`CuratedDataFormattingDump`"],
		(End[];#)&@
		CheckAbort[
			Block[{
				partitions=
					Map[
						ReplacePart[entityStore,
							"Entities"->
								Association@#
							]&
						]@
						Partition[
							Normal@entityStore["Entities"],
							UpTo[
									Floor[Length@entityStore["Entities"]/
									Ceiling[ByteCount[entityStore["Entities"]]/(5*10^7)]]
									]
							],
				$dataPacletPartitionNumber
				},
				$dataPacletPartitionNumber=
					Max@{
						Length@IntegerDigits@Length@partitions,
						2
						};
				(* ------- Prep Directories  ------- *)
				Quiet@
					CreateDirectory[
						FileNameJoin@{
							Replace[dir,	
								Automatic:>
									$TemporaryDirectory
								],
							StringTrim[dataType,"Data"]<>"Data_Index",
							"Data"
							},
						CreateIntermediateDirectories->True
						];
				(* ------- Indices -------*)
				dataPacletIndexFile[
					dir,
					dataType,
					partitions
					];
				dataPacletNamesIndexFile[dir,dataType,entityStore];
				dataPacletEntitiesIndexFile[dir,dataType,entityStore];
				dataPacletPropertiesIndexFile[dir,dataType,entityStore];
				dataPacletFunctionsIndexFile[dir,dataType,entityStore];
				dataPacletGroupsIndexFile[dir,dataType,entityStore];
				dataPacletPrivateGroupsIndexFile[dir,dataType,entityStore];
				(* ------- Data ------- *)
				MapIndexed[
					Function[
						Quiet@
							CreateDirectory[
								FileNameJoin@{
									Replace[dir,	
										Automatic:>
											$TemporaryDirectory
										],
									StringTrim[dataType,"Data"]<>
										"Data_Part"<>
											dataPacletIndexNumber[#2],
									"Data"
									},
								CreateIntermediateDirectories->True
								];
						dataPacletDataFile[First@#2,
							dir,
							StringTrim[dataType,"Data"],
							#
							]
						],
					partitions
					];
				(* ------- Paclets  ------- *)
				If[pack,
					Quiet@
						PacletExpressionBundle[
							FileNameJoin@{
								Replace[dir,
									Automatic:>
										$TemporaryDirectory
									],
								StringTrim[dataType,"Data"]<>"Data_Index"
								},
							"Version"->$dataPacletVersionNumber
							];
					Map[
						Quiet@
							PacletExpressionBundle[
								FileNameJoin@{
									Replace[dir,
										Automatic:>
											$TemporaryDirectory
										],
									StringTrim[dataType,"Data"]<>"Data_Part"<>
										dataPacletIndexNumber[#]
									},
								"Version"->
									$dataPacletVersionNumber
								]&,
						Range[Length@partitions]
						];
					AssociationMap[
						PacletBundle@
							FileNameJoin@{
								Replace[dir,
									Automatic:>
										$TemporaryDirectory
									],
								StringTrim[dataType,"Data"]<>"Data_"<>#
								}&,
						Flatten@{
							"Index",
							Map[
								"Part"<>dataPacletIndexNumber[#]&,
								Range[Length@partitions]
								]
							}],
					<|
						"Index"->
							FileNameJoin@{
								Replace[dir,
									Automatic:>
										$TemporaryDirectory
									],
								StringTrim[dataType,"Data"]<>"Data_Index"
								},
						"Data"->
							Map[
								FileNameJoin@{
									Replace[dir,
										Automatic:>
											$TemporaryDirectory
										],
									StringTrim[dataType,"Data"]<>"Data_Part"<>dataPacletIndexNumber[#]
									}&,
								Range[Length@partitions]
								]
						|>
					]
				],
			End[]
			]
		];


(* ::Subsubsection::Closed:: *)
(*Package*)



$CuratedDataPackageTemplate:=
	Import[
		PackageFileName[
			"Packages",
			"__Templates__",
			"CuratedData",
			"$CuratedData.m"],
		"Text"
		];


CuratedDataPaclet[
	dir:_String?DirectoryQ|Automatic:Automatic,
	dataType_String,
	entityStore_Association,
	pack:True|False:True,
	ops:(_String->_String)...
	]:=
	With[{
		file=
			With[{d=
				FileNameJoin@{
					Replace[dir,
						Automatic:>
							$TemporaryDirectory
						],
					StringTrim[dataType,"Data"]<>"Data"
					}
				},
				Quiet@
					CreateDirectory[
						FileNameJoin@{d,"AutoCompletionData"},
						CreateIntermediateDirectories->True
						];
				FileNameJoin@{
					d,
					StringTrim[dataType,"Data"]<>"Data.m"
					}
				]
		},
			(* --------- Package --------- *)
			With[{fob=OpenWrite@file},
				(WriteString[fob,#];Close@fob)&@
					StringReplace[$CuratedDataPackageTemplate,{
						ops,
						"$CuratedDataProperties"->
							ToString[
								DeleteCases["Label"]@
									Keys@entityStore["Properties"],
								InputForm
								],
						"$CuratedDataLabelFunction"->
							ToString[
								Replace[
									Lookup[
										Lookup[
											entityStore["Properties"],
											"Label",
											<||>
											],
										"DefaultFunction"
										],{
									_Missing|CommonName->CanonicalName
									}],
								InputForm
								],
						"$CuratedDataDefaultProperty"->
							ToString[
								Lookup[
									entityStore,
									"DefaultProperty",
									"Entity"
									],
								InputForm
								],
						"$CuratedDataType"->dataType,
						"$CuratedData"->StringTrim[dataType,"Data"]<>"Data"
						}
					]
				];
				
			(* --------- Autocompletions --------- *)
			Export[
				FileNameJoin@{
					Replace[dir,
						Automatic:>
							$TemporaryDirectory
						],
					StringTrim[dataType,"Data"]<>"Data",
					"AutoCompletionData",
					"specialArgFunctions.tr"
					},
				StringReplace[
					Import[
						PackageFileName[
							"Packages",
							"__Templates__",
							"CuratedData",
							"$CuratedDataCompletions.tr"
							],
						"Text"
						],
					{
						"$CuratedDataEntities"->
							ToString[
								Function[
									DeleteDuplicates@
										Join[
											Map[First@StringSplit[#,"::"]&,#],
											#]
									]@
									SortBy[
										Keys@entityStore["Entities"],
										StringLength
										],
								InputForm
								],
						"$CuratedDataProperties"->
							ToString[
								SortBy[
									DeleteCases["Label"]@
										Keys@entityStore["Properties"],
									StringLength
									],
								InputForm
								],
						"$CuratedData"->StringTrim[dataType,"Data"]<>"Data"
						}],
				"Text"
				];
			If[pack,
				(
					PacletExpressionBundle[#,"Version"->$dataPacletVersionNumber];
					PacletBundle[#]
					)&@
					FileNameJoin@{
						Replace[dir,
							Automatic:>
								$TemporaryDirectory
							],
						StringTrim[dataType,"Data"]<>"Data"
						},
				FileNameJoin@{
						Replace[dir,
							Automatic:>
								$TemporaryDirectory
							],
						StringTrim[dataType,"Data"]<>"Data"
						}
				]
		]


(* ::Subsubsection::Closed:: *)
(*Wrapper*)



$CuratedDataWrapperPackageTemplate:=
	Import[
		PackageFileName[
			"Packages",
			"__Templates__",
			"CuratedData",
			"$CuratedDataWrapper.m"],
		"Text"
		];


CuratedDataWrapperPaclet[
	dir:_String?DirectoryQ|Automatic:Automatic,
	dataType_String,
	dataFunctions_Association,
	pack:True|False:True,
	ops:(_String->_String)...
	]:=
	With[{
		file=
			With[{d=
				FileNameJoin@{
					Replace[dir,
						Automatic:>
							$TemporaryDirectory
						],
					StringTrim[dataType,"Data"]<>"Data"
					}
				},
				Quiet@
					CreateDirectory[
						FileNameJoin@{d,"AutoCompletionData"},
						CreateIntermediateDirectories->True
						];
				FileNameJoin@{
					d,
					StringTrim[dataType,"Data"]<>"Data.m"
					}
				]
		},
			(* --------- Package --------- *)
			With[{fob=OpenWrite@file},
				(WriteString[fob,#];Close@fob)&@
					StringReplace[$CuratedDataWrapperPackageTemplate,{
						ops,
						"$CuratedDataFunctions"->
							Block[{$Context="System`",$ContextPath={"System`"}},
								ToString[
									dataFunctions,
									InputForm
									]
								],
						"$CuratedDataType"->dataType,
						"$CuratedData"->StringTrim[dataType,"Data"]<>"Data"
						}
					]
				];
				
			(* --------- Autocompletions --------- *)
			Export[
				FileNameJoin@{
					Replace[dir,
						Automatic:>
							$TemporaryDirectory
						],
					StringTrim[dataType,"Data"]<>"Data",
					"AutoCompletionData",
					"specialArgFunctions.tr"
					},
				StringReplace[
					Import[
						PackageFileName[
							"Packages",
							"__Templates__",
							"CuratedData",
							"$CuratedDataCompletions.tr"
							],
						"Text"
						],
					{
						"$CuratedDataEntities"->
							ToString[
								Keys@dataFunctions,
								InputForm
								],
						"$CuratedData"->StringTrim[dataType,"Data"]<>"Data"
						}],
				"Text"
				];
			If[pack,
				(
					PacletExpressionBundle[#,"Version"->$dataPacletVersionNumber];
					PacletBundle[#]
					)&@
					FileNameJoin@{
						Replace[dir,
							Automatic:>
								$TemporaryDirectory
							],
						StringTrim[dataType,"Data"]<>"Data"
						},
				FileNameJoin@{
						Replace[dir,
							Automatic:>
								$TemporaryDirectory
							],
						StringTrim[dataType,"Data"]<>"Data"
						}
				]
		]


(* ::Subsubsection::Closed:: *)
(*Export*)



CuratedDataExport[
	dir:_String?DirectoryQ|Automatic:Automatic,
	dataType_String,
	entityStore:_Association?(
		Function[a,AllTrue[{"Entities","Properties"},KeyMemberQ[a,#]&]]
		),
	pack:True|False:True
	]:=
	 Prepend[
	 	"Package"->
	 		CuratedDataPaclet[dir,
	 			dataType,
	 			entityStore,
	 			pack,
	 			"$CuratedDataDefaultProperty"->
	 				Lookup[entityStore,
	 					"DefaultProperty",
	 					(*First@DeleteCases["Label"]@
	 						Keys@entityStore["Properties"]*)
	 					"Entity"
	 					]
	 			]
	 		]@
		 	CuratedDataIndexPaclet[dir,
		 		dataType,
		 		entityStore,
		 		pack
		 		];
CuratedDataExport[
	dir:_String?DirectoryQ|Automatic:Automatic,
	name:_String|None:None,
	datasets_Association?(
		AllTrue[Values@#,
			With[{a=#},
				AllTrue[{"Entities","Properties"},
					KeyMemberQ[a,#]&
					]
				]&
			]&),
	pack:True|False:True
	]:=
	If[name===None,
		Identity,
		Prepend[
			name->
				CuratedDataWrapperPaclet[dir,
					name,
					AssociationThread[
						StringTrim[
							Replace[Keys@datasets,
								s_Symbol:>SymbolName[s],
								1
								],
							name
							],
						Replace[Keys@datasets,
							s_String:>
								ToExpression[
									StringTrim[s,"Data"]<>"Data"<>"`"<>
										StringTrim[s,"Data"]<>"Data"],
							1
							]
						],
					pack
					]
			]
		]@
		Association@
			KeyValueMap[
				#->
					CuratedDataExport[dir,#,#2,pack]&,
				datasets
				];
CuratedDataExport[
	dir:_String?DirectoryQ|Automatic:Automatic,
	name:_String|None:None,
	entityStore_EntityStore,
	pack:True|False:True
	]:=
	CuratedDataExport[
		dir,
		name,
		entityStore[[1,"Types"]],
		pack
		];


End[];


