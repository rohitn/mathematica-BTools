(* ::Package:: *)



$TitleCellStyles::usage="The styles that are section-like";
$SectionCellStyles::usage="The styles that are section-like";
$IOCellStyles::usage="The styles that are code-like";
$TextCellStyles::usage="The styles that are text-like";
$DefaultStyleNotebook::usage=
	"Default.nb hidden notebook";
SystemStyleNotebook::usage=
	"Finds the notebook for a given stylesheet";


$SSCellDisplayStyleOptions::usage=
	"A listing of cell style options to make two cells look the same";


SSOpen::usage="Opens the style definitions notebook for a given notebook";
SSTemplate::usage=
	"Creates a stylesheet editing template
-Create in the current document by default
-Opens a new one when passed Notebook[<ssname>] as the first argument";
SSNew::usage=
	"Creates a new style cell with a given name and optional parent style and options";
SSDelete::usage="Deletes all matching style cells";
SSUpdate::usage="SSDelete + SSNew";


SSDefaultStyles::usage="Sets a default styling cascade";


SSCells::usage=
	"Gets the cells in the current stylesheet that match a given style.
Styles can be specified by a String, Symbol, or StyleData expression or a list thereof";


(*StylesheetNotebook::usage=
	"Finds the stylesheet notebook expression the given notebook depends on";*)


SSEditNotebook::usage=
	"The style notebook object for editing a given notebook";
SSNotebookObject::usage=
	"Gets the NotebookObject that stores the styles of a given NotebookObject";
SSNotebookGet::usage=
	"Gets the NotebookObject the stores the styles of a given NotebookObject";
SSStyles::usage=
	"Gets the styles from a stylesheet";


SSApplyEdits::usage=
	"Applies the edits from SSEdit";
SSEdit::usage="Applies the options given to the given cell styles in the given notebook";
SSDrop::usage"Drops the options given from the given cell styles in the given notebook";
SSValue::usage=
	"Gets the value of a style option for a cell style";
SSSync::usage="Copies style options from one style to another";


SSEditEvents::usage=
	"Edits the \[Star]EventActions";
SSEditAliases::usage=
	"Edits the InputAliases";
SSEditAutoReplacements::usage=
	"Edits the InputAutoReplacements";
SSEditTaggingRules::usage=
	"Edits the TaggingRules";


Begin["`Private`"];


If[!ValueQ[$frontEndExecuteBlock],
	$frontEndExecuteBlock=False;
	$frontEndExecuteBlock//Protect
	]


frontEndExecuteSow[e_]:=
	Sow[e, "FrontEndExecute"];
frontEndExecuteRouter[a_,b_]:=
	If[$frontEndExecuteBlock,
		frontEndExecuteSow[a],
		b
		];
frontEndExecuteRouter~SetAttributes~HoldAllComplete;
frontEndExecuteBlock[e_]/;!TrueQ[$frontEndExecuteBlock]:=
	Block[{$frontEndExecuteBlock=True},
		With[{rd=Reap[e,"FrontEndExecute"]},
			Replace[rd[[2]],
				{a:{__}}:>
					If[MemberQ[a, _Hold],
						MathLink`CallFrontEndHeld@@
							Append[
							 Thread[Replace[a, h:Except[_Hold]:>Hold[h]],Hold],
							 System`FrontEndDump`NoResult
							 ],
						MathLink`CallFrontEnd[a, System`FrontEndDump`NoResult]
						]
				];
			rd[[1]]
			]
		];
frontEndExecuteBlock[e_]/;TrueQ[$frontEndExecuteBlock]:=e;
frontEndExecuteBlock~SetAttributes~HoldAllComplete;


$TitleCellStyles={"Title","Chapter","Subchapter"};
$SectionCellStyles={"Section","Subsection","Subsubsection","Subsubsubsection"};
$IOCellStyles={"Input","Code","Output"};
$TextCellStyles={"Text","Item","ItemParagraph","Subitem","SubitemParagraph"};


$SSCellTextStyleOptions=
	{
		FontSize,
		FontColor,
		FontSlant,
		FontWeight,
		TabSpacings
		};


Quiet[
	System`CellFrameStyle;
	System`GroupOpenerColor;
	System`GroupOpenerInsideFrame;,
	General::shdw
	]


$SSCellFrameStyleOptions=
	{
		CellFrame,
		Background,
		CellFrameColor,
		System`CellFrameStyle
		};


$SSCellSpacingStyleOptions=
	{
		CellMargins,
		CellFrameMargins
		};


$SSCellDisplayStyleOptions:=
	Join[
		$SSCellTextStyleOptions,
		$SSCellFrameStyleOptions,
		$SSCellSpacingStyleOptions
		];


