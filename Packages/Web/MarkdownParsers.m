(* ::Package:: *)

(* Autogenerated Package *)

MarkdownToXML::usage=
  "Converts markdown to XML";


Begin["`Private`"];


(* ::Subsection:: *)
(*MarkdownToXML*)



markdownToXMLFormat//ClearAll


(* ::Subsubsection::Closed:: *)
(*Meta*)



markdownToXMLFormat["Meta", text_]:=
  With[{bits=StringSplit[#, ":", 2]},
    If[Length@bits<2,
      Nothing,
      XMLElement["meta",
        Normal@AssociationThread[
          {"name","content"},
          StringTrim@bits
          ],
        {}
        ]
      ]
    ]&/@StringSplit[text,"\n"];


(* ::Subsubsection::Closed:: *)
(*FenceBlock*)



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
      If[!StringMatchQ[First@striptext,Whitespace],
        {
          "class"->
            TemplateApply[
              "lang-`lang` highlight-source-`lang`",
              <|
                "lang"->StringTrim[First@striptext]
                |>
              ]
          },
        {}
        ],
      {
        XMLElement["code",
          {},
          {
            "\n"<>Last@striptext
            }
          ]
        }
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*CodeBlock*)



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


(* ::Subsubsection::Closed:: *)
(*QuoteBlock*)



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
    XMLElement[
      "blockquote",
      {},
      markdownToXML[quoteStripped, 
        Join[
            $markdownToXMLElementRules,
            $markdownToXMLOneTimeElementRules
            ]
        ]
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*Header*)



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
      markdownToXML[
        StringTrim[t, StartOfString~~"#"..], 
        Join[
          $markdownToXMLElementRules,
          $markdownToXMLOneTimeElementRules
          ]
        ]
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*Item*)



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
                {_, number}->_,
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
          ]
    },
    markdownToXMLItemRecursiveFormat/@
      SplitBy[
        With[{
          subtype=
            Floor[
              (StringLength[#]
                -StringLength@StringTrim[#, StartOfString~~Whitespace])/2
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
              markdownToXML[
                StringTrim[
                  StringTrim[#,
                    (Whitespace|"")~~
                      ("* "|"- "|((DigitCharacter..~~". ")))
                    ]
                  ],
                Join[
                  $markdownToXMLElementRules,
                  $markdownToXMLOneTimeElementRules
                  ]
                ]
              ]
          ]&/@lines,
      #[[1,1]]&
      ]
  ]


(* ::Subsubsection::Closed:: *)
(*ItalBold*)



markdownToXMLFormat[
  "ItalBold",
  t_
  ]:=
  With[
    {
      new=
        StringTrim[t, Repeated["*"|"_"]]
      },
    Which[
      StringLength[t]-StringLength[new]<4,
        XMLElement["em", {}, 
          markdownToXML[
            new,
            Join[
              $markdownToXMLElementRules,
              $markdownToXMLOneTimeElementRules
              ]
            ]
          ],
      StringLength[t]-StringLength[new]<6,
        XMLElement["strong", {}, 
          markdownToXML[
            new,
            Join[
              $markdownToXMLElementRules,
              $markdownToXMLOneTimeElementRules
              ]
            ]
          ],
      True,
        XMLElement["em", {},
          {
            XMLElement["strong", {}, 
              markdownToXML[
                new,
                Join[
                  $markdownToXMLElementRules,
                  $markdownToXMLOneTimeElementRules
                  ]
                ]
              ]
            }
          ]
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*Delimiter*)



markdownToXMLFormat[
  "Delimiter",
  _
  ]:=
  XMLElement["hr",{},{}]


(* ::Subsubsection::Closed:: *)
(*CodeLine*)



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


(* ::Subsubsection::Closed:: *)
(*XML*)



importXMLSlow[text_]:=
  FirstCase[
    ImportString[text, {"HTML", "XMLObject"}],
    XMLElement["body"|"head", _, b_]|b:XMLElement["script", __]:>b,
    "",
    \[Infinity]
    ]


markdownToXMLFormat[
  "XMLBlock"|"XMLLine",
  text_
  ]:=
  Module[{h=ToString@Hash[text]},
    $tmpMap[h]=text;
    Sow[h->text, "XMLExportKeys"];
    "XMLToExport"[h]
    ]


(* ::Subsubsection::Closed:: *)
(*Hyperlink*)



markdownToXMLFormat[
  "Link",
  text_
  ]:=
  With[{
    bits=
      {StringRiffle[#[[;;-2]], "]("], #[[-1]]}&@StringSplit[
        text,
        "]("
        ]
    },
    XMLElement["a",
      {
        "href"->
          StringTrim[Last[bits],")"]
        },
      markdownToXML[
        StringTrim[First[bits],"["],
        Join[
          $markdownToXMLElementRules,
          $markdownToXMLOneTimeElementRules
          ]
        ]
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*Img*)



markdownToXMLFormat[
  "Image",
  text_
  ]:=
  With[{
    bits=
      {StringJoin@#[[;;-2]], #[[-1]]}&@StringSplit[
        text,
        "]("
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


markdownToXMLFormat[
  "ImageRef",
  text_
  ]:=
  With[{
    bits=
      StringSplit[
        text,
        "][",
        2
        ]
    },
    XMLElement["img",
      {
        "src"->
          "ImageRefLink"@StringTrim[Last[bits],"]"],
        "alt"->
          StringTrim[First[bits],"!["]
        },
      {}
      ]
    ]


markdownToXMLFormat[
  "ImageRefLink",
  text_
  ]:=
  With[{
    bits=
      StringSplit[
        text,
        "]:",
        2
        ]
    },
    Sow[{"ImageRefLink", 
      StringTrim[First@bits, (Whitespace|"")~~"["]}->Last@bits];
      Nothing
    ];
markdownToXMLFormat[
  "ImageRefLinkBlock",
  text_
  ]:=
  markdownToXMLFormat["ImageRefLink", #]&/@
    Select[StringSplit[text, "\n"],
      Not@*StringMatchQ[Whitespace]
      ]


(* ::Subsubsection::Closed:: *)
(*TextForms*)



$MarkdownToXMLTextForms=
  {
    "MathLine"
    };


markdownToXMLFormat[Alternatives@@$MarkdownToXMLTextForms, text_String]:=
  text;


(* ::Subsubsection::Closed:: *)
(*Fallback*)



markdownToXMLFormat[t_,text_String]:=
  XMLElement[t, {}, {text}]


(* ::Subsubsection::Closed:: *)
(*makeTempHashKey*)



makeTempHashKey[h_]:=
  "-hash-!!!"<>h<>"!!!-hash-";
matchTempHashKey=
  "-hash-!!!"~~hashInt:NumberString~~"!!!-hash-":>$tmpMap[hashInt];


makeHashRef[orphans_, tag_, main_]:=
  With[{h=ToString@Hash[main]},
    $tmpMap[h]=tag->main;
    "Reinsert"->{orphans, makeTempHashKey@h}
    ];
makeHashRef[a_->b_]:=
  makeHashRef["", a, b];
makeHashRef[a_, b_]:=
  makeHashRef["", a, b];


(* ::Subsubsection::Closed:: *)
(*markdownToXMLValidateXMLBlock*)



markdownToXMLValidateXMLBlock[block_, start_, end_]:=
  start==end&&
    With[
      {
        splits=
          Developer`ToPackedArray@
            StringCases[block,
              {
                ("<"~~(Whitespace|"")~~(Whitespace|"")~~start)->
                  {1, 0},
                ("<"~~(Whitespace|"")~~"/"~~(Whitespace|"")~~end)->
                  {0, 1}
                }
              ]
        },
      (#[[1]]==#[[2]]&[Total[splits]])&&
      AllTrue[
        Accumulate@Most@splits,
        #[[1]]>#[[2]]&
        ]
      ]


(* ::Subsubsection::Closed:: *)
(*$markdownToXMLRules*)



(* ::Subsubsubsection::Closed:: *)
(*$markdownToXMLMeta*)



(* ::Text:: *)
(*
	For stripping meta info as used by pelican and things
*)



$markdownToXMLMeta=
  meta:(
    StartOfString~~
      (
        (
          StartOfLine~~(Whitespace|"")~~
          Except[WhitespaceCharacter, WordCharacter]..~~
          (Whitespace|"")~~":"~~Except["\n"]...~~"\n")..
          )
    ):>
      {
        "Meta"->meta
        }


(* ::Subsubsubsection::Closed:: *)
(*$markdownToXMLFenceBlock*)



$markdownToXMLFenceBlock=
    fence:(
      StartOfLine~~
        (
          r:Repeated["`", {3, \[Infinity]}]
        )~~
          t:Repeated[Except["`"|"\n"], {2, \[Infinity]}]~~"\n"
          ~~s___~~
      StartOfLine~~(b:Repeated["`", {3, \[Infinity]}])
      )/;(
          StringLength[r]==StringLength[b]&&
          Length[StringSplit[fence, "\n"]]>2&&
          StringCount[fence, b]==2
        ):>
    {
      "FenceBlock"->fence
      };


(* ::Subsubsubsection::Closed:: *)
(*$markdownToXMLCodeBlock*)



$markdownToXMLCodeBlock=
  code:(
    Longest[
      (
        (StartOfString|"\n")~~
          ("\t"|"    ")~~
          Except["\n"]..~~
          "\n"
          )~~
        (
          (
            (StartOfLine|(StartOfLine~~("\t"|"    ")~~
              Except["\n"]..))~~
              ("\n"|EndOfString)
              )...
          )
      ]
    ):>
    "CodeBlock"->code;


$markdownToXMLEndOfStringCodeBlock=
  code:(
    (StartOfString|"\n")~~
      ("\t"|"    ")~~
      Except["\n"]..~~EndOfString
    ):>
    "CodeBlock"->code;


(* ::Subsubsubsection::Closed:: *)
(*$markdownToXMLDelimiter*)



$markdownToXMLDelimiter=
  t:(
    (StartOfString|StartOfLine)~~
      (Whitespace|"")~~
      Repeated["-"|"_", {3,\[Infinity]}]~~
      (Whitespace|"")~~(EndOfLine|EndOfString)
      ):>
    "Delimiter"->t


(* ::Subsubsubsection::Closed:: *)
(*$markdownToXMLHeader*)



$markdownToXMLHeader=
  t:(StartOfLine~~(Whitespace|"")~~Longest["#"..]~~Except["\n"]..):>
    "Header"->t


(* ::Subsubsubsection::Closed:: *)
(*$markdownToXMLQuoteBlock*)



$markdownToXMLQuoteBlock=
  q:(
      (StartOfLine~~">"~~
        Except["\n"]..~~("\n"|EndOfString)
        )..
      ):>
    "QuoteBlock"->q


(* ::Subsubsubsection::Closed:: *)
(*$markdownToXMLItemBlock*)



$markdownToXMLLineIdentifier=
  ("* "|"- "|((DigitCharacter..)~~". "))


$markdownToXMLBlankSpaces=  
  Repeated[
    ("\n"~~(Except["\n"]..)~~EndOfLine),
    {0, 1}
    ]~~("\n\n"|"")


$markdownToXMLItemLine=
  (
    (StartOfLine|StartOfString)~~
      (Whitespace?(StringFreeQ["\n"])|"")~~
      $markdownToXMLLineIdentifier~~
        Except["\n"]...~~(EndOfLine|EndOfString)
    );


$markdownToXMLItemSingle=
  $markdownToXMLItemLine~~
    $markdownToXMLBlankSpaces;
$markdownToXMLItemBlock=
  t:
    Repeated[
      $markdownToXMLItemSingle
      ]:>
    "Item"->t


$markdownToXMLTwoWhitespaceItemLine=
  $markdownToXMLItemSingle/.
    Verbatim[(Whitespace?(StringFreeQ["\n"])|"")]:>
      Repeated[Except["\n", WhitespaceCharacter], {0,2}];


$markdownToXMLMultiItemBlock=
  t:(
    $markdownToXMLTwoWhitespaceItemLine~~
      Repeated[
        $markdownToXMLItemSingle~~
          ("\n\n"|"")
        ]
      ):>
    "Item"->t


(* ::Subsubsubsection::Closed:: *)
(*$markdownToXMLLink*)



markdownToXMLLinkPairedBrackets[o_]:=
  StringCount[o, "["]>0&&
    StringCount[o, "["]==StringCount[o, "]"]
markdownToXMLValidateLink[o_]:=
  markdownToXMLLinkPairedBrackets[o]&&
    !markdownToXMLLinkPairedBrackets[StringSplit[o, "]", 2][[2]]]


badLinkChars="!"(*|"*"|"_"*);


$markdownToXMLLink=
  l:(o:Except[badLinkChars]|StartOfLine|StartOfString)~~
    link:("["~~Except["\n"]..~~"]("~~Except[WhitespaceCharacter]..~~")")/;
      markdownToXMLValidateLink[link]:>
        makeHashRef[o, "Link", link]


(* ::Subsubsubsection::Closed:: *)
(*$markdownToXMLImage*)



$markdownToXMLImage=
  img:("!["~~Except["\n"]..~~"]("~~Except[WhitespaceCharacter]..~~")")/;
    markdownToXMLValidateLink[img]:>
    makeHashRef["Image"->img]


(* ::Subsubsubsection::Closed:: *)
(*$markdownToXMLImageRef*)



$markdownToXMLImageRef=
  img:("!["~~Except["]"]..~~"]["~~Except["]"]..~~"]"):>
    makeHashRef["ImageRef"->img]


(* ::Subsubsubsection::Closed:: *)
(*$markdownToXMLImageRefLinkBlock*)



$markdownToXMLImageRefLinkBlock=
  img:Repeated[(
    (Whitespace|"")~~"["~~Except["]"]..~~"]:"~~(Whitespace|"")~~
      WordCharacter~~Except[WhitespaceCharacter]..)]:>
    "ImageRefLinkBlock"->img


(* ::Subsubsubsection::Closed:: *)
(*$markdownToXMLImageRefLink*)



$markdownToXMLImageRefLink=
  img:((Whitespace|"")~~"["~~Except["]"]..~~"]:"~~(Whitespace|"")~~
    Except[WhitespaceCharacter]..~~(Whitespace|"")):>
    makeHashRef["ImageRefLink"->img]


(* ::Subsubsubsection::Closed:: *)
(*$markdownToXMLCodeLine*)



$markdownToXMLCodeLine=
  Shortest[
    o:(Except["`"]|StartOfLine|StartOfString)~~
      code:(
        (r:"`"..)~~
          Except["`"]~~mid___~~(Except["`"]|"")~~
          (b:"`"..)
        )/;StringLength[r]==StringLength[b]&&StringCount[mid, "`"]<StringLength[r]
    ]:>
    makeHashRef[o,
      "CodeLine",
      code
      ]


(* ::Subsubsubsection::Closed:: *)
(*$markdownToXMLMathLine*)



$markdownToXMLMathLine=
  math:Shortest[("$$"~~__~~"$$")]:>
    makeHashRef[("MathLine"->math)]


(* ::Subsubsubsection::Closed:: *)
(*$markdownToXMLXMLLine*)



$markdownToXMLXMLLine=
  xml:
    ("<"~~tag:WordCharacter..~~Except["<"]..~~"/>")|
    ("<link"~~Except["<"]..~~">"):>
    ("XMLLine"->xml)


(* ::Subsubsubsection::Closed:: *)
(*$markdownToXMLXMLBlock*)



$markdownToXMLXMLBlock=
  cont:(
    "<"~~t:WordCharacter..~~__~~
      "</"~~(Whitespace|"")~~t__(*t2:WordCharacter..*)~~(Whitespace|"")~~">"
    )/;markdownToXMLValidateXMLBlock[cont, t, t]:>
    ("XMLBlock"->cont);


(* ::Subsubsubsection::Closed:: *)
(*$markdownToXMLSimpleXMLBlock*)



$markdownToXMLSimpleXMLBlock=
  cont:(
    "<"~~t:WordCharacter..~~Except[">"]...~~">"~~Except["<"]...~~
      "</"~~(Whitespace|"")~~t__~~(Whitespace|"")~~">"
    ):>
    ("XMLBlock"->cont);


(* ::Subsubsubsection::Closed:: *)
(*$markdownToXMLRawXMLBlock*)



(*$markdownToXMLCommonXMLBlock=
	cont:(
		(StartOfLine|StartOfString)~~
			"<"~~(Whitespace|"")~~t:WordCharacter..~~..~~"\n\n"~~
				"</"~~(Whitespace|"")~~t__~~(Whitespace|"")~~">"
		)/;markdownToXMLValidateXMLBlock[cont, t, t]\[RuleDelayed]
		("XMLBlock"\[Rule]cont);*)


$markdownToXMLShortXMLBlock=
  cont:Shortest[(
    (StartOfLine|StartOfString)~~
      "<"~~(Whitespace|"")~~t:WordCharacter..~~__~~
        "</"~~(Whitespace|"")~~t__~~(Whitespace|"")~~">"
    )]/;markdownToXMLValidateXMLBlock[cont, t, t]:>
    ("XMLBlock"->cont);


$markdownToXMLCompleXMLBlock=
  cont:(
    (StartOfLine|StartOfString)~~
      "<"~~(Whitespace|"")~~t:WordCharacter..~~__~~
        "</"~~(Whitespace|"")~~t__~~(Whitespace|"")~~">"
    )/;markdownToXMLValidateXMLBlock[cont, t, t]:>
    ("XMLBlock"->cont);


$markdownToXMLRawXMLBlock=
  {
    (*$markdownToXMLCommonXMLBlock,*)
    $markdownToXMLShortXMLBlock,
    $markdownToXMLCompleXMLBlock
    };


(* ::Subsubsubsection::Closed:: *)
(*$markdownToXMLItalBold*)



$markdownToXMLItalBold=
  o:(a:(("*"|"_")..)~~Shortest[t:Except["\n"]..]~~a_):>
    makeHashRef["", "ItalBold", o]


(* ::Subsubsubsection::Closed:: *)
(*$markdownToXMLBlockRules*)



$markdownToXMLBlockRules={
  $markdownToXMLRawXMLBlock,
  $markdownToXMLFenceBlock,
  $markdownToXMLImageRefLinkBlock,
  $markdownToXMLMultiItemBlock,
  $markdownToXMLCodeBlock,
  $markdownToXMLEndOfStringCodeBlock,
  $markdownToXMLDelimiter,
  $markdownToXMLHeader,
  $markdownToXMLItemBlock,
  $markdownToXMLQuoteBlock
  };


(* ::Subsubsubsection::Closed:: *)
(*$markdownToXMLElementRules*)



$markdownToXMLElementRules=
  {
    $markdownToXMLXMLBlock,
    $markdownToXMLXMLLine,
    $markdownToXMLLink,
    $markdownToXMLImageRef,
    $markdownToXMLImageRefLink,
    $markdownToXMLImage,
    $markdownToXMLCodeLine,
    $markdownToXMLItalBold,
    $markdownToXMLMathLine
    };


(* ::Subsubsubsection::Closed:: *)
(*$markdownToXMLNewLineElements*)



$markdownToXMLNewLineElements=
  {
    "img"
    };


(* ::Subsubsection::Closed:: *)
(*markdownToXMLPrep*)



markdownToXMLPrep[text_String, rules:_List|Automatic:Automatic]:=
  With[
    {
      baseData=
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
                  Replace[
                    StringReplace[baseString, #2],
                    StringExpression[l__]:>
                      List[l]
                    ]
                },
              1]&,
          text,
          Replace[rules,
            Automatic:>
              $markdownToXMLBlockRules
            ]
          ]
        },
      Which[
        StringQ@baseData,
          {baseData},
        AllTrue[baseData, StringQ],
          baseData,
        True,
          Flatten@markdownPrepRecursive[baseData, rules]
        ]
      ]


markdownPrepRecursive[baseData_, rules_]:=
  If[StringQ@#, markdownToXMLPrep[#, rules], #]&/@
    Flatten@
      Replace[
        Flatten@
        ReplaceRepeated[
          Flatten[List@@baseData],
          {
            {a___, t_String, "Reinsert"->o_, b_String, c___}:>
              {a, markdownToXMLPrep[t<>o<>b], c},
            {a___, t_String, "Orphan"->o_, b___}:>
              {a, markdownToXMLPrep[t<>o], b}
            }
          ],
        {
          ("Orphan"->s_):>s(*Sequence@@{}*),
          ("Reinsert"->s_):>s
          },
        1
        ]


(* ::Subsubsection::Closed:: *)
(*markdownToXMLReinsertRefs*)



markdownToXMLReinsertRefs[eeex_]:=
  Module[{reap, oppp, expr, ops},
    reap=Reap[eeex];
    {expr, ops}=reap;
    oppp=Association@Cases[Flatten@ops, _Rule|_RuleDelayed];
    expr/.
    "ImageRefLink"[x_]:>
      Lookup[oppp, Key@{"ImageRefLink", x}, x]
    ];
markdownToXMLReinsertRefs~SetAttributes~HoldFirst;


(* ::Subsubsection::Closed:: *)
(*markdownToXMLReinsertXML*)



markdownToXMLReinsertXML[expr_]:=
  Module[{reap, ex, keys, exported, expass, expass2},
    reap=
      Reap[expr, "XMLExportKeys"];
    keys=Flatten@reap[[2]];
    ex=reap[[1]];
    If[Length@keys>0,
      exported=
        ImportString[
          StringJoin@{
            "<div>",
            "<div id=\""<>#[[1]]<>"\" class=\"hash-cell\">"<>
              #[[2]]<>"</div>"&/@
              keys,
            "</div>"
            },
          {"HTML", "XMLObject"}
          ];
      expass=
        Association@
          Cases[exported, 
            XMLElement["div", 
              {___, "class"->"hash-cell", "id"->id_, ___}|
                {___, "id"->id_, "class"->"hash-cell", ___},
              b_
              ]:>(id->b),
            \[Infinity]
            ];
      expass2=
        AssociationMap[
          ReplaceRepeated[
            #,
            {
              XMLElement["div", 
                {___, "class"->"hash-cell", "id"->id_, ___}|
                  {___, "id"->id_, "class"->"hash-cell", ___},
                _
                ]:>Sequence@@Lookup[expass, id, Echo[id](*Nothing*)]
              }
            ]&, 
          expass
          ]; 
      ex/."XMLToExport"[h_]:>Sequence@@Lookup[expass2, h, Echo[h](*Nothing*)],
      ex
      ]
    ];
markdownToXMLReinsertXML~SetAttributes~HoldFirst;


(* ::Subsubsection::Closed:: *)
(*markdownFixedPointReplace*)



(* ::Text:: *)
(*
	Done with FixedPoint to handle all of the hash-prep stuff. 
	Hopefully done in such a way as to not fuck up everything.
*)



markdownFixedPointReplace[text_, rules_]:=
  FixedPoint[
    If[StringQ@#,
      Replace[
        markdownToXMLPrep[#, rules], 
        {
          s:{_String, __String}:>
            markdownToXMLPrep[StringJoin[s], rules],
          e_List:>
            Flatten[
              Replace[SplitBy[e, StringQ],
                j:{__String}:>StringJoin[j],
                1
                ],
              1
              ]
          }
        ],
      #
      ]&,
    text,
    10 (* could forsee recursion infinitely, but unlikely *)
    ]


(* ::Subsubsection::Closed:: *)
(*markdownToXML*)



markdownToXML//Clear


markdownToXML[
  text_String,
  rules:_List|Automatic:Automatic,
  extraBlockRules:_List:{},
  extraElementRules:_List:{},
  oneTimeBlockRules:_List:{},
  oneTimeElementRules:_List:{}
  ]:=
  Block[
    {
      $markdownToXMLBlockRules=
        DeleteDuplicates@Flatten@{
          Join[extraBlockRules, $markdownToXMLBlockRules],
          Replace[$markdownToXMLOneTimeBlockRules,
            Except[_List]->{}
            ],
          oneTimeBlockRules
          },
      $markdownToXMLOneTimeBlockRules=
        oneTimeBlockRules,
      $markdownToXMLElementRules=
        DeleteDuplicates@Flatten@{
          Join[extraElementRules, $markdownToXMLElementRules],
          Replace[$markdownToXMLOneTimeElementRules,
            Except[_List]->{}
            ],
          oneTimeElementRules
          },
      $markdownToXMLOneTimeElementRules=
        oneTimeElementRules
      },
    Flatten@
      Replace[
        markdownFixedPointReplace[text, rules], 
        {
          s_String:>
            If[rules===Automatic,
              Flatten@List@markdownToXMLPostProcess1[s],
              {s}
              ],
          l_List:>
            Replace[l,
              {
                s_String:>
                  If[rules===Automatic,
                    markdownToXMLPostProcess1[s],
                    Module[
                      {withHashes},
                      withHashes=
                        StringReplace[s, matchTempHashKey];
                      If[StringQ@withHashes,
                        withHashes,
                        Sequence@@Flatten@List@
                          Map[
                            If[StringQ@#,
                              #,
                              markdownToXMLFormat@@#
                              ]&,
                            List@@withHashes
                            ]
                        ]
                      ]
                    ],
                (r_->s_):>
                    markdownToXMLFormat[r, s]
                },
              1
              ]
        }]
    ]


(* ::Subsubsection::Closed:: *)
(*markdownToXMLPostProcess1*)



recursiveConvertToXML[string_]:=
  Replace[
    DeleteCases[_String?(StringMatchQ[Whitespace])]@
      Flatten@List@
        markdownToXML[string, $markdownToXMLElementRules],
    {
      {e_XMLElement}:>e,
      e:Except[{_XMLElement}]:>
        XMLElement["p",
          {},
          Flatten@{e}
          ]
      }
    ]


splitWhiteSpaceBlocks[s_]:=
  Select[Not@*StringMatchQ[Whitespace]]@
    StringSplit[s,"\n\n"]


markdownToXMLPostProcess1[s_]:=
  Module[{withHashes},
    withHashes=
      StringReplace[s, matchTempHashKey];
    If[StringQ@withHashes,
      SplitBy[
        recursiveConvertToXML/@
          splitWhiteSpaceBlocks[withHashes]//Flatten,
        Replace[
          {
            XMLElement[Alternatives@@$markdownToXMLNewLineElements, __]:>
              RandomReal[],
            _->True
            }
          ]
        ],
      Sequence@@
        Map[
          If[StringQ@#,
            markdownToXMLPostProcess1@#,
            markdownToXMLFormat@@#
            ]&,
          List@@withHashes
          ]
      ]
    ]


(* ::Subsubsection::Closed:: *)
(*markdownToXMLPreProcess*)



markdownToXMLPreProcess[t_String]:=
  StringReplace[t,{
    ("\n"~~Whitespace?(StringFreeQ["\n"])~~EndOfLine)->"\n",
    "\[IndentingNewLine]"->"\n\t",
    "\t"->"    ",
    "\[SpanFromLeft]"->"\[Ellipsis]"
    }]


(* ::Subsubsection::Closed:: *)
(*MarkdownToXML*)



MarkdownToXML//Clear


Options[MarkdownToXML]=
  {
    "StripMetaInformation"->True,
    "HeaderElements"->{"meta", "style", "link", "title"},
    "BlockRules"->{},
    "ElementRules"->{}
    };
MarkdownToXML[
  _String?(StringLength[StringTrim[#]]==0&),
  ops:OptionsPattern[]
  ]:="";
MarkdownToXML[
  s_String?(StringLength[StringTrim[#]]>0&&Not@FileExistsQ[#]&),
  ops:OptionsPattern[]
  ]:=
  Block[
  {
    $tmpMap=<||>,
    $timings
    },
    With[{
      sm=TrueQ@OptionValue["StripMetaInformation"],
      he=OptionValue["HeaderElements"],
      er=Replace[OptionValue["ElementRules"],Except[_?OptionQ]:>{}],
      br=Replace[OptionValue["BlockRules"],Except[_?OptionQ]:>{}]
      },
      Replace[
        GatherBy[
          markdownToXMLReinsertRefs@
            markdownToXMLReinsertXML@
                markdownToXML[
                  markdownToXMLPreProcess[s],
                  Automatic,
                  br,
                  er,
                  If[sm,
                    {
                      $markdownToXMLMeta
                      },
                    {}
                    ],
                  {}
                  ],
          With[{base=StringMatchQ[Alternatives@@he]},
            Head[#]==XMLElement&&Length[#]>0&&base@First[#]&
            ]
          ],
      {
        {h_,b_}:>
          XMLElement["html",
            {},
            {
              XMLElement["head", {}, DeleteDuplicates@h],
              XMLElement["body", {}, b]
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
      ]
    ];
MarkdownToXML[f:(_File|_String?FileExistsQ)]:=
  MarkdownToXML@
    Import[f, "Text"]


End[];



