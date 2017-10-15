(* ::Package:: *)



NotebookToMarkdown::usage="Converts a notebook to markdown";
NotebookMarkdownSave::usage="Saves a notebook as markdown";


MarkdownToXML::usage=
	"Converts markdown to XML";


Begin["`Private`"];


$MarkdownSiteRoot=
	FileNameJoin@{
		$WebTemplatingRoot,
		"markdown"
		};


$MarkdownStandardContentExtensions=
	{
		"content",
		"project",
		"proj"
		};


MarkdownSiteBase[f_String]:=
	Replace[FileNameSplit[f],{
		{d:Shortest[___],
			(Alternatives@@$MarkdownStandardContentExtensions)|"output",___}:>
			FileNameJoin@{d},
		_:>If[DirectoryQ@f,f,DirectoryName[f]]
		}]


MarkdownContentExtension[root_]:=
	SelectFirst[$MarkdownStandardContentExtensions,
		DirectoryQ@FileNameJoin@{root,#}&,
		Nothing
		];


MarkdownContentPath[f_String]:=
	Replace[FileNameSplit[f],{
		{Shortest[___],
			Alternatives@@$MarkdownStandardContentExtensions,p___}:>
			FileNameJoin@{p},
		_:>f
		}]


MarkdownOutputPath[f_String]:=
	Replace[FileNameSplit[f],{
		{Shortest[___],"output",p___}:>FileNameJoin@{p},
		_:>f
		}]


$markdownnewmdfiletemplate=
"`headers`

`body`
";


markdownFileMetadataTitle[t_,name_,opsassoc_]:=
	Replace[t,
		{
			Automatic:>name
			}];


markdownFileMetadataSlug[t_,name_,opsassoc_]:=
	Replace[t,
		{
			Automatic:>
				ToLowerCase@
					StringReplace[
						markdownFileMetadataTitle[
							Lookup[opsassoc,"Title",t],
							name,
							opsassoc
							],{
						Whitespace->"-",
						Except[WordCharacter]->""
						}]
			}];


markdownFileMetadata[val_,opsassoc_]:=
	Replace[val,{
		_List:>
			StringRiffle[ToString/@val,","],
		_DateObject:>
			StringReplace[DateString[val,"ISODateTime"],"T"->" "]
		}]


markdownMetadataFormat[name_,ops_]:=
	With[{opsassoc=Association@ops},
		Function[StringRiffle[#,"\n"]]@
			KeyValueMap[
				#<>": "<>
					StringReplace[
						ToString@
							Switch[#,
								"Title",
									markdownFileMetadataTitle[#2,name,opsassoc],
								"Slug",
									markdownFileMetadataSlug[#2,name,opsassoc],
								_,
									markdownFileMetadata[#2,opsassoc]
								],
						"\n"->"\ "
						]&,
				KeySortBy[
					Switch[#,"Title",0,_,1]&
					]@opsassoc
				]
		];


MarkdownNotebookMetadata[c:{Cell[_BoxData,"Metadata",___]...}]:=
	Join@@Select[Normal@ToExpression[First@First@#]&/@c,OptionQ];
MarkdownNotebookMetadata[nb_Notebook]:=
	MarkdownNotebookMetadata@
		Cases[
			NotebookTools`FlattenCellGroups[First@nb],
			Cell[_BoxData,"Metadata",___]
			];
MarkdownNotebookMetadata[nb_NotebookObject]:=
	MarkdownNotebookMetadata@
		Cases[
			NotebookRead@Cells[nb,CellStyle->"Metadata"],
			Cell[_BoxData,___]
			]


MarkdownNotebookDirectory[nb_]:=
	Replace[Quiet@NotebookDirectory[nb],
		Except[_String?DirectoryQ]:>
			With[{
				d=
					FileNameJoin@{
						$TemporaryDirectory,
						"markdown_export"
						}
				},
				If[!DirectoryQ[d],
					CreateDirectory[d]
					];
				d
				]
		];


MarkdownNotebookFileName[nb_]:=
	Replace[Quiet@NotebookFileName[nb],
		Except[_String?FileExistsQ]:>
			FileNameJoin@{
				$TemporaryDirectory,
				"markdown_export",
				"markdown_notebook.nb"
				}
		];


MarkdownNotebookContentPath[nb_]:=
	MarkdownContentPath@
		MarkdownNotebookFileName[nb];


$NotebookToMarkdownStyles=
	{
		"Section","Subsection","Subsubsection",
		"Code","Output","Text",
		"Quote","PageBreak",
		"Item","Subitem",
		"ItemNumbered","SubitemNumbered",
		"FencedCode","Message","FormattedOutput",
		"RawMarkdown","RawHTML","RawPre","Program",
		"Echo", "Print"
		};


NotebookToMarkdown[nb_NotebookObject]:=
	With[{meta=meta=MarkdownNotebookMetadata[nb]},
		With[{
			dir=MarkdownNotebookDirectory[nb],
			name=
				Replace[
					Lookup[meta,"Slug","Title"],
					Automatic:>
						FileBaseName@MarkdownNotebookFileName[nb]
					]
			},
			If[!DirectoryQ[dir],
				$Failed,
				With[{
					d2=
						MarkdownSiteBase[dir],
					cext=
						MarkdownContentExtension[MarkdownSiteBase@dir],
					path=
						FileNameJoin@ConstantArray["..",1+FileNameDepth[MarkdownContentPath[dir]]]
					},
					StringRiffle[
						DeleteCases[""]@
							iNotebookToMarkdown[
								<|
									"Root"->d2,
									"Path"->path,
									"Name"->name,
									"ContentExtension"->cext,
									"Meta"->meta
									|>,
								#
								]&/@NotebookRead@
								Cells[nb,
									CellStyle->$NotebookToMarkdownStyles
									],
						"\n\n"
						]
					]
				]
			]
		];
NotebookToMarkdown[nb_Notebook]:=
	With[{
		nb2=CreateDocument@Insert[nb,Visible->False,2]
		},
		CheckAbort[
			(NotebookClose[nb2];#)&@
				NotebookToMarkdown[nb2],
			NotebookClose[nb2];
			$Aborted
			]
		]


iNotebookToMarkdown//Clear


$iNotebookToMarkdownRasterizeBaseForms=
	TemplateBox[__,
		InterpretationFunction->("Dataset[<>]"& ),
		__
		]|
	TemplateBox[__,
		"DateObject",
		__
		]|
	InterpretationBox[
		RowBox[{
			TagBox[_String,"SummaryHead",___]|
				StyleBox[TagBox[_String,"SummaryHead",___],"NonInterpretableSummary"],
			__
			}],
		__
		]|
	_DynamicBox|_DynamicModuleBox;
$iNotebookToMarkdownRasterizeForms=
	$iNotebookToMarkdownRasterizeBaseForms|
		_RowBox?(
			Not@*FreeQ[
				$iNotebookToMarkdownRasterizeBaseForms|
				$iNotebookToMarkdownOutputStringBaseForms
				])


$iNotebookToMarkdownOutputStringBaseForms=
	_GraphicsBox|_Graphics3DBox|
		TagBox[__,_Manipulate`InterpretManipulate]|
		TagBox[_GridBox,"Column"|"Grid"]|
		TemplateBox[_,"Legended",___];
$iNotebookToMarkdownOutputStringForms=
	$iNotebookToMarkdownOutputStringBaseForms|
	TooltipBox[
		_?(MatchQ[#,$iNotebookToMarkdownOutputStringForms]&),
		__
		]|
	InterpretationBox[
		_?(MatchQ[#,$iNotebookToMarkdownOutputStringForms]&),
		__
		];


markdownIDHook[id_]:=
	TemplateApply[
		"<a id=\"``\" style=\"width:0;height:0;margin:0;padding:0;\">&zwnj;</a>",
		ToLowerCase@
			StringReplace[StringTrim@id,
				{Whitespace->"-",Except[WordCharacter]->""}
				]
		];


iNotebookToMarkdown[pathInfo_,
	StyleBox[a__,FontSlant->"Italic",b___]]:=
	Replace[iNotebookToMarkdown[pathInfo,StyleBox[a,b]],
		s:Except[""]:>
			"_"<>s<>"_"
		];
iNotebookToMarkdown[pathInfo_,
	StyleBox[a___,FontWeight->"Bold"|Bold,b___]]:=
	Replace[iNotebookToMarkdown[pathInfo,StyleBox[a,b]],
		s:Except[""]:>
			"*"<>s<>"*"
		];
iNotebookToMarkdown[pathInfo_,
	StyleBox[a_,___]]:=
	Replace[iNotebookToMarkdown[pathInfo,a],
		s:Except[""]:>
			"*"<>s<>"*"
		];


iNotebookToMarkdown[pathInfo_,Cell[a___,CellTags->t_,b___]]:=
	Replace[iNotebookToMarkdown[pathInfo,Cell[a,b]],
		s:Except[""]:>
			markdownIDHook[
				ToLowerCase@StringJoin@Flatten@{t}
				]<>"\n\n"<>s
		];
iNotebookToMarkdown[pathInfo_,Cell[a___,FontSlant->"Italic"|Italic,b___]]:=
	Replace[iNotebookToMarkdown[pathInfo,Cell[a,b]],
		s:Except[""]:>
			"_"<>s<>"_"
		];
iNotebookToMarkdown[pathInfo_,Cell[a___,FontWeight->"Bold"|Bold,b___]]:=
	Replace[iNotebookToMarkdown[pathInfo,Cell[a,b]],
		s:Except[""]:>
			"*"<>s<>"*"
		];


iNotebookToMarkdown[pathInfo_,Cell[t_,"Section",___]]:=
	Replace[iNotebookToMarkdown[pathInfo,t],
		s:Except[""]:>
			Replace[
				FrontEndExecute@
					ExportPacket[Cell[t],"PlainText"],{
				{id_String,___}:>
					markdownIDHook[id]<>"\n\n",
				_->""
				}]<>
			"# "<>s
		];
iNotebookToMarkdown[pathInfo_,Cell[t_,"Subsection",___]]:=
	Replace[iNotebookToMarkdown[pathInfo,t],
		s:Except[""]:>
			Replace[
				FrontEndExecute@
					ExportPacket[Cell[t],"PlainText"],{
				{id_String,___}:>
					markdownIDHook[id]<>"\n\n",
				_->""
				}]<>
			"## "<>s
		];
iNotebookToMarkdown[pathInfo_,Cell[t_,"Subsubsection",___]]:=
	Replace[iNotebookToMarkdown[pathInfo,t],
		s:Except[""]:>
			"### "<>s
		];
iNotebookToMarkdown[pathInfo_,Cell[t_,"Subsububsection",___]]:=
	Replace[iNotebookToMarkdown[pathInfo,t],
		s:Except[""]:>
			"#### "<>s
		];
iNotebookToMarkdown[pathInfo_,Cell[t_,"Subsububsubsection",___]]:=
	Replace[iNotebookToMarkdown[pathInfo,t],
		s:Except[""]:>
			"##### "<>s
		];
iNotebookToMarkdown[pathInfo_,Cell[t_,"Subsububsubsubsection",___]]:=
	Replace[iNotebookToMarkdown[pathInfo,t],
		s:Except[""]:>
			"###### "<>s
		];


notebookToMarkdownPlainTextExport[t_,ops:OptionsPattern[]]:=
	FrontEndExecute[
		FrontEnd`ExportPacket[
			Cell[t],
			"PlainText"
			]
		][[1]]


iNotebookToMarkdown[pathInfo_,Cell[t_,"RawMarkdown",___]]:=
	notebookToMarkdownPlainTextExport[t];
iNotebookToMarkdown[pathInfo_,Cell[t_,"RawHTML",___]]:=
	With[{md=notebookToMarkdownPlainTextExport[t]},
		With[{block=StringSplit[md,"\n",2]},
			"<"<>block[[1]]<>">\n"<>
				block[[2]]<>
				"\n</"<>StringSplit[block[[1]]][[1]]<>">"
			]
		];
iNotebookToMarkdown[pathInfo_,Cell[t_,"RawPre",___]]:=
	With[{md=notebookToMarkdownPlainTextExport[t]},
		ExportString[XMLElement["pre",{},{md}],"XML"]
		];
iNotebookToMarkdown[pathInfo_,Cell[t_,"Program",___]]:=
	With[{md=notebookToMarkdownPlainTextExport[t]},
		ExportString[
			XMLElement["pre",{"class"->"program"},{XMLElement["code",{},{"\n"<>md<>"\n"}]}],
			"XML"
			]
		];


iNotebookToMarkdown[pathInfo_,Cell[t_,"PageBreak",___]]:=
	"---"


iNotebookToMarkdown[pathInfo_,Cell[t_,"Text",___]]:=
	iNotebookToMarkdown[pathInfo,t];


iNotebookToMarkdown[pathInfo_,Cell[t_,"Print",___]]:=
	"<p style='font-size:10; color:rgb(128, 128, 128);'>
	``
</p>"~TemplateApply~iNotebookToMarkdown[pathInfo,t];
iNotebookToMarkdown[pathInfo_,Cell[t_,"Echo",___]]:=
	"<p style='font-size:10; color:rgb(128, 128, 128);'>
	<span style='color:orange'> >> </span>``
</p>"~TemplateApply~iNotebookToMarkdown[pathInfo,t];


iNotebookToMarkdown[pathInfo_,Cell[t_,"Item",___]]:=
	Replace[iNotebookToMarkdown[pathInfo,t],
		s:Except[""]:>"* "<>s
		];
iNotebookToMarkdown[pathInfo_,Cell[t_,"ItemParagraph",___]]:=
	Replace[iNotebookToMarkdown[pathInfo,t],
		s:Except[""]:>StringReplace[s,StartOfLine->"  "]
		];
iNotebookToMarkdown[pathInfo_,Cell[t_,"Subitem",___]]:=
	Replace[iNotebookToMarkdown[pathInfo,t],
		s:Except[""]:>"  * "<>s
		];
iNotebookToMarkdown[pathInfo_,Cell[t_,"Subsubitem",___]]:=
	Replace[iNotebookToMarkdown[pathInfo,t],
		s:Except[""]:>"    * "<>s
		];
iNotebookToMarkdown[pathInfo_,Cell[t_,"SubitemParagraph",___]]:=
	Replace[iNotebookToMarkdown[pathInfo,t],
		s:Except[""]:>StringReplace[s,StartOfLine->"   "]
		];


iNotebookToMarkdown[pathInfo_,Cell[t_,"ItemNumbered",___]]:=
	Replace[iNotebookToMarkdown[pathInfo,t],
		s:Except[""]:>"1. "<>s
		];
iNotebookToMarkdown[pathInfo_,Cell[t_,"SubitemNumbered",___]]:=
	Replace[iNotebookToMarkdown[pathInfo,t],
		s:Except[""]:>"  1. "<>s
		];
iNotebookToMarkdown[pathInfo_,Cell[t_,"SubsubitemNumbered",___]]:=
	Replace[iNotebookToMarkdown[pathInfo,t],
		s:Except[""]:>"    1. "<>s
		];


iNotebookToMarkdown[pathInfo_,Cell[t_,"Quote",___]]:=
	Replace[iNotebookToMarkdown[pathInfo,t],
		s:Except[""]:>StringReplace[s,StartOfString->"> "]
		];


iNotebookToMarkdown[pathInfo_,Cell[e_,___]]:=
	iNotebookToMarkdown[pathInfo,e]


iNotebookToMarkdown[pathInfo_,
	TemplateBox[{msgHead_,msgName_,text_,___},"MessageTemplate",___]
	]:=
	"
<div class='mma-message'>
	<span class='mma-message-name'>`head`::`name`:</span>
	<span class='mma-message-text'>`body`</span>
</div>"~
	TemplateApply~
	<|
		"head"->msgHead,
		"name"->msgName,
		"body"->ToString@ToExpression@text
		|>;


$iNotebookToMarkdownToStripStartBlockFlag=
	"\n\"<!--<<<[[<<!\"\n";
$iNotebookToMarkdownToStripEndBlockFlag=
	"\n\"!>>]]>>>--!>\"\n";


$iNotebookToMarkdownToStripStart=
	"\"<!--STRIP_ME_FROM_OUTPUT>";
$iNotebookToMarkdownToStripEnd=
	"<STRIP_ME_FROM_OUTPUT--!>\"";


$iNotebookToMarkdownUnIndentedLine=
	"\"<!NO_INDENT>\"";


notebookToMarkdownStripBlock[s_]:=
	$iNotebookToMarkdownToStripStartBlockFlag<>
		$iNotebookToMarkdownUnIndentedLine<>
			$iNotebookToMarkdownToStripStart<>
				StringTrim@s<>
			$iNotebookToMarkdownToStripEnd<>
	$iNotebookToMarkdownToStripEndBlockFlag


markdownCodeCellGraphicsFormat[pathInfo_,e_,
	style_,postFormat_,
	ops:OptionsPattern[]
	]:=
	Replace[
		StringReplace[
			StringReplace[
				First@FrontEndExecute@
					FrontEnd`ExportPacket[
						Cell[e/.{
							b:$iNotebookToMarkdownRasterizeForms:>
								Replace[
									iNotebookToMarkdown[pathInfo,b,
										Replace[style,{
											"InputText"->"Input",
											_->Last@Flatten@{style}
											}]
										],
									s:Except[""]:>
										notebookToMarkdownStripBlock[s]
								],
							g:$iNotebookToMarkdownOutputStringForms:>
								Replace[
									iNotebookToMarkdown[pathInfo,g],
									s:Except[""]:>
										notebookToMarkdownStripBlock[s]
									],
							s_String?(StringMatchQ["\t"..]):>
								StringReplace[s,"\t"->" "]
							},
						ops,
						PageWidth->700
						],
						First@Flatten@{style}
						],
					{
						$iNotebookToMarkdownToStripStartBlockFlag~~
							inner:Shortest[__]~~
							$iNotebookToMarkdownToStripEndBlockFlag:>
								StringReplace[
									StringReplace[inner,{"\\\n"->""}],{
									$iNotebookToMarkdownToStripStart|
										$iNotebookToMarkdownToStripEnd->"",
									StartOfLine->$iNotebookToMarkdownUnIndentedLine
									}]
						}],
			{
				$iNotebookToMarkdownUnIndentedLine~~" \\\n"->
					$iNotebookToMarkdownUnIndentedLine,
				$iNotebookToMarkdownToStripStart~~
					inner:Shortest[__]~~
					$iNotebookToMarkdownToStripEnd:>
						StringReplace[inner,{
							StartOfLine->$iNotebookToMarkdownUnIndentedLine,
							StartOfLine~~Whitespace->"",
							"\\\n"->""
							}]
				}],
		s:Except[""]:>
				StringReplace[postFormat@s,{
				("\t"...)~~$iNotebookToMarkdownUnIndentedLine->
					""
				}]
		];


iNotebookToMarkdown[pathInfo_,Cell[e_,"FencedCode",___]]:=
	markdownCodeCellGraphicsFormat[pathInfo,e,
		"PlainText",
		Replace[
			ReplacePart[#, 
				1->StringTrim@StringTrim[#[[1]], "(*"|"*)"]
				]&@
				StringSplit[#,"\n",2],
			{
				{
					s_?(StringContainsQ["="]),
					b_
					}:>
					"<?prettify "<>s<>" ?>\n"<>"```\n"<>b<>"\n"<>"```",
				{
					s_?(StringMatchQ[Except[WhitespaceCharacter]..]@*StringTrim),
					b_
					}:>
					"```"<>StringTrim[s]<>"\n"<>b<>"\n```",
				_:>
					"```\n"<>#<>"\n"<>"```"
				}
			]&
		];
iNotebookToMarkdown[pathInfo_,Cell[e_,"Code"|"Input",___]]:=
	markdownCodeCellGraphicsFormat[pathInfo,e,
		"InputText",
		StringReplace[#,StartOfLine->"\t"]&
		];
iNotebookToMarkdown[pathInfo_,Cell[e_,"InlineInput",___]]:=
	markdownCodeCellGraphicsFormat[pathInfo,e,
		"InputText",
		"```"<>#<>If[StringEndsQ[#,"`"]," ",""]<>"```"&
		];
iNotebookToMarkdown[pathInfo_,Cell[e_,"Output",___]]:=
	markdownCodeCellGraphicsFormat[pathInfo,e,
		{"InputText","Output"},
		StringReplace["(*Out:*)\n\n"<>#,{
			StartOfLine->"\t"
			}]&
		];
iNotebookToMarkdown[pathInfo_,Cell[e_,"FormattedOutput",___]]:=
	markdownCodeCellGraphicsFormat[pathInfo,e,
		{"PlainText","Output"},
		ExportString[
			XMLElement["pre",{"class"->"program"},{
				XMLElement["code",{},{"-----------Out-----------\n"<>#}]
				}],
			"XML"
			]&,
		ShowStringCharacters->False
		]


iNotebookToMarkdown[pathInfo_,s_String]:=
	s;
iNotebookToMarkdown[pathInfo_,s_TextData]:=
	StringRiffle[
		Map[iNotebookToMarkdown[pathInfo,#]&,List@@s//Flatten]
		];
iNotebookToMarkdown[pathInfo_,b_BoxData]:=
	Replace[
		iNotebookToMarkdown[pathInfo,First@b],
		"":>
			First@
				FrontEndExecute@
					FrontEnd`ExportPacket[
						Cell[b],
						"PlainText"
						]
		];


iNotebookToMarkdown[pathInfo_,
	TagBox[
		GridBox[rows_,___],
		"Column"
		]
	]:=
	StringRiffle[
		StringReplace[
			iNotebookToMarkdown[pathInfo,#],
			"\n"->""
			]&/@First/@rows,
		"\n\n"
		];


iNotebookToMarkdown[pathInfo_,
	TagBox[
		GridBox[rows_,___],
		"Grid"
		]
	]:=
	StringRiffle[
		StringRiffle[
			Map[
				StringReplace[
					iNotebookToMarkdown[pathInfo,#],
					"\n"->""
					]&,
				#],
			"    "
			]&/@rows,
		"\n\n"
		];


iNotebookToMarkdown[
	pathInfo_,
	ButtonBox[d_,
		o___,
		BaseStyle->"Hyperlink",
		r___
		]]:=
	With[{t=iNotebookToMarkdown[pathInfo,d]},
		Replace[
			FirstCase[
				Flatten@List@
					Replace[
						Lookup[{o,r},ButtonData,t],
						s_String?(StringFreeQ["/"]):>"#"<>s
						],
				_String|_FrontEnd`FileName|_URL|_File,
				t
				],{
			URL[s_String?(StringContainsQ["_download=True"])]:>
				With[{parse=URLParse[s]},
					If[MatchQ[Lookup[parse["Query"],"_download",False],True|"True"],
						(*Download links*)
						"<a href=\""<>
							URLBuild@
								ReplacePart[parse,
									"Query"->
										Normal@
											KeyDrop[Association@parse["Query"],"_download"]
									]<>"\" download>"<>t<>"</a>",
						"["<>t<>"]("<>
							iNotebookToMarkdown[pathInfo,s]<>")"
						]
					],
			e_:>
				"["<>t<>"]("<>
					iNotebookToMarkdown[pathInfo,e]<>")"
			}]
		
		];


iNotebookToMarkdown[
	pathInfo_,
	ButtonBox[d_,
		o___,
		BaseStyle->"Link",
		r___
		]]:=
	With[{t=iNotebookToMarkdown[pathInfo,d]},
		"[```"<>t<>If[StringEndsQ[t,"`"]," ",""]<>"```]("<>
			Replace[
				FirstCase[
					Flatten@{Lookup[{o,r},ButtonData,t]},
					_String,
					t
					],
				s_String:>
					If[StringStartsQ[s,"paclet:"],
						With[{page=Documentation`ResolveLink[s]},
							URLBuild@
								Flatten@{
									If[StringQ[page]&&StringStartsQ[page,$InstallationDirectory],
										"https://reference.wolfram.com/language",
										"https://www.wolframcloud.com/objects/b3m2a1.paclets/reference"
										],
									URLParse[s,"Path"]
									}<>".html"
							],
						With[{page=
							Replace[Documentation`ResolveLink[s],{
								Null:>
									If[StringStartsQ[s,"paclet:"],
										FileNameJoin@URLParse[s,"Path"],
										FileNameJoin@{"ref",s}
										]
								}]
							},
							URLBuild@
								Flatten@{
									If[StringStartsQ[page,$InstallationDirectory],
										"https://reference.wolfram.com/language",
										"https://www.wolframcloud.com/objects/b3m2a1.paclets/reference"
										],
									ReplacePart[#,
										If[Length[#]==2,1,2]->
											ToLowerCase@
												StringReplace[
													#[[If[Length[#]==2,1,2]]],
													"ReferencePages"->"ref"
													]
										]&@DeleteCases["System"]@
									FileNameSplit@Echo@
										(StringTrim[#,"."~~FileExtension[#]]<>".html")&@
											Replace[
												Replace[FileNameSplit[page],{a___,"Symbols",b_}:>{a,b}],{
												{___,p_,"Documentation","English",e___}:>
													FileNameJoin@{p,e},
												{___,a_,b_,c_}:>
													FileNameJoin@{a,b,c},
												_:>
													page
												}]
								}
							]
						]
				]
			<>")"
		];


markdownNotebookHashExport//Clear


markdownNotebookHashExport[
	pathInfo_,
	expr_,
	ext_,
	fbase_:Automatic,
	alt_:Automatic,
	pre_:Identity,
	hash_:Automatic
	]:=
	With[{
		fname=
			Replace[fbase,
				Automatic:>
					ToLowerCase[
						StringReplace[
							StringTrim[pathInfo["Name"],FileExtension@pathInfo["Name"]],{
							Whitespace|$PathnameSeparator->"-",
							Except[WordCharacter]->""
							}]
						]<>"-"<>ToString@Replace[hash,Automatic:>Hash[expr]]<>"."<>ext
				]
		},
		Sow[
			{"img",fname}->pre@expr,
			"MarkdownExport"
			];
		"!["<>
			Replace[alt,
				Automatic:>StringTrim[fname,"."<>ext]
				]<>"]("<>
			StringRiffle[{
				Switch[pathInfo["ContentExtension"],
					"content",
						"{filename}",
					_String,
						pathInfo["ContentExtension"],
					_,
						Nothing
					],
				"img",
				fname
				},"/"]<>")"
		]


iNotebookToMarkdown[
	pathInfo_,
	InterpretationBox[
		g_?(MatchQ[$iNotebookToMarkdownOutputStringForms]),
		__
		],
	fbase_:Automatic,
	alt_:Automatic
	]:=
	iNotebookToMarkdown[
		root,
		path,
		name,
		g,
		fbase,
		alt
		]


iNotebookToMarkdown[
	pathInfo_,
	TooltipBox[
		g:$iNotebookToMarkdownOutputStringForms,
		t_,
		___],
	fbase_:Automatic,
	alt_:Automatic
	]:=
	iNotebookToMarkdown[
		root,
		path,
		name,
		g,
		fbase,
		If[alt===Automatic,iNotebookToMarkdown@t,alt]
		]


iNotebookToMarkdown[
	pathInfo_,
	g:$iNotebookToMarkdownRasterizeForms,
	style_:"Output"
	]:=
	markdownNotebookHashExport[
		pathInfo,
		g,
		"png",
		Automatic,
		Automatic,
		Rasterize[Cell[BoxData@#,style]]&
		]


iNotebookToMarkdown[
	pathInfo_,
	g:TagBox[__,_Manipulate`InterpretManipulate],
	fbase_:Automatic,
	alt_:Automatic
	]:=
	With[{
		expr=
			Replace[
				ToExpression[g],
				(AnimationRunning->False)->
					(AnimationRunning->True),
				1
				]
		},
		markdownNotebookHashExport[
			pathInfo,
			expr,
			"gif",
			alt,
			fbase,
			Identity,
			Replace[expr,{
				m:Verbatim[Manipulate][
					_,
					l__List,
					___
					]:>
					With[{syms=
						Alternatives@@
							ReleaseHold[
								Function[
									Null,
									FirstCase[
										Hold[#],
										s_Symbol:>HoldPattern[s],
										nosym,
										\[Infinity]
										],
									HoldFirst
									]/@Hold[l]
								]
						},
						Hash@DeleteCases[Hold[m],syms,\[Infinity]]
						],
				_:>Automatic
				}]
			]
		];


iNotebookToMarkdown[
	pathInfo_,
	g:_GraphicsBox|_Graphics3DBox|TemplateBox[_,"Legended",___],
	fbase_:Automatic,
	alt_:Automatic
	]:=
	markdownNotebookHashExport[
		pathInfo,
		g,
		"png",
		alt,
		fbase,
		Cell[BoxData[#],"Output"]&
		]


iNotebookToMarkdown[pathInfo_,f_FrontEnd`FileName]:=
	StringRiffle[FileNameSplit[ToFileName[f]],"/"];
iNotebookToMarkdown[pathInfo_,u:_URL]:=
	First@u;
iNotebookToMarkdown[pathInfo_,f_File]:=
	StringRiffle[FileNameSplit[First[f]],"/"];


iNotebookToMarkdown[pathInfo_,e_]:=
	"";


NotebookMarkdownSave[
	nbObj:_NotebookObject|Automatic:Automatic
	]:=
	With[{nb=Replace[nbObj,Automatic:>InputNotebook[]]},
		With[{
			meta=MarkdownNotebookMetadata[nb]
			},
			If[Lookup[meta,"_Save",True]=!=False,
				With[{
					md=
						Reap[
							NotebookToMarkdown[nb],
							"MarkdownExport"
							],
					root=
						MarkdownSiteBase@
							MarkdownNotebookDirectory[nb]
					},
					If[!FileExistsQ@
							FileNameJoin@Flatten@{root,MarkdownContentExtension@root,First[#]},
						Export[
							FileNameJoin@Flatten@{root,MarkdownContentExtension@root,First[#]},
							ReleaseHold@Last[#]
							]
						]&/@Flatten@Last[md];
					If[StringLength@StringTrim@md[[1]]>0,
						Export[
							StringReplace[NotebookFileName[nb],".nb"~~EndOfString->".md"],
							StringTrim@
								TemplateApply[
									$markdownnewmdfiletemplate,
									<|
										"headers"->
											If[Length@meta>0,
												markdownMetadataFormat[
													FileBaseName@
														MarkdownNotebookContentPath[nb],
													Association@
														Flatten[
															{
																"Modified":>Now,
																meta
																}
															]
													],
												""
												],
										"body"->md[[1]]
										|>
									],
							"Text"
							]
						]
					]
				]
			]
		]


markdownToXMLFormat//ClearAll


markdownToXMLFormat["Meta",text_]:=
	XMLElement["meta",
		Normal@AssociationThread[
			{"name","content"},
			StringTrim@
				StringSplit[#,":",2]
			],
		{}
		]&/@StringSplit[text,"\n"];


markdownToXMLFormat[
	"FenceBlock",
	text_
	]:=
	With[{
		striptext=
			StringSplit[
				StringTrim[
					text,
					StringRepeat["`",
						StringLength@text-
							StringLength@StringTrim[text,StartOfString~~("`"..)]
						]
					],
				"\n",
				2
				]
		},
		XMLElement["pre",
			{},
			{
				XMLElement["code",
					If[!StringMatchQ[First@striptext,Whitespace],
						{"class"->"language-"<>StringTrim[First@striptext]},
						{}
						],
					{
						"\n"<>Last@striptext
						}
					]
				}
			]
		]


markdownToXMLFormat[
	"CodeBlock",
	text_
	]:=
	With[{
		stripableWhitespace=
			First@
				MinimalBy[
					StringCases[text,
						StartOfLine~~w:Whitespace?(StringFreeQ["\n"])~~
							Except[WhitespaceCharacter]:>w
						],
					StringLength
					]
		},
		XMLElement["pre",
			{},
			{
				XMLElement["code",
					{},
					{
						StringTrim@
							StringReplace[
								text,
								StartOfLine~~stripableWhitespace->""
								]
						}
					]
				}
			]
		]


markdownToXMLFormat[
	"QuoteBlock",
	text_
	]:=
	With[{
		quoteStripped=
			StringReplace[
				text,
				StartOfLine~~">"->""
				]
		},
		XMLElement["blockquote",
			{},
			markdownToXML[quoteStripped]
			]
		]


markdownToXMLFormat[
	"Header",
	text_
	]:=
	With[{t=StringTrim[text]},
		XMLElement[
			"h"<>
				ToString[StringLength[t]-
					StringLength[StringTrim[t,StartOfString~~"#"..]]],
			{},
			markdownToXML[StringTrim[t,StartOfString~~"#"..],$markdownToXMLElementRules]
			]
		]


markdownToXMLItemRecursiveFormat[l_]:=
	With[
		{
			number=l[[1,1,2]]
			},
		XMLElement[
			Switch[l[[1,1,1]],
				DigitCharacter,
					"ol",
				_,
					"ul"
				],
			{},
			Flatten@Replace[
				SplitBy[l,
					#[[1,2]]==number&
					],
				{
					mainlist:
						{
								{_,number}->_,
								___
								}:>
							Last/@mainlist,
					sublist_:>
						markdownToXMLItemRecursiveFormat[sublist]
					},
				1
				]
			]
		]


markdownToXMLFormat["Item",text_String]:=
	With[{
		lines=
			StringJoin/@
				Partition[
					StringSplit[text,
						StartOfLine~~
							ws:(Whitespace|"")~~
								thing:("* "|"- "|((DigitCharacter..~~"."))):>
							ws<>thing
						],
					2
					]//StringTrim
		},
		markdownToXMLItemRecursiveFormat/@
			SplitBy[
				With[{
					subtype=
						Floor[
							(StringLength[#]
								-StringLength@StringTrim[#,StartOfString~~Whitespace])/2
							],
					thingtype=
						Replace[
							StringTake[
								StringTrim[#,StartOfString~~Whitespace],
								2],{
							t:("* "|"- "):>t,
							_->DigitCharacter
							}]
					},
					{thingtype,subtype}->
						XMLElement["li",{},
							markdownToXML@
								StringTrim[
									StringTrim[#,
										(Whitespace|"")~~
											("* "|"- "|((DigitCharacter..~~". ")))
										]
									]
							]
					]&/@lines,
			#[[1,1]]&
			]
	]


markdownToXMLFormat[
	"Delimiter",
	_
	]:=
	XMLElement["hr",{},{}]


markdownToXMLFormat[
	"CodeLine",
	text_
	]:=
	With[{
		striptext=
			StringTrim[
				text,
				StringRepeat["`",
					StringLength@text-
						StringLength@StringTrim[text,StartOfString~~("`"..)]
					]
				]
		},
		XMLElement["code",{},{striptext}]
		]


markdownToXMLFormat[
	"XMLBlock"|"XMLLine",
	text_
	]:=
	FirstCase[
		ImportString[text,{"HTML","XMLObject"}],
		XMLElement["body",_,b_]:>b,
		"",
		\[Infinity]
		]


markdownToXMLFormat[
	"Link",
	text_
	]:=
	With[{
		bits=
			StringSplit[
				text,
				"](",
				2
				]
		},
		XMLElement["a",
			{
				"href"->
					StringTrim[Last[bits],")"]
				},
			markdownToXML[
				StringTrim[First[bits],"["],
				$markdownToXMLElementRules
				]
			]
		]


markdownToXMLFormat[
	"Image",
	text_
	]:=
	With[{
		bits=
			StringSplit[
				text,
				"](",
				2
				]
		},
		XMLElement["img",
			{
				"src"->
					StringTrim[Last[bits],")"],
				"alt"->
					StringTrim[First[bits],"!["]
				},
			{}
			]
		]


markdownToXMLFormat[t_,text_String]:=
	XMLElement[t,{},{text}]


$markdownToXMLMeta=
	meta:(
		StartOfString~~
			((StartOfLine~~
					(Whitespace|"")~~
					Except[WhitespaceCharacter]..~~
					(Whitespace|"")~~":"~~Except["\n"]...~~"\n")..)
		):>
			{
				"Meta"->meta
				}


$markdownToXMLFenceBlock=
	Shortest[
		fence:(
			StartOfLine~~(r:Repeated["`",{3,\[Infinity]}])~~
				Except["`"]~~s__~~Except["`"]~~
				StartOfLine~~(b:Repeated["`",{3,\[Infinity]}])
			)/;(
				StringLength[r]==StringLength[b]&&
					Length[StringSplit[fence,"\n"]]>2
				)
		]:>
		{
			"FenceBlock"->fence
			};


$markdownToXMLCodeBlock=
	code:
		Longest[
			((StartOfString|"\n")~~"    "~~Except["\n"]..~~"\n")~~
				(((StartOfLine|(StartOfLine~~"    "~~Except["\n"]..))~~("\n"|EndOfString))...)
			]:>
		"CodeBlock"->code;


$markdownToXMLDelimiter=
	t:(
		(StartOfString|StartOfLine)~~
			(Whitespace|"")~~
			Repeated["-"|"_",{3,\[Infinity]}]~~
			Except["\n"]...
			):>
		"Delimiter"->t


$markdownToXMLHeader=
	t:(StartOfLine~~(Whitespace|"")~~Longest["#"..]~~Except["\n"]..):>
		"Header"->t


$markdownToXMLQuoteBlock=
	q:(
			(StartOfLine~~">"~~
				Except["\n"]..~~("\n"|EndOfString)
				)..
			):>
		"QuoteBlock"->q


$markdownToXMLLineIdentifier=
	("* "|"- "|((DigitCharacter..)~~". "))


$markdownToXMLItemLine=
	(
		(StartOfLine|StartOfString)~~
			(Whitespace?(StringFreeQ["\n"])|"")~~
			$markdownToXMLLineIdentifier~~
				Except["\n"]...~~(EndOfLine|EndOfString)
		);


$markdownToXMLItemSingle=
	$markdownToXMLItemLine~~
		(
			(("\n"~~(Except["\n"]..)~~EndOfLine))...
			);
$markdownToXMLItemBlock=
	t:
		Repeated[
			$markdownToXMLItemSingle~~
				("\n\n"|"")
			]:>
		"Item"->t


$markdownToXMLLink=
	o:(Except["!"]|StartOfLine|StartOfString)~~
		link:("["~~Except["]"]..~~"]("~~Except[")"]..~~")"):>
		{
			"Orphan"->o,
			"Link"->link
			}


$markdownToXMLImage=
	img:("!["~~Except["]"]..~~"]("~~Except[")"]..~~")"):>
		"Image"->img


$markdownToXMLCodeLine=
	Shortest[
		o:(Except["`"]|StartOfLine|StartOfString)~~
			code:(
				(r:"`"..)~~
					Except["`"]~~__~~Except["`"]~~
					(b:"`"..)
				)/;StringLength[r]==StringLength[b]
		]:>
		{
			"Orphan"->o,
			"CodeLine"->code
			}


$markdownToXMLXMLLine=
	xml:("<"~~Except["<"]..~~"/>"):>
		("XMLLine"->xml)


$markdownToXMLXMLBlock=
	cont:(
		"<"~~t:WordCharacter..~~__~~
			"</"~~t2:WordCharacter..~~">"
		)/;t==t2&&StringCount[cont,"<"<>t]==StringCount[cont,"</"<>t]:>
		("XMLBlock"->cont)


$markdownToXMLBlockRules={
	$markdownToXMLFenceBlock,
	$markdownToXMLCodeBlock,
	$markdownToXMLDelimiter,
	$markdownToXMLHeader,
	$markdownToXMLItemBlock,
	$markdownToXMLQuoteBlock
	};


$markdownToXMLElementRules={
	$markdownToXMLLink,
	$markdownToXMLImage,
	$markdownToXMLCodeLine,
	$markdownToXMLXMLBlock,
	$markdownToXMLXMLLine
	};


$markdownToXMLNewLineElements=
	{
		"img"
		};


markdownToXMLPrep[text_String,rules:_List|Automatic:Automatic]:=
	With[{baseData=
		Fold[
			Flatten@
				Replace[
					Replace[#,
						{
							baseText_String:>{baseText},
							StringExpression[l__]:>
								List[l]
							}
						],
					{
						baseString_String:>
							Replace[StringReplace[baseString,#2],
								StringExpression[l__]:>
									List[l]
								]
						},
					1]&,
			text,
			Replace[rules,
				Automatic:>$markdownToXMLBlockRules
				]
			]
		},
		If[StringQ@baseData,
			baseData,
			Flatten@
				ReplaceAll[
					("Orphan"->_):>Sequence@@{}
					]@
				ReplaceRepeated[
					Flatten[List@@baseData],
					{a___,t_String,"Orphan"->o_,b___}:>
						{a,markdownToXMLPrep[t<>o],b}
					]
			]
		]


markdownToXML//Clear


markdownToXML[
	text_String,
	rules:_List|Automatic:Automatic,
	extraBlockRules:_List:{},
	extraElementRules:_List:{}
	]:=
	Block[{
		$markdownToXMLBlockRules=
			Join[extraBlockRules,$markdownToXMLBlockRules],
		$markdownToXMLElementRules=
			Join[extraElementRules,$markdownToXMLElementRules]
		},
		Flatten@
			Replace[
				markdownToXMLPrep[text,rules],{
					s_String:>
						If[rules===Automatic,
							Flatten@List@
								markdownToXMLPostProcess1[s],
							{s}
							],
					l_List:>
						Replace[l,
							{
								s_String:>
									If[rules===Automatic,
										markdownToXMLPostProcess1[s],
										s
										],
								(r_->s_):>
									markdownToXMLFormat[r,s]
								},
							1
							]
				}]
		]


markdownToXMLPostProcess1[s_]:=
	SplitBy[
		Replace[
			DeleteCases[_String?(StringMatchQ[Whitespace])]@
				Flatten@List@
					markdownToXML[#,$markdownToXMLElementRules],
			{
				{e_XMLElement}:>e,
				e:Except[{_XMLElement}]:>
					XMLElement["p",{},
						Replace[Flatten@{e},
							str_String:>
								StringTrim[str],
							1
							]
						]
				}
			]&/@
			Select[Not@*StringMatchQ[Whitespace]]@
				StringSplit[s,"\n\n"]//Flatten,
		Replace[{
			XMLElement[Alternatives@@$markdownToXMLNewLineElements,__]:>
				RandomReal[],
			_->True
			}]
		]


markdownToXMLPreProcess[t_String]:=
	StringReplace[t,{
		("\n"~~Whitespace?(StringFreeQ["\n"])~~EndOfLine)->"\n",
		"\[IndentingNewLine]"->"\n\t",
		"\t"->"    "
		}]


Options[MarkdownToXML]=
	{
		"StripMetaInformation"->True,
		"HeaderElements"->{"meta","style"},
		"BlockRules"->{},
		"ElementRules"->{}
		};
MarkdownToXML[
	s_String?(Not@*FileExistsQ),
	ops:OptionsPattern[]
	]:=
	With[{
		sm=TrueQ@OptionValue["StripMetaInformation"],
		he=OptionValue["HeaderElements"],
		er=Replace[OptionValue["ElementRules"],Except[_?OptionQ]:>{}],
		br=Replace[OptionValue["BlockRules"],Except[_?OptionQ]:>{}]
		},
		Replace[
			GatherBy[
				markdownToXML[
					markdownToXMLPreProcess[s],
					Automatic,
					Join[
						br,
						If[sm,
							{
								$markdownToXMLMeta
								},
							{}
							]
						],
					er
					],
				MatchQ[First[#],he]&
				],
		{
			{h_,b_}:>
				XMLElement["html",
					{},
					{
						XMLElement["head",{},h],
						XMLElement["body",{},b]
						}
					],
			{b_}:>
				XMLElement["html",
					{},
					{
						XMLElement["body",{},b]
						}
					]
			}]
		];
MarkdownToXML[f:(_File|_String?FileExistsQ)]:=
	MarkdownToXML@
		Import[f,"Text"]


End[];