SystemStyleNotebook[parts___String,name_String]:=
	Replace[
		FileNameJoin@Flatten@{
			$InstallationDirectory,
			"SystemFiles","FrontEnd","StyleSheets",
			parts,name<>".nb"
			},{
		f_String?FileExistsQ:>
			Replace[FENotebooks@f,{
				{}->Missing["NotFound"],
				{nb_}:>nb
				}],
		_->Missing["FileNotFound"]
		}];


$DefaultStyleNotebook:=
SystemStyleNotebook["Default"]


ssFileNameJoin[args__]:=
	FileNameJoin@Flatten@{$FrontEndDirectory,"StyleSheets",args}


ssFileName@FrontEnd`FileName[baseComponents_List,base_,___]:=
	If[FileExistsQ@FileNameJoin@Append[baseComponents,base],
		FileNameJoin@Append[baseComponents,base],
		If[FileExistsQ@ssFileNameJoin[baseComponents,base],
			ssFileNameJoin[baseComponents,base],
			First@FrontEndFiles@
				FileNameJoin@Flatten@{baseComponents,base}
			]
		];
ssFileName[base:_String?(Not@*FileExistsQ)|{__String}]:=
	If[FileExistsQ@ssFileNameJoin[base],
		ssFileNameJoin[base],
		Replace[
			FrontEndExecute@
				FrontEnd`FindFileOnPath[
					FileNameJoin@Flatten@{base},
					"StyleSheetPath"
					],{
			s_String:>
				FileNameJoin@Flatten@{s,"FrontEnd","StyleSheets",base}
			}]
		];


SSNotebookFileName[nb_NotebookObject]:=
	Replace[CurrentValue[nb,StyleDefinitions],{
		f:_String|_FrontEnd`FileName:>
			ssFileName[f],
		_Notebook:>
			Missing["NotAvailable"]
		}];


If[!AssociationQ@$ssNbObjCache,
	$ssNbObjCache=<||>
	];
SSNotebookObject[nb_NotebookObject]:=
	Replace[Lookup[$ssNbObjCache,nb],{
		_Missing|_NotebookObject?(NotebookInformation@#===$Failed&):>
			Set[$ssNbObjCache[nb],
				Replace[SSNotebookFileName[nb],{
					f_String:>
						Replace[FENotebooks[f],{
							{}:>Missing["NotFound"],
							{n_,___}:>n
							}],
					_Missing:>
						With[{n=CurrentValue[nb,StyleDefinitions]},
							SelectFirst[FENotebooks[],
								NotebookGet@#===n&]
							]
					}]
				]
		}];


SSNotebookObject/:
	HoldPattern[Unset[SSNotebookObject[nb_NotebookObject]]]:=
		$ssNbObjCache[nb]=.;
SSNotebookObject/:
	HoldPattern[Unset[SSNotebookObject[nb:EvaluationNotebook[]|InputNotebook[]]]]:=
		With[{n=nb},
			Unset[SSNotebookObject[n]]
			];
SSNotebookObject/:
	HoldPattern[Set[SSNotebookObject[nb_NotebookObject],n_NotebookObject]]:=
		$ssNbObjCache[nb]=n;
SSNotebookObject/:
	HoldPattern[
		Set[SSNotebookObject[nb:EvaluationNotebook[]|InputNotebook[]],
			n_NotebookObject]
		]:=
		With[{e=nb},
			Set[SSNotebookObject[e],n]
			];
SSNotebookObject/:
	HoldPattern[SetDelayed[SSNotebookObject[nb_NotebookObject],n_]]:=
		$ssNbObjCache[nb]:=n;
SSNotebookObject/:
	HoldPattern[
		SetDelayed[SSNotebookObject[nb:EvaluationNotebook[]|InputNotebook[]],
			n_]
		]:=
		With[{e=nb},
			SetDelayed[SSNotebookObject[e],n]
			];


SSNotebookGet[nb_NotebookObject]:=
	NotebookGet@SSNotebookObject@nb;
SSNotebookGet[Optional[Automatic,Automatic]]:=
	SSNotebookGet@EvaluationNotebook[];


SSEditNotebook[nb:_NotebookObject|Automatic:Automatic]:=
	With[{e=Replace[nb,Automatic:>EvaluationNotebook[]]},
		Replace[CurrentValue[e,StyleDefinitions],{
			"StylesheetFormatting.nb"|"PrivateStylesheetFormatting.nb"|
				Notebook[{___,
					Cell[
						StyleData[
							StyleDefinitions->
								("PrivateStylesheetFormatting.nb"|"StylesheetFormatting.nb")
							],
					___],
					___
					},
					___
					]->e,
			s:_String|_FrontEnd`FileName:>
				(
					SetOptions[e,
						StyleDefinitions->
							Notebook[{Cell[StyleData[StyleDefinitions->s]]},
								StyleDefinitions->
									("PrivateStylesheetFormatting.nb")
								]
						];
					$ssNbObjCache[e]=.;
					SSNotebookObject[e]
					),
			_:>
				SSNotebookObject[e]
			}]
		];


