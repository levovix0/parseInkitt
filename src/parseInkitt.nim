import strtabs, nimpy, sequtils, strutils, os, strformat, uri
import fusion/htmlparser, cligen, fusion/htmlparser/xmltree, chronos, chronos/apps/http/httpclient

type
  Token = distinct string
  P = seq[Token]

proc `$`(a: Token): string = string a
proc `$`(a: P): string = a.join(" ")
proc `$`(a: seq[P]): string = a.join("\n\n")

proc tokenize(a: XmlNode): Token =
  Token a.innerText.strip

proc tokenizeP(a: XmlNode): P =
  for t in a:
    result.add tokenize t

proc tokenizeChapter(a: XmlNode): seq[P] =
  for p in a.findAll("p"):
    result.add tokenizeP p

type
  OutFormat {.pure.} = enum
    text
    html

proc pareseInkitt(
  start: int = 1,
  number: int = 1,
  outDir: string = ".",
  outFormat: OutFormat = OutFormat.text,
  translate: bool = false,
  lang: string = "ru",
  url: seq[string]
) =
  ## Parse book from inkitt and write it to text file
  doassert url.len >= 1, "pass book url to program"
  var url = url[0]

  var trx, tr: PyObject
  if translate:
    trx = pyimport "deep_translator"
    tr = trx.GoogleTranslator(target=lang)

  proc trans(a: P): P =
    result = try: @[
      Token tr.translate(text= $a).to(string)
        .replace(" .", ".")
        .replace(" ?", "?")
        .replace(" !", "!")
        .replace(" \"", "\"")
        .replace("\" ", "\"")
        .replace(":\"", ": \"")
        .replace("…", "...")
        .replace("-... ", "- ...")
    ]
    except: a
    echo $a, "\n-> ", result
  
  createDir outDir
  
  for c in start..<(start + number):
    let client = HttpSessionRef.new
    let url = url & "/" & "chapters" & "/" & ($c)
    let doc = parseHtml HttpClientRequestRef.new(client, client.getAddress(url.parseUri).get).fetch.waitFor.data.bytesToString
    var story = doc.findAll("article")[0][3][1]
    
    case outFormat
    of OutFormat.text:
      var storyText = ""
      for x in doc.findAll("div"):
        if not x.attrs.hasKey "class": continue
        if x.attrs["class"] != "story-page-text": continue
        if translate:
          storyText = $x.tokenizeChapter.map(trans)
        else:
          storyText = $x.tokenizeChapter

      storyText = &"Глава {c}\n\n{storyText}"
      writeFile outDir / &"{c}.txt", storyText
    
    of OutFormat.html:
      var res = newXmlTree("div", [])
      res.add newText(&"Chapter {c}")
      for x in story:
        res.add x
      writeFile outDir / &"{c}.html", $res

when isMainModule:
  clCfg.version = "0.1"
  pareseInkitt.dispatch(help = {
    "start": "start character",
    "number": "characters number",
    "outDir": "output directory",
    "outFormat": "text / html",
    "lang": "destination language",
  })