SSStyleData[styleNames_,parentStyles_]:=
	MapThread[
		If[#2===None,
			StyleData[#],
			StyleData[#,StyleDefinitions->StyleData[#2]]
			]&,
		With[{
			styles=
				{styleNames}/.{
					(h:Rule|RuleDelayed)[s_List,e_]:>
						Flatten@Map[Thread[h[#,e]]&,s],
					(h:Rule|RuleDelayed)[s_,e_List]:>
						Flatten@Map[Thread[h[s,#]]&,e]
					}//Flatten
			},
			{
				styles,
				Take[
					ConstantArray[
						{parentStyles}/.{
							(h:Rule|RuleDelayed)[s_List,e_]:>
								Flatten@Map[Thread[h[#,e]]&,s],
							(h:Rule|RuleDelayed)[s_,e_List]:>
								Flatten@Map[Thread[h[s,#]]&,e]
							},
						Length@styles
						]//Flatten,
					Length@styles
					]
			}]
		]//.{
			(Rule|RuleDelayed)[name:Except[StyleDefinitions],env_]:>
				StyleData@@Flatten@{name,env}
			}//.{
			DefaultStyle[f__]:>(
				StyleDefinitions->
					Replace[{f},{
						{s_String}:>
							StringTrim[s,".nb"]<>".nb",
						{path__,name_}:>
							FrontEnd`FileName[{path},
								Evaluate[StringTrim[name,".nb"]<>".nb"]],
						{e_}:>
							e
						}]
				),
			StyleData[a___,StyleData[b___],c___]:>
				StyleData[a,b,c]
			}


Options[SSNew]=
	DeleteDuplicatesBy[
		Join[
			Options[Cell],
			Options[Notebook],
			Options[NotebookWrite]
			],
		First];
SSNew[nb:_NotebookObject|Automatic:Automatic,
	type:
		_String|All|_StyleData|_DefaultStyle|
			{(_String|All|_StyleData|_DefaultStyle)..},
	parentType:
		_FrontEnd`FileName|_String|_StyleData|None|
			{(_FrontEnd`FileName|_String|_StyleData|None)..}:
		None,
	placement:Next|First|Last|Automatic:Automatic,
	ops:OptionsPattern[]]:=
	With[{
		ec=EvaluationCell[],
		notebook=Replace[nb,Automatic:>SSEditNotebook[]],
		position=
				Replace[placement,
					Automatic:>Replace[type,{_DefaultStyle->First,_->Next}]],
		styleDecs=
			SSStyleData[type,parentType]
		},
		Switch[position,
			First,SelectionMove[notebook,Before,Notebook],
			Next,SelectionMove[notebook,After,Cell],
			Last,SelectionMove[notebook,After,Notebook]
			];
		NotebookWrite[notebook,
			Cell[#,
				Sequence@@FilterRules[{ops},
					Except[Alternatives@@Map[First,Options[NotebookWrite]]]
					]
				],
			Sequence@@FilterRules[{ops},Options@NotebookWrite]
			]&/@styleDecs;
		];


SSDelete[
	nb:_NotebookObject|Automatic:Automatic,
	type:_String|_List|_DefaultStyle]:=
	Replace[SSCells[nb,type],{
		c:{__CellObject}:>
			NotebookDelete@c
		}];


SSUpdate[
	nb:_NotebookObject|Automatic:Automatic,
	type:All|_String|_List|_DefaultStyle,
	parentType:_FrontEnd`FileName|_String|_List|_StyleData|None:None,
	placement:Next|First|Last|Automatic:Automatic,
	ops:(_Rule|_RuleDelayed)...]:=
	(
		SSDelete[nb,type];
		SSNew[nb,type,parentType,placement,ops]
		);


SSTemplate[newNB:_Notebook|_NotebookObject|None:None,
	defaultStyle:_DefaultStyle:DefaultStyle["Default.nb"],
	styles:(_String|_Directive)...,
	ops:_Rule|_RuleDelayed...
	]:=With[{nb=Replace[newNB,{
			_Notebook:>
			CreateDocument["",
				ops,
				WindowTitle->First@newNB,
				StyleDefinitions->
					Notebook[{
						Cell[StyleData[StyleDefinitions->"StylesheetFormatting.nb"]],
						Cell[StyleData["Notebook"],
							Saveable->True,
							Editable->True
							]
						}],
					Saveable->True],
				None:>Automatic
				}]},
		SSNew[nb,defaultStyle,Next];
		Do[
			SSNew[nb,##]&@@If[MatchQ[s,_Directive],s,{s}],
			{s,{styles}}];
		Replace[nb,Automatic:>Null]
		];
SSTemplate[
	newNB:_Notebook|_NotebookObject|None:None,
	defaultStyle:_DefaultStyle:DefaultStyle["Default.nb"],
	Default]:=
	SSTemplate[newNB,defaultStyle,
		"Notebook",
		"Title","Chapter","Subchapter",
		"Section","Subsection","Subsubsection",
		"Text","Code","Input",
		"Item","ItemParagraph"
		];


SSOpen[nb:_NotebookObject|Automatic:Automatic]:=
With[{notebook=Replace[nb,Automatic:>SSEditNotebook[]]},
	(*FrontEndTokenExecute@"EditStyleDefinitions";*)
Replace[
StyleDefinitions/.Options[notebook,StyleDefinitions],{
s:(_String|_FrontEnd`FileName):>
			SystemOpen@s,
n:(_Notebook):>
			CreateDocument[n,
				WindowTitle->"StyleDefintions for "<>FileNameTake@NotebookFileName[notebook]]
}
]
];


SSDefaultStyles[
	nb:_NotebookObject|Automatic:Automatic,
	styles__String]:=
	With[{sList={styles}},
		Do[
			SSEdit[nb,sList[[i]],DefaultNewCellStyle->sList[[i+1]]],
			{i,Length@sList-1}
			]
		];


$SSCellStyleSinglePattern=
	All|_String|_StyleData|_Verbatim|Default;


$SSCellStylePatterns=
	$SSCellStyleSinglePattern|{$SSCellStyleSinglePattern..};


cellTypeMatchQ[type_String,types_]:=
	Which[
		types==="*",True,
		types==={},False,
		MatchQ[types,_Verbatim],
			Length@First@types<=1&&
				cellTypeMatchQ[type,First@types],
		MatchQ[types,StyleData[_]],cellTypeMatchQ[type,First@types],
		MatchQ[types,
			Except[
				_List|
				_String|
				_StringExpression|
				_Alternatives
				]
			],False,
		MatchQ[types,_List],
			MemberQ[
				Replace[types,
					{s_,"*"..}:>{s},
					1
					],
				type
				],
		MatchQ[type,_String|_StringExpression],StringMatchQ[type,types],
		True,False
		];
cellTypeMatchQ[All,All]:=True;
cellTypeMatchQ[type_Symbol,"*"]:=True;
cellTypeMatchQ[type:Except[_String],_]:=False;
cellTypeMatchQ[types_][type_]:=cellTypeMatchQ[type,types];


cellStyleNameMatchQ[s_StyleData,types_]:=
	types=!={}&&If[Length@s==1,
		cellTypeMatchQ[First@s,types],
		Length@s>0&&(
			cellTypeMatchQ[First@s,Cases[Flatten@{types},_String|_Symbol]]||
				With[{styleDatas=
					Replace[Cases[Flatten@{types},_StyleData|_Verbatim],{
						HoldPattern[Verbatim][d_StyleData]:>
							If[Length@d!=Length@s,
								Nothing,
								List@@d
								],
						HoldPattern[Verbatim][e_]:>
							If[Length@s!=1,
								Nothing,
								{e}
								],
						d_StyleData:>
							If[Length@d>Length@s,
								Nothing,
								Join[
									List@@d,
									ConstantArray["*",Max@{Length@s-Length@d,0}]
									]
								]
						},
						1]
						},
					AnyTrue[styleDatas,
						And@@MapThread[cellTypeMatchQ,{List@@s,#}]&]
					])
		];


cellStyleDataMatchQ[s_StyleData,types_]:=
	With[{matchData=DeleteCases[s,Except[_String|_Symbol]]},
		MatchQ[s,
			Alternatives@@
				Replace[Flatten@{types},{
					DefaultStyle[d_]:>
						StyleData[StyleDefinitions->d],
					DefaultStyle[p_List,f_String]:>
						StyleData[StyleDefinitions->FrontEnd`FileName[{p},f]],
					DefaultStyle[a__,b_]:>
						StyleData[StyleDefinitions->StyleData[a,b]]
					},
					1]
				]||
			cellStyleNameMatchQ[matchData,types]
		];
cellStyleDataMatchQ[types_][s_]:=
	cellStyleDataMatchQ[s,types];


cellMatchQ[cell_,types_,Optional[StyleData,StyleData]]:=
	Replace[
cell,
{
Cell[_,_String,___]:>False,
Cell[_?(
MatchQ[
Replace[#,_BoxData:>ToExpression[#,StandardForm,Hold]],
If[types===Default,
							StyleData[StyleDefinitions->_,___],
_StyleData?(cellStyleDataMatchQ[types])
]
]&),
				___]:>True,
_->False
}
];
cellMatchQ[cell_,types_,Normal]:=Replace[
cell,
{Cell[_,_?(cellTypeMatchQ[types]),___]:>True,
_:>False
}]
cellMatchQ[cell_,types_,_]:=False


stylesheetNotebook[nb_,file_String?FileExistsQ]:=Get@file;
stylesheetNotebook[nb_,file_FrontEnd`FileName]:=Get@ToFileName@file;
stylesheetNotebook[nb_NotebookObject,file_String]:=
	stylesheetNotebook[NotebookGet@nb,Quiet@NotebookDirectory@nb,file];
stylesheetNotebook[
		nb_Notebook,
		dir:(_String?DirectoryQ|Automatic|$Failed):Automatic,
		file_String]:=
	With[{testDir=
		Replace[Quiet@NotebookDirectory@nb,
			_NotebookDirectory|$Failed:>
			Replace[dir,$Failed|Automatic:>$UserDocumentsDirectory]
			]},
		If[FileExistsQ@FileNameJoin@{testDir,file},
			Get@FileNameJoin@{testDir,file},
			Replace[Cases[Flatten@Table[
							FileNames["*",FileNameJoin@{d,"FrontEnd","Stylesheets"}],
									{d,
										FileNames["*",{
											FileNameJoin@{$UserBaseDirectory,"Applications"},
											$InstallationDirectory
										}]
									}],
							s_?(FileNameTake@#===file&):>s],
					{
						{}:>$Failed,
						{s_,___}:>Get@s
				}
					]
				]
		];


Options[SSCells]={
	"MakeCell"->False,
	"SelectMode"->StyleData
	};
SSCells[
	nb:_Notebook|_NotebookObject|Automatic:Automatic,
	types:$SSCellStylePatterns|{},
	ops:OptionsPattern[]
	]:=
	With[{
		make=TrueQ@OptionValue["MakeCell"],
		mode=
			Replace[
				OptionValue["SelectMode"],
				Except[Normal|StyleData]->StyleData
				]
		},
		Replace[
			Select[
				Replace[
					Replace[nb,Automatic:>SSEditNotebook[]],
					{
						n_NotebookObject:>Cells[n],
						n_Notebook:>(First@NotebookTools`FlattenCellGroups[n])
						}
					],
				cellMatchQ[Replace[#,c_CellObject:>NotebookRead@c],types,mode]&
				],{
			l_List:>
				If[mode===StyleData&&make,
					With[{missingStyles=
						Select[Flatten[{types},1],
							With[{c=NotebookRead/@l},
								With[{s=#},
									Not@AnyTrue[c,cellMatchQ[#,s,StyleData]&]
									]&
								]
							]
						},
						SSNew[nb,missingStyles];
						Join[
							SSCells[nb,
								missingStyles,
								"MakeCell"->False,
								ops
								],
							l
							]
						],
					l]	
			}]
		];


StylesheetNotebook[nb:_Notebook|_NotebookObject|Automatic:Automatic]:=
	With[{n=Replace[nb,Automatic:>SSEditNotebook[]]},
		Module[{styleDefs=StyleDefinitions/.Options[n,StyleDefinitions],
				parentNB,extraStyles},
				parentNB=
					Replace[styleDefs,
						sd_Notebook:>
							Replace[SSCells[sd,Default],
								{
									{___,c_}:>Last@First@First@c,
									{}->Notebook[{}]
								}]
							];
				extraStyles=
					Replace[styleDefs,{
						sd_Notebook:>SSCells[sd],
						_:>{}
						}];
				If[MatchQ[parentNB,_String|_FrontEnd`FileName],
					parentNB=
						Replace[
							stylesheetNotebook[n,parentNB],
							s_String:>Get@s
							];
					parentNB
					];
				Replace[
					NotebookTools`FlattenCellGroups@parentNB,{
						Notebook[cells_List,o___]:>
							With[{styleNB=Notebook[Flatten@{cells,extraStyles}]},
								Notebook[Join[
									SSCells[styleNB,Default],
									SSCells[styleNB]],
									o]
								],
						_->parentNB
						}
					]
				]
			];


SSStyles[nb:_Notebook|_NotebookObject|Automatic:Automatic]:=
	Module[
		{defaultCells=SSCells[nb,Default]},
		{
			With[{n=StylesheetNotebook@nb},
				defaultCells={
					defaultCells,
					If[n=!=$Failed,SSCells[n,Default],{}]};
					Cases[
						If[n=!=$Failed,
							SSCells[n],
							{}],
						Cell[StyleData[s:Except[_Rule]..,___Rule],___]:>Cell[StyleData[s]]
					]
				],
			Join@@defaultCells
		}
	];


SSSuspendScreen[nb_]:=
	frontEndExecuteRouter[
		FrontEnd`NotebookSuspendScreenUpdates[nb],
		FrontEndExecute@
			FrontEnd`NotebookSuspendScreenUpdates[nb]
		]


SSResumeScreen[nb_]:=
	frontEndExecuteRouter[
		FrontEnd`NotebookResumeScreenUpdates[nb],
		FrontEndExecute@
			FrontEnd`NotebookResumeScreenUpdates[nb]
		]


SSSelectionMove[a___]:=
	frontEndExecuteRouter[
		FrontEnd`SelectionMove[a],
		SelectionMove[a]
		]


SSToggleShowExpr[nb_]:=
	frontEndExecuteRouter[
		frontEndExecuteSow[
			FrontEndToken[nb, "ToggleShowExpression"]
			],
		FrontEndTokenExecute[nb, "ToggleShowExpression"]
		]


SSApplyEdits[cells:{__CellObject}]:=
	With[{
		groups=GroupBy[cells,ParentNotebook],
		current=EvaluationCell[],
		inb=InputNotebook[]
		},
		KeyValueMap[
			With[{nb=#},
				If[$frontEndExecuteBlock//TrueQ,
					CheckAll,
					Function[Null, #, HoldAll]
					][
					SSSuspendScreen[nb];
					Map[
						SSSelectionMove[#,All,Cell];
						SSToggleShowExpr[nb]~Do~2;
						&,
						#2
						];
					SSResumeScreen[nb],
					SSResumeScreen[nb]
					]
				]&,
			groups
			];
		If[inb===ParentNotebook@current,
			SSSelectionMove[current,All,Cell]
			];
		];
SSApplyEdits[nb:_CellObject|Automatic:Automatic]:=
	SSApplyEdits[{Replace[nb,Automatic:>EvaluationCell[]]}];


SSSetOptions[obj_,ops__]:=
	If[$frontEndExecuteBlock,
		frontEndExecuteSow[FrontEnd`SetOptions[obj,ops]],
		SetOptions[obj,ops]
		]


SSEdit[
	cellExprs:_Cell|{__Cell},
	conf:_?OptionQ
	]:=
	With[{cells=Flatten@{cellExprs}},
		With[{del=
			Alternatives@@Map[(Rule|RuleDelayed)[First@#,_]&,Flatten@{conf}]
			},
			Table[
				Join[
					DeleteCases[c,del],
					Cell[conf]/.(
						(h:Rule|RuleDelayed)[k_,f_Function]:>
							With[{o=f@(k/.Quiet@Options[c,k])},
								h[k,o]
								]
						)
					],
					{c,cells}
					]
				]
			]


SSEdit[
	cellObs:_CellObject|{__CellObject},
	conf_?OptionQ
	]:=
	frontEndExecuteBlock@
		With[{cells=Flatten@{cellObs}},
			Do[
				With[{oplist=
					Table[
						If[MatchQ[o,_Rule],
							With[{op=Options[c,First@o]},
								Replace[op,{
									{k_->v_,___}:>
										(k->
											Replace[Last@o,
												f_Function:>(f[v,c])]
											),
									{}->o
									}]
								],
							o
							],
						{o,Flatten@{conf}}]
						},
				SSSetOptions[c,oplist]
				],
				{c,cells}
			];
		SSApplyEdits@cells;
		]


SSEdit[
	StyleData[nb:_NotebookObject],
	types:$SSCellStylePatterns,
	conf_?OptionQ
	]:=
		With[{snb=StyleDefinitions/.Options[nb,StyleDefinitions]},
			SetOptions[nb,
				StyleDefinitions->Replace[snb,{
					_Notebook:>
						With[{n=NotebookTools`FlattenCellGroups@snb},
							ReplacePart[n,
								1->With[{c=
										Replace[
											SSCells[n,StyleData,types],
											l_?(Length@#<Length@Flatten@{types}&):>
												With[{stypes=First/@First/@l},
														Join[l,
															Cell[StyleData[#]]&/@DeleteCases[Flatten@{types},
																Alternatives@@stypes]
															]
														]
											]},
											Join[
												DeleteCases[First@n,
													Alternatives@@DeleteDuplicates[
																Cell[StyleData[First@First@#,___],___]&/@c
															]
													],
												SSEdit[c,conf]
												]
										]
									]
							],
					_String:>
						Notebook[
							Prepend[
								SSEdit[Cell[StyleData[#]]&/@Flatten@{types},conf],
								Cell@StyleData[StyleDefinitions->snb]
								],
								StyleDefinitions->
									Notebook[{
										Cell[StyleData[StyleDefinitions->"StylesheetFormatting.nb"]],
										Cell[StyleData["Notebook"],
											Saveable->True,
											Editable->True
											]
										}]
								]
								
					}]
				]
			]


Options[SSEdit]=
	Options[SSCells];
SSEdit[
	nb:_NotebookObject|Automatic:Automatic,
	types:$SSCellStylePatterns,
	conf_?OptionQ,
	ops:OptionsPattern[]
	]:=
	With[{cells=SSCells[nb,types,ops]},
		If[Length@cells===0,
			$Failed,
	SSEdit[cells,conf]
			]
	];


$SSCellOptionPatterns=
	_String|_Symbol|{(_String|_Symbol)..};


Options[SSValue]=
	Join[
		Options[SSCells],
		{
			"ValueFunction"->CurrentValue
			}
		];
SSValue[
	cellOb:_CellObject|{__CellObject},
	ops:$SSCellOptionPatterns,
	OptionsPattern[]
	]:=
	With[{
		mode=
			Replace[OptionValue["ValueFunction"],{
				Automatic->CurrentValue,
				"Absolute"->AbsoluteCurrentValue
				}]
		},
		If[ListQ@cellOb,
			If[Length@cellOb>1,
				Transpose,
				Flatten[#,1]&
				],
			Identity
			]@
			Map[mode[cellOb,#]&,
				Flatten@{ops}
				]
		];
SSValue[
	nb:_NotebookObject|Automatic:Automatic,
	cellStyle:$SSCellStylePatterns,
	op:$SSCellOptionPatterns,
	ops:OptionsPattern[]
	]:=
	With[{cells=
		SSCells[nb,cellStyle,
			FilterRules[{ops},
				Options[SSCells]
				]
			]},
		Replace[cells,{
			c:{__}:>
				SSValue[c,op,
					FilterRules[{ops},
						Options[SSCells]
						]
					],
			{}:>
				With[{
					mode=
						Replace[OptionValue["ValueFunction"],{
							Automatic->CurrentValue,
							"Absolute"->AbsoluteCurrentValue
							}]
					},
					Map[
						Replace[
							mode[
								SSEditNotebook@nb,
								{StyleDefinitions,cellStyle,#}
								],
							$Failed->Inherited
							]&,
						Flatten@{op}
						]
					]
			}]
		];


Options[SSSync]=
	DeleteDuplicatesBy[First]@
	Join[
		Options[SSEdit],
		Options[SSValue]
		];
SSSync[
	nb:_NotebookObject|Automatic:Automatic,
	toStyle:$SSCellStyleSinglePattern,
	fromStyle:$SSCellStyleSinglePattern,
	op:$SSCellOptionPatterns:Automatic,
	ops:OptionsPattern[]
	]:=
	With[{
		o=
			Replace[op,Automatic:>$SSCellDisplayStyleOptions],
		c=
			SSCells[nb,fromStyle,
				FilterRules[{ops},
					Options[SSCells]
					]
				]
		},
		SSEdit[nb,toStyle,
			Thread[
				o->
					If[Length@c>0,	
						SSValue[First@c,o,
							FilterRules[{ops},
								Options[SSValue]
								]
							],
						SSValue[nb,
							fromStyle,
							o,
							FilterRules[{ops},
								Options[SSValue]
								]
							]
						]
				],
			FilterRules[{ops},
				Options[SSEdit]
				]
			]
		];


SSDrop[cellObs:_CellObject|{__CellObject},ops__]:=
SSEdit[cellObs,Sequence@@Thread[{ops}->Inherited]]


Options[SSDrop]=
	Options[SSCells];
SSDrop[
		nb:_NotebookObject|Automatic:Automatic,
		types:$SSCellStylePatterns:"*",
		op:$SSCellOptionPatterns,
		ops:OptionsPattern[]
		]:=
	With[{
		cells=
			SSCells[nb,types,
				FilterRules[{ops},Options[SSCells]]
				]
			},
		SSDrop[cells,op,ops]
		];


resolveSSRuleListMergeTag[e_]:=e


resolveSSRuleListMerge[merge_]:=
	Normal@
		Merge[merge,
			resolveSSRuleListMergeTag[
				If[OptionQ[#], 
					resolveSSRuleListMerge[#],
					Last[#]
					]
				]&
			]//.{
				HoldPattern[
					resolveSSRuleListMergeTag[
						If[_,_,_]
						]&[{___,a_}]
					]:>a,
				HoldPattern[
					resolveSSRuleListMergeTag[e_]
					]:>e
				}


(* ::Text:: *)
(*This should really be done in terms of CurrentValue but I didn\[CloseCurlyQuote]t think to do it initially, so we\[CloseCurlyQuote]ll run with it.*)



$SSRuleListOptionPattern=
	_Rule|_RuleDelayed|{(_Rule|_RuleDelayed)..};


Options[SSEditRuleListOption]=
	Options[SSEdit];
SSEditRuleListOption[
	obs:{__CellObject}|{__NotebookObject},
	op_,
	new:$SSRuleListOptionPattern
	]:=
	frontEndExecuteBlock[
		Do[
			SSSetOptions[ob,
				op->
					resolveSSRuleListMerge@
						Flatten@{
							Replace[op/.Options[ob,op],Except[_List]:>{}],
							new
							}
				],
			{ob,obs}
			];
		SSApplyEdits[obs];
		];
SSEditRuleListOption[
	nb:_NotebookObject|Automatic:Automatic,
	cellStyles_,
	op_,
	events:$SSRuleListOptionPattern,
	ops:OptionsPattern[]
	]:=
	Replace[
		SSCells[nb,cellStyles,
			FilterRules[{ops},Options[SSCells]]
			],{
		c:{__}:>
			SSEditRuleListOption[c,op,events],
		_->Null
		}];


Options[SSEditEvents]=
	Join[
		Options[SSEditRuleListOption],
		{
			"EditOption"->Automatic
			}
		];
SSEditEvents[
	nb:(_NotebookObject|_CellObject|{__CellObject}|Automatic):Automatic,
	events:$SSRuleListOptionPattern,
	ops:OptionsPattern[]
	]:=
	With[{
		op=
		Replace[OptionValue["EditOption"],
			Except[CellEventActions|NotebookEventActions|Automatic]->Automatic
			]
		},
		With[{obop=
			Replace[nb,{
				Automatic:>
					{SSEditNotebook[nb],
						Replace[op,Automatic:>NotebookEventActions]
						},
				_CellObject|{__CellObject}:>
					{nb,
						Replace[op,Automatic:>CellEventActions]
						},
				_NotebookObject:>
					{nb,
						Replace[op,Automatic:>NotebookEventActions]
						}
				}]},
			SSEditRuleListOption[
				Flatten@{First@obop},
				Last@obop,
				events,
				ops
				]
			]
		];
SSEditEvents[
	nb:_NotebookObject|Automatic:Automatic,
	cellStyles:$SSCellStylePatterns,
	events:$SSRuleListOptionPattern,
	ops:OptionsPattern[]
	]:=
	Replace[
		SSCells[nb,cellStyles,FilterRules[{ops},Options[SSCells]]],{
		c:{__}:>
			SSEditEvents[c,events,ops],
		_->Null
		}];


Options[SSEditAliases]=
	Options[SSEditRuleListOption];
SSEditAliases[
	nb:(_NotebookObject|_CellObject|{__CellObject}|Automatic):Automatic,
	events:$SSRuleListOptionPattern,
	ops:OptionsPattern[]
	]:=
	With[{obop=
		Replace[nb,{
			Automatic:>
				{SSEditNotebook[nb],
					InputAliases
					},
			_CellObject|{__CellObject}:>
				{nb,
					InputAliases
					},
			_NotebookObject:>
				{nb,
					InputAliases
					}
			}]},
		SSEditRuleListOption[
			Flatten@{First@obop},
			Last@obop,
			events,
			ops
			]
		];
SSEditAliases[
	nb:_NotebookObject|Automatic:Automatic,
	cellStyles:$SSCellStylePatterns,
	events:$SSEventPatterns,
	ops:OptionsPattern[]
	]:=
	Replace[
		SSCells[nb,cellStyles,FilterRules[{ops},Options[SSCells]]],{
		c:{__}:>
			SSEditAliases[c,events,ops],
		_->Null
		}];


Options[SSEditAutoReplacements]=
	Options[SSEditRuleListOption];
SSEditAutoReplacements[
	nb:(_NotebookObject|_CellObject|{__CellObject}|Automatic):Automatic,
	events:$SSRuleListOptionPattern,
	ops:OptionsPattern[]
	]:=
	With[{obop=
		Replace[nb,{
			Automatic:>
				{SSEditNotebook[nb],
					InputAutoReplacements
					},
			_CellObject|{__CellObject}:>
				{nb,
					InputAutoReplacements
					},
			_NotebookObject:>
				{nb,
					InputAutoReplacements
					}
			}]},
		SSEditRuleListOption[
			Flatten@{First@obop},
			Last@obop,
			events,
			ops
			]
		];
SSEditAutoReplacements[
	nb:_NotebookObject|Automatic:Automatic,
	cellStyles:$SSCellStylePatterns,
	events:$SSRuleListOptionPattern,
	ops:OptionsPattern[]
	]:=
	Replace[
		SSCells[nb,cellStyles,FilterRules[{ops},Options[SSCells]]],{
		c:{__}:>
			SSEditAutoReplacements[c,events,ops],
		_->Null
		}];


Options[SSEditTaggingRules]=
	Options[SSEditRuleListOption];
SSEditTaggingRules[
	nb:(_NotebookObject|_CellObject|{__CellObject}|Automatic):Automatic,
	events:$SSRuleListOptionPattern,
	ops:OptionsPattern[]
	]:=
	With[{obop=
		Replace[nb,{
			Automatic:>
				{SSEditNotebook[nb],
					TaggingRules
					},
			_CellObject|{__CellObject}:>
				{nb,
					TaggingRules
					},
			_NotebookObject:>
				{nb,
					TaggingRules
					}
			}]},
		SSEditRuleListOption[
			Flatten@{First@obop},
			Last@obop,
			events,
			ops
			]
		];
SSEditTaggingRules[
	nb:_NotebookObject|Automatic:Automatic,
	cellStyles:$SSCellStylePatterns,
	events:$SSRuleListOptionPattern,
	ops:OptionsPattern[]
	]:=
	Replace[
		SSCells[nb,cellStyles,FilterRules[{ops},Options[SSCells]]],{
		c:{__}:>
			SSEditTaggingRules[c,events,ops],
		_->Null
		}];


End[];



